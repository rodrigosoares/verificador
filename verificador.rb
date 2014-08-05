# encoding: utf-8
require_relative 'classes/instalagem'
require_relative 'classes/localizacao'
require 'time'
carrega_gem 'geocoder'

# Expressões regulares para capturar o IP, a data, o caminho, o método e o código de status de uma requisição.
IP_REGEX = %r{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}}
DATA_REGEX = %r{\d{2}\/\w{3}\/\d{4}\:\d{2}\:\d{2}\:\d{2}}
METODO_REGEX = %r{[A-Z]{3,7}}
CAMINHO_REGEX = %r{[A-Z]{3,7}\s\S*}
COD_STATUS_REGEX = %r{\s\d{3}\s}

# Códigos de status válidos para captura.
COD_STATUS_VALIDOS = ["400", "401", "403", "404"]

# Lista de locais geográficos para exportação das coordenadas.
@lista_locais = []

# Imprime o trecho do banner que contém os códigos de status válidos.
def imprime_codigos
  resposta = ""
  COD_STATUS_VALIDOS.each do |codigo|
    resposta << "#{codigo}, "
  end
  resposta = resposta.strip.chop
  resposta[-5] = " e"
  return resposta
end

# Imprime o banner da ferramenta com créditos e instruções.
def imprime_banner
  puts "VERIFICADOR DE REQUISIÇÕES HTTP - desenvolvido por Rodrigo Soares e Silva, e-mail: rodrigosoares@id.uff.br"
  puts
  puts "Esta ferramenta processa e verifica requisições registradas em arquivos de logs. " +
    "Em seguida, exporta informações de requisições em um relatório textual nesta mesma pasta. " +
    "Somente serão consideradas requisições originadas de endereços IPs que não constam no arquivo de IPs ignorados " +
    "e com os seguintes códigos de status: #{imprime_codigos}. Os endereços IP no arquivo de IPs ignorados devem " +
    "vir cada um em uma linha."
  puts
  puts "uso: 'ruby verificador.rb <arquivo-logs> <arquivo-ips-ignorados>'"
end

# Extrai do arquivo de IPs ignorados a lista de IPs a serem ignorados na varredura. Se o arquivo não for encontrado,
# todos os endereços IPs do arquivo de logs serão processados.
def obtem_ips_ignorados(caminho_ips_ignorados = nil)
  lista_ips_ignorados = []
  unless caminho_ips_ignorados.nil?
    begin
      arquivo = File.open caminho_ips_ignorados, 'r'
      arquivo.each_line do |linha|
	      lista_ips_ignorados << linha.match(IP_REGEX).to_s
      end
      arquivo.close
    rescue Errno::ENOENT
      puts 'Arquivo de IPs ignorados não encontrado. Todos os IPs serão processados.'
    end
  end
  return lista_ips_ignorados
end

# Calcula a média diária de requisições válidas.
def media_diaria(total_requisicoes, data_inicial, data_final)
  numero_dias = (data_final - data_inicial).to_i
  return (total_requisicoes / numero_dias.to_f).round 1
end

# Retorna uma hash com apenas os métodos das requisições e o número de ocorrências de cada um.
def contagem_metodos(lista_requisicoes)
  lista_requisicoes.collect { |requisicao| requisicao[:metodo] }.each_with_object(Hash.new 0) { |metodo, hash| hash[metodo] += 1 }
end

# Formata a hash de contagem de métodos em uma string para ser impressa.
def contagem_metodos_formatado(lista_requisicoes)
  hash_metodos = contagem_metodos lista_requisicoes
  string = ""
  hash_metodos.each { |metodo| string << " #{metodo.first}: #{metodo.last} |" }
  return string.chop.strip
end

# Inclui localização na lista ou incrementa ocorrência de localizações já existentes.
def inclui_local(requisicao)
  existe = false
  @lista_locais.each do |local|
    if local.ip == requisicao[:ip]
      local.ocorrencias += 1
      existe = true
    end
  end
  unless existe
    info = Geocoder.search(requisicao[:ip]).first
    @lista_locais << Localizacao.new(info.ip, info.country, info.city, info.longitude, requisicao[:data])
  end
end

# Ordena a lista de locais pelas longitudes.
def ordena_infos_por_longitude
  puts "Ordenando informações..."
  @lista_locais.sort! { |a, b| a.longitude <=> b.longitude }
end

# Exporta coordenadas de longitude por quantidade de requisições de cada IP.
def exporta_coordenadas(lista_requisicoes)
  puts "Verificando localizações..."
  lista_requisicoes.each do |requisicao|
    inclui_local requisicao
  end
  puts "Exportando coordenadas..."
  ordena_infos_por_longitude
  rotulo = "coords_verificador_#{Time.now.strftime '%d%m%y_%H%M%S'}.dat"
  arquivo = File.new rotulo, "w"
  @lista_locais.each { |local| arquivo.puts "#{local.longitude} #{local.ocorrencias}" }
  arquivo.close
  puts "Arquivo de coordenadas gráficas #{rotulo} gerado."
end

# Exporta as informações colhidas na varredura para um arquivo textual.
def exporta(lista_requisicoes)
  rotulo = "infos_verificador_#{Time.now.strftime '%d%m%y_%H%M%S'}.txt"
  arquivo_saida = File.new rotulo, 'w'
  total_requisicoes = 0
  lista_requisicoes.each do |requisicao|
    arquivo_saida.puts "IP: #{requisicao[:ip]} -- data: #{requisicao[:data]} -- código de status: #{requisicao[:codigo]} -- caminho: #{requisicao[:caminho]}"
    total_requisicoes += 1
  end
  data_inicial = Date.parse(lista_requisicoes.first[:data])
  data_inicial_formatada = data_inicial.strftime('%d/%m/%Y')
  data_final = Date.parse(lista_requisicoes.last[:data])
  data_final_formatada = data_final.strftime('%d/%m/%Y')
  arquivo_saida.puts "TOTAL: #{total_requisicoes} reqs entre #{data_inicial_formatada} e #{data_final_formatada}"
  arquivo_saida.puts "MÉDIA: #{media_diaria(total_requisicoes, data_inicial, data_final)} reqs/dia"
  arquivo_saida.puts "#{contagem_metodos_formatado lista_requisicoes}"
  arquivo_saida.close
  puts "Arquivo #{rotulo} gerado."
end

# Processa uma linha do arquivo e aplica as expressões regulares para filtrar as informações relevantes.
def processa_linha(linha, lista_ips_ignorados)
  ip_linha = linha.match(IP_REGEX).to_s
  cod_status = linha.match(COD_STATUS_REGEX).to_s.strip
  requisicao = nil
  if !ip_linha.empty? && !lista_ips_ignorados.include?(ip_linha) && COD_STATUS_VALIDOS.include?(cod_status)
    data = linha.match(DATA_REGEX).to_s
    caminho = linha.match(CAMINHO_REGEX).to_s
    metodo = caminho.match(METODO_REGEX).to_s
    data[11] = " "
    requisicao = {
      :ip => ip_linha,
      :data => data,
      :codigo => cod_status,
      :caminho => caminho,
      :metodo => metodo
    }
  end
  return requisicao
end

# Faz uma varredura pelo arquivo de logs.
def processa_arquivo(caminho_logs = nil, caminho_ips_ignorados = nil)
  if caminho_logs.nil?
    imprime_banner
  else
    begin
      lista_requisicoes = []
      lista_ips_ignorados = obtem_ips_ignorados caminho_ips_ignorados
      arquivo = File.open caminho_logs, 'r'
      puts "Processando arquivo #{caminho_logs}..."
      arquivo.each_line do |linha|
	      requisicao = processa_linha linha, lista_ips_ignorados
	      unless requisicao.nil?
	        lista_requisicoes << requisicao
	      end
      end
      arquivo.close
      exporta lista_requisicoes
      exporta_coordenadas lista_requisicoes
      puts "OK."
    rescue Errno::ENOENT
      puts 'Arquivo de logs não encontrado.'
    end
  end
end

arquivo_logs = ARGV[0]
arquivo_ips_ignorados = ARGV[1]
processa_arquivo arquivo_logs, arquivo_ips_ignorados

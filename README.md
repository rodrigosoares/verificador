#Verificador - versão 1.0

*Verificador* é uma ferramenta de extração de dados estatísticos de arquivos de log gerados pelo serviço HTTP e foi desenvolvida como parte do trabalho de conclusão de curso intitulado "Negação de Serviço na Nuvem", do Bacharelado em Ciência da Computação da Universidade Federal Fluminense.

##Uso

A ferramenta recebe como parâmetros o arquivo de log HTTP e, opcionalmente, um arquivo de endereços IP a serem ignorados na varredura. O arquivo de endereços IPs a serem ignorados deve ser textual e dispor um endereço por linha.

Uso: `$ ruby verificador.rb [arquivo_logs] [arquivo_ips_ignorados]`

Requer a linguagem Ruby instalada para ser executada.

##Características da versão 1.0

* Extrai o total de requisições, a média diária, o total de requisições GET, HEAD e POST e as páginas solicitadas.
* Execução via console.
* Analisa apenas as requisições com código de status 400, 401, 403 e 404.
* Gera um arquivo textual com os resultados e outro arquivo com as longitudes e respectivas ocorrências.
* Desenvolvida na linguagem Ruby versão 1.9.3.

##Bibliotecas de terceiros

Esta ferramenta usa uma biblioteca chamada Geocoder, que pode ser encontrada [aqui](http://www.rubygeocoder.com/).

##Aviso

Esta ferramenta é disponibilizada para fins educativos, com o intuito de servir em pesquisas relacionadas à área de Redes e Segurança da Informação. O autor **não se responsabiliza** pelo mau uso desta ferramenta.

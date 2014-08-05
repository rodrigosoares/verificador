# encoding: utf-8
# InstalaGem - instalador de gems para scripts ruby
# Coloque na mesma pasta do script.

def carrega_gem(nome, versao = nil)
  begin
    gem nome, versao
  rescue LoadError
    puts "Instalando gem '#{nome}'..."
    versao = "-- version '#{versao}'" unless versao.nil?
    system "gem install #{nome} #{versao}"
    Gem.clear_paths
    retry
  end

  require nome
end

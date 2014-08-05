class Localizacao
  attr_reader :ip, :pais, :cidade, :ocorrencias, :data, :longitude
  attr_writer :ocorrencias

  def initialize ip, pais, cidade, longitude, data
    @ip = ip
    @pais = pais
    @cidade = cidade
    @data = data
    @longitude = longitude
    @ocorrencias = 1
  end
end
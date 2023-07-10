require 'json'
require 'net/http'
require 'uri'
require 'nokogiri'

# Lee las claves de la API desde el archivo credentials.json
file = File.read('credentials.json')
data_hash = JSON.parse(file)
public_key = data_hash['public_key']
private_key = data_hash['private_key']

# Define un método para obtener el creador con menos cómics disponibles
def get_creator_with_least_comics(last_name, public_key)
  url = URI("https://gateway.marvel.com/v1/public/creators?lastName=#{last_name}&apikey=#{public_key}")
  response = Net::HTTP.get(url)
  data = JSON.parse(response)
  creators = data['data']['results']
  creator_with_least_comics = creators.min_by { |creator| creator['comics']['available'] }
  return creator_with_least_comics
end

# Obtiene los creadores con apellidos "Campbell" y "Hall"
campbell_creator = get_creator_with_least_comics('Campbell', public_key)
hall_creator = get_creator_with_least_comics('Hall', public_key)

# Compara cuál de los dos creadores tiene menos cómics disponibles
if campbell_creator['comics']['available'] < hall_creator['comics']['available']
  creator_with_least_comics = campbell_creator
else
  creator_with_least_comics = hall_creator
end

# Define un método para obtener los personajes de un creador
def get_characters(creator_id, public_key)
  url = URI("https://gateway.marvel.com/v1/public/creators/#{creator_id}/comics?apikey=#{public_key}")
  response = Net::HTTP.get(url)
  data = JSON.parse(response)
  comics = data['data']['results']
  characters = []
  comics.each do |comic|
    comic['characters']['items'].each do |character|
      characters << { 'id' => character['resourceURI'].split('/')[-1], 'name' => character['name'] }
    end
  end
  characters.sort_by! { |character| character['name'] }
  return characters
end

# Obtiene los personajes del creador con menos cómics disponibles
characters = get_characters(creator_with_least_comics['id'], public_key)

# Genera un archivo HTML con el nombre del creador y una tabla con los personajes
builder = Nokogiri::HTML::Builder.new do |doc|
  doc.html {
    doc.body {
      doc.h1 creator_with_least_comics['fullName']
      doc.table {
        characters.each do |character|
          doc.tr {
            doc.td character['id']
            doc.td character['name']
          }
        end
      }
    }
  }
end

File.write('output.html', builder.to_html)

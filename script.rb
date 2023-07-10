require 'httparty'
require 'json'
require 'digest/md5'

# Lee las claves de la API desde el archivo credentials.json
credentials_file = File.read('credentials.json')
credentials = JSON.parse(credentials_file)
public_key = credentials['public_key']
private_key = credentials['private_key']

ts = Time.now.to_i.to_s
hash = Digest::MD5.hexdigest(ts + private_key + public_key)

def get_creator_with_least_comics(last_name, public_key, private_key, ts, hash)
  url = "https://gateway.marvel.com/v1/public/creators?lastName=#{last_name}&apikey=#{public_key}&ts=#{ts}&hash=#{hash}"
  response = HTTParty.get(url)
  data = response['data']
  creators = data['results']
  creator_with_least_comics = creators.min_by { |creator| creator['comics']['available'] }
  return creator_with_least_comics
end

# Obtiene el creador de comics de apellido "Campbell" con menos comics disponibles
campbell_creator = get_creator_with_least_comics('Campbell', public_key, private_key, ts, hash)
puts "Creador Campbell: #{campbell_creator['fullName']}"

# Obtiene el creador de comics de apellido "Hall" con menos comics disponibles
hall_creator = get_creator_with_least_comics('Hall', public_key, private_key, ts, hash)
puts "Creador Hall: #{hall_creator['fullName']}"

require 'nokogiri'

# Genera un archivo HTML con el nombre del creador y una tabla con los personajes
html = Nokogiri::HTML::Builder.new do |doc|
  doc.html {
    doc.body {
      doc.h1 campbell_creator['fullName']
      doc.table {
        if campbell_creator.respond_to?(:[], 'characters')
          characters = campbell_creator['characters']
          if characters
            characters.each do |character|
              doc.tr {
                doc.td character['id']
                doc.td character['name']
              }
            end
          end
        end
      }
    }
  }
end

# Escribe el contenido HTML en un archivo
File.open('output.html', 'w') do |file|
  file.write(html.to_html)
end

puts "Archivo HTML generado: #{File.expand_path('output.html')}"



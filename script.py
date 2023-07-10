import json
import requests
from operator import itemgetter
from bs4 import BeautifulSoup

# Lee las claves de la API desde el archivo credentials.json
with open('credentials.json', 'r') as f:
    credentials = json.load(f)

public_key = credentials['public_key'] #Public
private_key = credentials['private_key'] #Private

# Define una función para obtener el creador con menos cómics disponibles
def get_creator_with_least_comics(last_name, public_key, private_key):
    url = f'https://gateway.marvel.com/v1/public/creators?lastName={last_name}&apikey={public_key}'
    response = requests.get(url)
    data = response.json()
    creators = data['data']['results']
    creator_with_least_comics = min(creators, key=itemgetter('comics', 'available'))
    return creator_with_least_comics

# Obtiene los creadores con apellidos "Campbell" y "Hall"
campbell_creator = get_creator_with_least_comics('Campbell', public_key, private_key)
hall_creator = get_creator_with_least_comics('Hall', public_key, private_key)

# Compara cuál de los dos creadores tiene menos cómics disponibles
if campbell_creator['comics']['available'] < hall_creator['comics']['available']:
    creator_with_least_comics = campbell_creator
else:
    creator_with_least_comics = hall_creator

# Define una función para obtener los personajes de un creador
def get_characters(creator_id, public_key, private_key):
    url = f'https://gateway.marvel.com/v1/public/creators/{creator_id}/comics?apikey={public_key}'
    response = requests.get(url)
    data = response.json()
    comics = data['data']['results']
    characters = []
    for comic in comics:
        for character in comic['characters']['items']:
            characters.append({'id': character['resourceURI'].split('/')[-1], 'name': character['name']})
    characters = sorted(characters, key=itemgetter('name'))
    return characters

# Obtiene los personajes del creador con menos cómics disponibles
characters = get_characters(creator_with_least_comics['id'], public_key, private_key)

# Genera un archivo HTML con el nombre del creador y una tabla con los personajes
soup = BeautifulSoup('<html><body></body></html>', 'html.parser')
body = soup.body
body.append(soup.new_tag('h1'))
body.h1.string = creator_with_least_comics['fullName']
table = soup.new_tag('table')
body.append(table)
for character in characters:
    tr = soup.new_tag('tr')
    table.append(tr)
    td_id = soup.new_tag('td')
    td_id.string = character['id']
    tr.append(td_id)
    td_name = soup.new_tag('td')
    td_name.string = character['name']
    tr.append(td_name)

with open('output.html', 'w') as f:
    f.write(str(soup))


#Public Key 19e020763594cf1824c4b657a3906c0d
#Private Key d8a50fec907ba37afe1186acbcee8a7b02c11de3
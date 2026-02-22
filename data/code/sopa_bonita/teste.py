from bs4 import BeautifulSoup, Tag, NavigableString
from urllib.request import urlopen
import pandas as pd
import requests

url = "http://www.estacoesferroviarias.com.br/m/mooca.htm"
page = urlopen(url)
html = page.read()
soup = BeautifulSoup(html, "html.parser")
main_text = soup.get_text()

# date of establishment
date_tag = soup.find('b', string='Inauguração:')
date_node = date_tag.next_sibling
if date_node and isinstance(date_node, NavigableString):
    date_data = date_node.strip()
    print(f"{date_data}")

# municipality name
mun_tag = soup.find(class_='municipio')
mun_data = mun_tag.get_text(strip=True).replace("Município de ", "")
print(f"{mun_data}")

# statation name
station_tag = soup.find("span", class_="estacao")
data_station = station_tag.get_text(strip=True)
print(data_station)

# railway names
rail_tag = soup.find(class_="estacao")
data_rail = rail_tag.get_text(strip=True)
data_rail = data_rail.replace("\n", "").replace("\r", "").replace(" ", "")
print(data_rail)

# branch name
branch_tag = soup.find_all('strong')[0]
data_branch = branch_tag.get_text(strip=True)
data_branch = data_branch.replace(" -", "")
print(data_branch)

test_df = pd.DataFrame({'municipality': mun_data, "start_date": date_data, "station": data_station, "railway": data_rail, "branch": data_branch}, index=[0])
test_df.to_csv("test.csv", index=False)



from bs4 import BeautifulSoup, Tag, NavigableString
from urllib.request import urlopen
import pandas as pd
import requests
url = "http://www.estacoesferroviarias.com.br/a/est-a.htm"
r = requests.get(url)
html_content = r.text

# Sao Paulo

# Loop over all pages based on alphabet and extract the links to the station pages
alpha_list = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u"]

url_list = []
for alpha in alpha_list:
    url = f"http://www.estacoesferroviarias.com.br/{alpha}/est-{alpha}.htm"
    url_list.append(url)

url_list.append("http://www.estacoesferroviarias.com.br/v/est-vxy.htm")
print(url_list)

htm_list = []
for url in url_list:
    # Create a BeautifulSoup object
    r = requests.get(url)
    soup = BeautifulSoup(r.text, 'html.parser')
    # Find all anchor tags (links)
    main_text = soup.find_all('td', class_='listaestacoes')
    for link in main_text:
        if link.find('a'):
            htm_links = link.find('a').get('href').replace("../", "")
        htm_list.append(htm_links)

for htm in htm_list:
    url = f"http://www.estacoesferroviarias.com.br/{htm}"
    r = requests.get(url)
    soup = BeautifulSoup(r.text, 'html.parser')
    # branch name
    branch_tag = soup.find_all('strong')[0]
    branch_data = branch_tag.get_text(strip=True)
    branch_data = branch_data.replace(" -", "")
    print(branch_data)
    # date of establishment
    date_tag = soup.find('b', string='Inauguração:')
    date_node = date_tag.next_sibling
    if date_node and isinstance(date_node, NavigableString):
        date_data = date_node.strip()
        print(f"{date_data}")
    # municipality name
    mun_tag = soup.find(class_='municipio')
    mun_data = mun_tag.get_text(strip=True).replace("Município de ", "")
    print(f"{mun_data}")
    # statation name
    station_tag = soup.find("span", class_="estacao")
    stationn_data = station_tag.get_text(strip=True)
    print(stationn_data)
    # railway names
    rail_tag = soup.find(class_="estacao")
    rail_data = rail_tag.get_text(strip=True)
    rail_data = rail_data.replace("\n", "").replace("\r", "").replace(" ", "")
    print(rail_data)

print(branch_data)
print(htm_list)
sp_df = pd.DataFrame({'municipality': mun_data, "start_date": date_data, "station": stationn_data, "railway": rail_data, "branch": branch_data}, index=[0])
sp_df.to_csv("sp_station.csv", index=False)




for htm in htm_list:
    url = f"http://www.estacoesferroviarias.com.br/{htm}"
    r = requests.get(url)
    soup = BeautifulSoup(r.text, 'html.parser')
    # branch name
    branch_tag = soup.find_all('strong')[0]
    branch_data = branch_tag.get_text(strip=True)
    branch_data = branch_data.replace(" -", "")
    print(branch_data)



print(soup.prettify())
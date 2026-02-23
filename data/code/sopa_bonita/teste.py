from bs4 import BeautifulSoup, Tag, NavigableString
from urllib.request import urlopen
import pandas as pd
import requests
import re

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

mun_data_list = []
station_data_list = []
rail_data_list = []
branch_data_list = []
date_data_list = []
for htm in htm_list:
    try:
        if htm[1] != "/":
            fix_htm = f"{htm[0]}/{htm}"
        elif htm[1] == "w":
            fix_htm = f"v/{htm}"
        else:
            fix_htm = htm
        url = f"http://www.estacoesferroviarias.com.br/{fix_htm}"
        r = requests.get(url)
        soup = BeautifulSoup(r.text, 'html.parser')
        url = f"http://www.estacoesferroviarias.com.br/{fix_htm}"
        r = requests.get(url)
        soup = BeautifulSoup(r.text, 'html.parser')
        # muncipality and station name
        mun_station_tag = soup.find_all("tr", class_="estacao")[1]
        mun_station_data = mun_station_tag.get_text(strip=True).replace("\n", "").replace("\r", "").replace(" ", "")
        mun_station_split = mun_station_data.partition("Municípiode")
        station_data = mun_station_split[0]
        mun_data = mun_station_split[2]
        mun_data_list.append(mun_data)
        station_data_list.append(station_data)
        print(f"{station_data}")
        print(f"{mun_data}")
        # railway names
        rail_tag = soup.find_all("tr", class_="estacao")[0]
        rail_data = rail_tag.get_text(strip=True).replace("\n", "").replace("\r", "").replace(" ", "")
        rail_data_list.append(rail_data)
        print(f"{rail_data}")
        # branch name
        branch_tag = soup.find_all("td", class_="dados")[1]
        branch_data = branch_tag.get_text(strip=True).replace(" -", "").replace("\n", "").replace("\r", "")
        branch_data_list.append(branch_data)
        print(f"{branch_data}")
        # date of establishment
        date_tag = soup.find('b', string='Inauguração:')
        date_node = date_tag.next_sibling
        if date_node and isinstance(date_node, NavigableString):
            date_data = date_node.strip()
            print(f"{date_data}")
        date_data_list.append(date_data)
    except:
        print(url)
    continue

sp_df = pd.DataFrame({'municipality': mun_data_list, "start_date": date_data_list, "station": station_data_list, "railway": rail_data_list, "branch": branch_data_list})
sp_df.to_csv("sp_station.csv", index=False)
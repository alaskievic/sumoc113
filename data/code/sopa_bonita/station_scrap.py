#%%

###### Sao Paulo #####
from bs4 import BeautifulSoup, NavigableString
from urllib.request import urlopen
import pandas as pd
import requests
import csv

# Loop over all pages based on alphabet and extract the links to the station pages
alpha_list = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u"]

# Open the output file
output_file_path = 'sp_station.csv'
with open(output_file_path, mode='w', newline='') as csvfile:
    # Create a CSV writer object
    csv_writer = csv.writer(csvfile)
    # Write the header row
    header = ['municipality', 'start_date', 'station', 'railway', 'branch']
    csv_writer.writerow(header)


def get_url_list_sp(alpha_list):
    url_list = []
    for alpha in alpha_list:
        url = f"http://www.estacoesferroviarias.com.br/{alpha}/est-{alpha}.htm"
        url_list.append(url)
    url_list.append("http://www.estacoesferroviarias.com.br/v/est-vxy.htm")
    print(url_list)
    return url_list

def make_htm_list(url_list):
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
    return htm_list

# muncipality and station name
def get_mun_station_data(soup):
    mun_station_tag = soup.find_all("tr", class_="estacao")[1]
    mun_station_data = mun_station_tag.get_text(strip=True).replace("\n", "").replace("\r", "").replace(" ", "")
    mun_station_split = mun_station_data.partition("Municípiode")
    station_data = mun_station_split[0]
    mun_data = mun_station_split[2]
    return mun_data, station_data

# railway names
def get_rail_data(soup):
    rail_tag = soup.find_all("tr", class_="estacao")[0]
    rail_data = rail_tag.get_text(strip=True).replace("\n", "").replace("\r", "").replace(" ", "")
    return rail_data

# branch name
def get_branch_data(soup):
    branch_data_list = []
    branch_tag = soup.find_all("td", class_="dados")[1]
    branch_data = branch_tag.get_text(strip=True).replace(" -", "").replace("\n", "").replace("\r", "")
    branch_data_list.append(branch_data)
    return branch_data_list

# date of establishment
def get_date_data(soup):
    try:
        date_tag = soup.find('b', string='Inauguração:')
        date_node = date_tag.next_sibling
        if date_node and isinstance(date_node, NavigableString):
            date_data = date_node.strip()
    except:
        date_data = "NA"
    return date_data

# main function to run the code
def main_sp():
    url_list = get_url_list_sp(alpha_list)
    htm_list = make_htm_list(url_list)
    for htm in htm_list:
        try:
            if htm[1] != "/" and htm[0] != "w":
                fix_htm = f"{htm[0]}/{htm}"
            elif htm[0] == "w":
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
            mun_data, station_data = get_mun_station_data(soup)
            # railway names
            rail_data = get_rail_data(soup)
            # branch name
            branch_data_list = get_branch_data(soup)
            branch_data = branch_data_list[0] if branch_data_list else "NA"
            # date of establishment
            date_data = get_date_data(soup)
            data_final = [mun_data, date_data, station_data, rail_data, branch_data]
            with open(output_file_path, mode='a', newline='') as csvfile:
                csv_writer = csv.writer(csvfile)
                csv_writer.writerow(data_final)
        except:
            print(url)
        continue
    data_final = data_final.strip()
    return data_final

# run the main function
if __name__ == "__main__":
    main_sp()








#%%
from bs4 import BeautifulSoup, NavigableString
from urllib.request import urlopen
import pandas as pd
import requests
import csv

##### Rest of Brazil #####
# Get a list of region indexes  
region_list = ["ne", "ba", "es", "go", "mg", "mt", "pa", "rj", "pr_sc", "rs"]

# Open the output file
output_file_path = 'region_station_teste.csv'
with open(output_file_path, mode='w', newline='') as csvfile:
    # Create a CSV writer object
    csv_writer = csv.writer(csvfile)
    # Write the header row
    header = ['municipality', 'start_date', 'station', 'railway', 'branch']
    csv_writer.writerow(header)

def get_url_list_region(region_list):
    url_list = []
    for region in region_list:
        url = f"http://www.estacoesferroviarias.com.br/index_{region}.htm"
        url_list.append(url)
    print(url_list)
    return url_list

def make_rail_list(url_list):
    rail_list = []
    for url in url_list:
        # Create a BeautifulSoup object
        r = requests.get(url)
        soup = BeautifulSoup(r.text, 'html.parser')
        # Find all anchor tags (links)
        main_text = soup.find('td', class_='dados')
        for links in main_text.find_all('a', href=True):
            htm_links = links.get('href')
            rail_list.append(htm_links)
    # drop duplciates
    rail_list = list(set(rail_list))
    return rail_list

def make_url_station(rail_list):
    url_station_list = []
    for railroad in rail_list:
        url = f"http://www.estacoesferroviarias.com.br/{railroad}"
        url_station_list.append(url)
    url_station_list.append("http://www.estacoesferroviarias.com.br/amapa/indice.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/ma-pi/indice.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/ms_nob/indice.htm")

    url_station_list.append("http://www.estacoesferroviarias.com.br/efmm/indice.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/ms_nob/indice.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/ms_nob/indice.htm")

    print(url_station_list)
    return url_station_list


def make_htm_list_region(url_station_list):
    htm_list_station = []
    for url in url_station_list:
        # Create a BeautifulSoup object
        r = requests.get(url)
        soup = BeautifulSoup(r.text, 'html.parser')
        # get prefix
        prefix = url.split("/")[-2].split(".")[0]
        # Find all anchor tags (links)
        main_text = soup.find_all('td', class_='listaestacoes')
        for link in main_text:
            if link.find('a'):
                htm_links = link.find('a').get('href').replace("../", "")
                htm_links = f"{prefix}/{htm_links}"
                htm_list_station.append(htm_links)
    return htm_list_station

# muncipality and station name
def get_mun_station_data(soup):
    mun_station_tag = soup.find_all("tr", class_="estacao")[1]
    mun_station_data = mun_station_tag.get_text(strip=True).replace("\n", "").replace("\r", "").replace(" ", "")
    mun_station_split = mun_station_data.partition("Municípiode")
    station_data = mun_station_split[0]
    mun_data = mun_station_split[2]
    return mun_data, station_data

# railway names
def get_rail_data(soup):
    rail_tag = soup.find_all("tr", class_="estacao")[0]
    rail_data = rail_tag.get_text(strip=True).replace("\n", "").replace("\r", "").replace(" ", "")
    return rail_data

# branch name
def get_branch_data(soup):
    branch_data_list = []
    branch_tag = soup.find_all("td", class_="dados")[1]
    branch_data = branch_tag.get_text(strip=True).replace(" -", "").replace("\n", "").replace("\r", "")
    branch_data_list.append(branch_data)
    return branch_data_list

# date of establishment
def get_date_data(soup):
    try:
        date_tag = soup.find('b', string='Inauguração:')
        date_node = date_tag.next_sibling
        if date_node and isinstance(date_node, NavigableString):
            date_data = date_node.strip()
    except:
        date_data = "NA"
    return date_data

# main function to run the code
def main_region():
    url_list  = get_url_list_region(region_list)
    rail_list = make_rail_list(url_list)
    url_station_list = make_url_station(rail_list)
    htm_list_station = make_htm_list_region(url_station_list)
    for htm in htm_list_station:
        try:
            # string section is present
            if "ce_crato/ce_sobral" in htm:
                htm_fix = htm.replace("ce_crato/ce_sobral", "ce_sobral")
            elif "alagoas/pernambuco" in htm:
                htm_fix = htm.replace("alagoas/pernambuco", "pernambuco")
            else:
                htm_fix = htm
            url = f"http://www.estacoesferroviarias.com.br/{htm_fix}"
            r = requests.get(url)
            soup = BeautifulSoup(r.text, 'html.parser')
            url = f"http://www.estacoesferroviarias.com.br/{htm_fix}"
            r = requests.get(url)
            soup = BeautifulSoup(r.text, 'html.parser')
            # muncipality and station name
            mun_data, station_data = get_mun_station_data(soup)
            # railway names
            rail_data = get_rail_data(soup)
            # branch name
            branch_data_list = get_branch_data(soup)
            branch_data = branch_data_list[0] if branch_data_list else "NA"
            # date of establishment
            date_data = get_date_data(soup)
            data_final = [mun_data, date_data, station_data, rail_data, branch_data]
            with open(output_file_path, mode='a', newline='') as csvfile:
                csv_writer = csv.writer(csvfile)
                csv_writer.writerow(data_final)
        except:
            print(url)
        continue
    return data_final

# run the main function
if __name__ == "__main__":
    main_region()

# %%

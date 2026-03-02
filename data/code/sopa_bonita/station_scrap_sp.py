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
    return data_final

# run the main function
if __name__ == "__main__":
    main_sp()
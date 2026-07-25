
#%%
from bs4 import BeautifulSoup, NavigableString
from urllib.request import urlopen
import pandas as pd
import requests
import csv

##### Rest of Brazil #####
# Get a list of region indexes  
region_list = ["ne", "ba", "es", "go", "mg", "mt", "pa", "rj", "rs"]

# Open the output file
output_file_path = 'region_station.csv'
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
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-tronco/parana.html")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-cur-paran/cur-paranagua.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-cur-pgro/cur-pontagrossa.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/efsc/indice.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/eftc/indice.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-rionegro/ramal_rionegro.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-ramalparanap/ramparanap.html")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-riobranco/ramal_riobranco.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-guarapuava/ramal_guarapuava.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-ramalbb/ramal_barrabonita.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-tronco/parana.html")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-spp/ramal_cianorte.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/sc-saofranc/linha_sfrancisco.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr-variantes/variantes.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/sc_troncosul/tronco_sul.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/pr_alfa.htm")
    url_station_list.append("http://www.estacoesferroviarias.com.br/sc_alfa.htm")
    return url_station_list


def make_htm_list_region(url_station_list):
    htm_list_station = []
    for url in url_station_list:
        # Create a BeautifulSoup object
        r = requests.get(url)
        soup = BeautifulSoup(r.text, 'html.parser')
        # get prefix
        prefix = url.split("/")[-2].split(".")[0]
        if "www" in prefix:
            prefix = prefix.replace("www", "")
        # Find all anchor tags (links)
        main_text = soup.find_all('td', class_='listaestacoes')
        try:
            for link in main_text:
                if link.find('a') is not None:
                    htm_links = link.find('a').get('href').replace("../", "")
                    htm_links = f"{prefix}/{htm_links}"
                    htm_list_station.append(htm_links)
        except:
            print(url)
            continue
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
            # fix for multiple paths
            if "ce_crato/ce_sobral" in htm:
                htm_fix = htm.replace("ce_crato/ce_sobral", "ce_sobral")
            elif "alagoas/pernambuco" in htm:
                htm_fix = htm.replace("alagoas/pernambuco", "pernambuco")
            elif "efcb_rj_auxiliar/efcb_rj_linha_centro" in htm:
                htm_fix = htm.replace("efcb_rj_auxiliar/efcb_rj_linha_centro", "efcb_rj_linha_centro")
            elif "rgn/ce_crato" in htm:
                htm_fix = htm.replace("rgn/ce_crato", "ce_crato")
            elif "rgn/ba_monte%20azul" in htm:
                htm_fix = htm.replace("rgn/ba_monte%20azul", "ba_monte%20azul")
            elif "alagoas/efcp_pe" in htm:
                htm_fix = htm.replace("alagoas/efcp_pe", "efcp_pe")                                                
            elif "ba_lbras/efcb_mg_linhacentro" in htm:
                htm_fix = htm.replace("ba_lbras/efcb_mg_linhacentro", "efcb_mg_linhacentro")
            elif "ba_lbras/ba_monte%20azul" in htm:
                htm_fix = htm.replace("ba_lbras/ba_monte%20azul", "ba_monte%20azul")
            elif "ba_lbras/ba_paulistana" in htm:
                htm_fix = htm.replace("ba_lbras/ba_paulistana", "ba_paulistana")
            elif "ba_lbras/ba_catuicara" in htm:
                htm_fix = htm.replace("ba_lbras/ba_catuicara", "ba_catuicara")
            elif "ba_lbras/ba_propria" in htm:
                htm_fix = htm.replace("ba_lbras/ba_propria", "ba_propria")
            elif "efl_mg_manhuacu/efl_mg_linhadocentro" in htm:
                htm_fix = htm.replace("efl_mg_manhuacu/efl_mg_linhadocentro", "efl_mg_linhadocentro")
            elif "efl_mg_manhuacu/efl_ramais_2" in htm:
                htm_fix = htm.replace("efl_mg_manhuacu/efl_ramais_2", "efl_ramais_2")
            elif "rs_uruguaiana/rs_linhaspoa" in htm:
                htm_fix = htm.replace("rs_uruguaiana/rs_linhaspoa", "rs_linhaspoa")
            elif "rs_uruguaiana/rs_marcelino-stamaria" in htm:
                htm_fix = htm.replace("rs_uruguaiana/rs_marcelino-stamaria", "rs_marcelino-stamaria")
            elif "rs_uruguaiana/rs_bage_riogrande" in htm:
                htm_fix = htm.replace("rs_uruguaiana/rs_bage_riogrande", "rs_bage_riogrande")
            elif "alagoas/ba_propria" in htm:
                htm_fix = htm.replace("alagoas/ba_propria", "ba_propria")
            elif "alagoas/ba_monte%20azul" in htm:
                htm_fix = htm.replace("alagoas/ba_monte%20azul", "ba_monte%20azul")
            elif "efl_rj_litoral/efl_ramais_3" in htm:
                htm_fix = htm.replace("efl_rj_litoral/efl_ramais_3", "efl_ramais_3")
            elif "rmv_cruz_jureia/mmg" in htm:
                htm_fix = htm.replace("rmv_cruz_jureia/mmg", "mmg")
            elif "efl_rj_litoral/efl_rj_petropolis" in htm:
                htm_fix = htm.replace("efl_rj_litoral/efl_rj_petropolis", "efl_rj_petropolis")
            elif "rs_marcelino-stamaria/pr-tronco" in htm:
                htm_fix = htm.replace("rs_marcelino-stamaria/pr-tronco", "pr-tronco")
            elif "rs_marcelino-stamaria/efcb_mg_linhacentro" in htm:
                htm_fix = htm.replace("rs_marcelino-stamaria/efcb_mg_linhacentro", "efcb_mg_linhacentro")
            elif "rmv_sapucai/rmv_cruz_jureia" in htm:
                htm_fix = htm.replace("rmv_sapucai/rmv_cruz_jureia", "rmv_cruz_jureia")
            elif "efcb_rj_riodeouro/efcb_rj_auxiliar" in htm:
                htm_fix = htm.replace("efcb_rj_riodeouro/efcb_rj_auxiliar", "efcb_rj_auxiliar")
            elif "efl_rj_petropolis/efl_rj_litoral" in htm:
                htm_fix = htm.replace("efl_rj_petropolis/efl_rj_litoral", "efl_rj_litoral") 
            elif "efl_rj_petropolis/efl_rj_cantagalo" in htm:
                htm_fix = htm.replace("efl_rj_petropolis/efl_rj_cantagalo", "efl_rj_cantagalo")
            elif "efcb_rj_ramalsp/efcb_rj_linha_centro" in htm:
                htm_fix = htm.replace("efcb_rj_ramalsp/efcb_rj_linha_centro", "efcb_rj_linha_centro")
            elif "efl_mg_tresrios_caratinga/efl_ramais_1" in htm:
                htm_fix = htm.replace("efl_mg_tresrios_caratinga/efl_ramais_1", "efl_ramais_1")
            elif "efl_mg_tresrios_caratinga/efl_mg_linhadocentro" in htm:
                htm_fix = htm.replace("efl_mg_tresrios_caratinga/efl_mg_linhadocentro", "efl_mg_linhadocentro")
            elif "efcb_mg_linhacentro/efcb_mg_ramais" in htm:
                htm_fix = htm.replace("efcb_mg_linhacentro/efcb_mg_ramais", "efcb_mg_ramais")
            elif "efcb_mg_linhacentro/efcb_mg_paraopeba" in htm:
                htm_fix = htm.replace("efcb_mg_linhacentro/efcb_mg_paraopeba", "efcb_mg_paraopeba")
            elif "efcb_mg_linhacentro/efcb_mg_pontenova" in htm:
                htm_fix = htm.replace("efcb_mg_linhacentro/efcb_mg_pontenova", "efcb_mg_pontenova")
            elif "rmv_tronco/efgoiaz" in htm:
                htm_fix = htm.replace("rmv_tronco/efgoiaz", "efgoiaz")
            elif "efcp_pe/pernambuco" in htm:
                htm_fix = htm.replace("efcp_pe/pernambuco", "pernambuco")
            elif "efcp_pe/paraiba" in htm:
                htm_fix = htm.replace("efcp_pe/paraiba", "paraiba")
            elif "efcp_pe/rgn" in htm:
                htm_fix = htm.replace("efcp_pe/rgn", "rgn")
            elif "efcp_pe/ce_crato" in htm:
                htm_fix = htm.replace("efcp_pe/ce_crato", "ce_crato")
            elif "ma-pi/ba_paulistana" in htm:
                htm_fix = htm.replace("ma-pi/ba_paulistana", "ba_paulistana")
            elif "ms_nob/efcb_mg_linhacentro" in htm:
                htm_fix = htm.replace("ms_nob/efcb_mg_linhacentro", "efcb_mg_linhacentro")                                                                                                                                                                                                                                                                                                                                                
            elif "ms_nob/ms_pontapora" in htm:
                htm_fix = htm.replace("ms_nob/ms_pontapora", "ms_pontapora")
            elif "efmm/ce_crato" in htm:
                htm_fix = htm.replace("efmm/ce_crato", "ce_crato")
            elif "efmm/ma-pi" in htm:
                htm_fix = htm.replace("efmm/ma-pi", "ma-pi")                                               
            elif "ma-pi/ce_crato" in htm:
                htm_fix = htm.replace("ma-pi/ce_crato", "ce_crato")
            elif "ce_crato/ma-pi" in htm:
                htm_fix = htm.replace("ce_crato/ma-pi", "ma-pi")                                 
            elif "rs_linhaspoa/rs_uruguaiana" in htm:
                htm_fix = htm.replace("rs_linhaspoa/rs_uruguaiana", "rs_uruguaiana")
            elif "efl_rj_litoral/efcb_rj_auxiliar" in htm:
                htm_fix = htm.replace("efl_rj_litoral/efcb_rj_auxiliar", "efcb_rj_auxiliar")
            elif "rs_bage_riogrande/rs_uruguaiana" in htm:
                htm_fix = htm.replace("rs_bage_riogrande/rs_uruguaiana", "rs_uruguaiana")                                         
            elif "http://www.estacoesferroviarias.com.br//pr-riobranco/colangelina.htm" in htm:
                htm_fix ="http://www.estacoesferroviarias.com.br/pr-riobranco/colargelina.htm"
            elif "http://www.estacoesferroviarias.com.br//pr-variantes/engdenizar.htm" in htm:
                htm_fix = "http://www.estacoesferroviarias.com.br/pr-variantes/denizar.htm"
            elif "http://www.estacoesferroviarias.com.br//pr-tronco/pontagrossa.htm" in htm:
                htm_fix = "http://www.estacoesferroviarias.com.br/pr-tronco/pontagrossa-nova.htm"                                                                
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

# Remove duplicates from dataset and create a final version
df = pd.read_csv('region_station.csv')
# Remove duplicate rows
df.drop_duplicates(inplace=True)
df.to_csv('region_station_final.csv', index=False)





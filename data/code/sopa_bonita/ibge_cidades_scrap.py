#%%

###### IBGE Cidades - All Municipalities #####
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from bs4 import BeautifulSoup
from urllib.request import urlopen
import pandas as pd
import csv


state_list = ["Acre", "Alagoas", "Amapá", "Amazonas", "Bahia", "Ceará", "Distrito Federal",
              "Espírito Santo", "Goiás", "Maranhão", "Mato Grosso", "Mato Grosso do Sul",
              "Minas Gerais", "Pará", "Paraíba", "Paraná", "Pernambuco", "Piauí", "Rio de Janeiro",
              "Rio Grande do Norte", "Rio Grande do Sul", "Rondônia", "Roraima", "Santa Catarina",
              "São Paulo", "Sergipe", "Tocantins"]

# Open the output file
output_file_path = 'ibge_cidades.csv'
with open(output_file_path, mode='w', newline='') as csvfile:
    # Create a CSV writer object
    csv_writer = csv.writer(csvfile)
    # Write the header row
    header = ['municipality', 'state', 'mun_hist', 'foundation_hist']
    csv_writer.writerow(header)

# set some options
chrome_options = Options()

# Add the headless argument
chrome_options.add_argument("--headless")

# start lists
mun_name_list = []
mun_info_hist_list = []
mun_list_link = []

def find_between(s, first, last):
    try:
        start = s.index(first) + len(first)
        end = s.index(last, start)
        return s[start:end]
    except ValueError:
        return ""

def click_page(state):
    driver = webdriver.Chrome()
    driver.get("https://cidades.ibge.gov.br")
    # Click on history button
    element = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//button[@class='button__link destaques__item__link']"))
        )
    element.click()

    # Click on the "Municípios" link
    mun_link = WebDriverWait(driver, 10).until(
            EC.element_to_be_clickable((By.XPATH, "//li[@id='menu__municipio']//i[@class='fa fa-chevron-right']"))
        )
    mun_link.click()

    # Click on a specific state and get all municipalities
    state_link = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//div[contains(text(), '{state}')]".format(state=state)))
        )
    state_link.click()

    html_state = driver.page_source
    # Create a BeautifulSoup object
    soup = BeautifulSoup(html_state, 'html.parser')
    # Find all anchor tags (links)
    mun_list = []
    main_text = soup.find_all('div', id='municipios')
    for link in main_text:
        if link.find('a'):
            mun_links_text = link.find_all('a')
            for hrefs in mun_links_text:
                mun_links = hrefs.get('href')
                mun_list.append(mun_links)
    driver.quit()
    return mun_list

# main function to run the code
def main_ibge():
    for state in state_list:
        mun_list = click_page(state)
        mun_list_link.append(mun_list)
    # mun_list_link is a list of lists, we need to flatten it
    mun_list_link_flat = [item for sublist in mun_list_link for item in sublist]
    print(mun_list_link_flat)
    for mun in mun_list_link_flat:
        try:
            driver = webdriver.Chrome(options=chrome_options)
            driver.get(f"https://cidades.ibge.gov.br{mun}/historico")
            WebDriverWait(driver, 30).until(
            EC.visibility_of_element_located((By.CLASS_NAME, "hist__texto"))
            )
            html = driver.page_source
            soup = BeautifulSoup(html, 'html.parser')
            main_text = soup.find_all(class_='hist__texto')
            full_string = " ".join([text.get_text(strip=True) for text in main_text]) if main_text else "NA"
            driver.quit()
            mun_name_part = mun.split("/")
            mun_name = mun_name_part[3]
            state_name = mun_name_part[2]
            hist_key = "Histórico"
            found_key = "Formação Administrativa"
            split_hist = find_between(full_string, hist_key, found_key)
            split_found = full_string.partition(found_key)[2]
            if split_hist != "":
                data_final = [mun_name, state_name, split_hist, split_found]
                with open(output_file_path, mode='a', newline='') as csvfile:
                        csv_writer = csv.writer(csvfile)
                        csv_writer.writerow(data_final)
            else:
                data_final = [mun_name, state_name, full_string, "NA"]
                with open(output_file_path, mode='a', newline='') as csvfile:
                        csv_writer = csv.writer(csvfile)
                        csv_writer.writerow(data_final)
        except:
            print(mun_name)
            continue
    return data_final

# run the main function
if __name__ == "__main__":
    main_ibge()


# %%

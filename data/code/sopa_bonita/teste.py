from bs4 import BeautifulSoup
from urllib.request import urlopen

url = "http://www.estacoesferroviarias.com.br/m/mooca.htm"
page = urlopen(url)
html = page.read()
soup = BeautifulSoup(html, "html.parser")

full_text = soup.get_text()

print(soup.get_text())

title_element = soup.find(string='Inauguração')

target_string = "Inauguração: "
if target_string in full_text:
    # Split the string once by the target string and take the second part
    text_after = full_text.split(target_string, 1)[1].strip()
    print(f"Extracted value: {text_after}")


print(title_element)
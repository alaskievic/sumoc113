#!/usr/bin/env python3
from __future__ import annotations

import csv
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent
OCR_DIR = ROOT / "mistral_outputs"
CSV_DIR = ROOT / "csv"

OUTPUT_FIELDS = [
    "source_image",
    "bank_name",
    "founding_year",
    "balance_date",
    "capital_raw",
    "reserve_raw",
    "raw_entry",
    "municipality",
    "state",
    "parenthetical_raw",
    "branch_location",
    "notes",
]

STATE_MAP = {
    "DF.": "DF",
    "Goiás": "GO",
    "Mato Grosso": "MT",
    "R. G. do Sul": "RS",
    "R. G. do Norte": "RN",
    "GB.": "GB",
    "Minas Gerais": "MG",
}

BANESPA_CORRECTIONS = {
    "Aerop. de Congonhas": {
        "municipality": "São Paulo",
        "state": "SP",
        "branch_location": "Aeroporto de Congonhas",
        "notes": "Capital branch/location label",
    },
    "Brás": {
        "municipality": "São Paulo",
        "state": "SP",
        "branch_location": "Brás",
        "notes": "Capital branch/location label",
    },
    "Anápolis": {"state": "GO"},
    "Aracatuba": {"municipality": "Araçatuba"},
    "Biriqui": {"municipality": "Birigui"},
    "C. Grande": {"municipality": "Campo Grande", "state": "MT"},
    "Galia": {"municipality": "Gália"},
    "Jau": {"municipality": "Jaú"},
    "Moqi Mirim": {"municipality": "Mogi Mirim"},
    "Natal": {"state": "RN"},
    "P. Aleare": {"municipality": "Porto Alegre", "state": "RS"},
    "Ribeirão Prêmio": {"municipality": "Ribeirão Prêto"},
    "São José do Rio Prêmio": {"municipality": "São José do Rio Prêto"},
    "São Luís": {"state": "MA"},
}

BBAHIA_BRANCHES = [
    ("Sucursal: Rio de Janeiro", "Rio de Janeiro", "RJ", "Sucursal", "Metropolitan addresses ignored"),
    ("Alagoinhas", "Alagoinhas", "BA", "", ""),
    ("Belmonte", "Belmonte", "BA", "", ""),
    ("Brumado", "Brumado", "BA", "", ""),
    ("Buerarema", "Buerarema", "BA", "", ""),
    ("Cachoeira", "Cachoeira", "BA", "", ""),
    ("Camacã", "Camacã", "BA", "", ""),
    ("Canavieiras", "Canavieiras", "BA", "", ""),
    ("Candeias", "Candeias", "BA", "", ""),
    ("Caravelas", "Caravelas", "BA", "", ""),
    ("Castro Alves", "Castro Alves", "BA", "", ""),
    ("Catú", "Catú", "BA", "", ""),
    ("Coaraci", "Coaraci", "BA", "", ""),
    ("Cruz das Almas", "Cruz das Almas", "BA", "", ""),
    ("Feira de Santana", "Feira de Santana", "BA", "", ""),
    ("Gandu", "Gandu", "BA", "", ""),
    ("Guanambi", "Guanambi", "BA", "", ""),
    ("Ibicaraí", "Ibicaraí", "BA", "", ""),
    ("Ibirataia", "Ibirataia", "BA", "", ""),
    ("Ilhéus", "Ilhéus", "BA", "", ""),
    ("Ipiaú", "Ipiaú", "BA", "", ""),
    ("Irecê", "Irecê", "BA", "", ""),
    ("Itaberaba", "Itaberaba", "BA", "", ""),
    ("Itabuna", "Itabuna", "BA", "", ""),
    ("Itajuípe", "Itajuípe", "BA", "", ""),
    ("Itambé", "Itambé", "BA", "", ""),
    ("Itapetinga", "Itapetinga", "BA", "", ""),
    ("Itaquara", "Itaquara", "BA", "", ""),
    ("Jacobina", "Jacobina", "BA", "", ""),
    ("Jequié", "Jequié", "BA", "", ""),
    ("Joazeiro", "Joazeiro", "BA", "", ""),
    ("Miguel Calmon", "Miguel Calmon", "BA", "", ""),
    ("Paulo Afonso", "Paulo Afonso", "BA", "", ""),
    ("Piritiba", "Piritiba", "BA", "", ""),
    ("Poções", "Poções", "BA", "", ""),
    ("Prado", "Prado", "BA", "", ""),
    ("Remanso", "Remanso", "BA", "", ""),
    ("Santo Antônio de Jesus", "Santo Antônio de Jesus", "BA", "", ""),
    ("São Felix", "São Felix", "BA", "", ""),
    ("Serrinha", "Serrinha", "BA", "", ""),
    ("Ubaitaba", "Ubaitaba", "BA", "", ""),
    ("Ubatã", "Ubatã", "BA", "", ""),
    ("Valença", "Valença", "BA", "", ""),
    ("Vitória da Conquista", "Vitória da Conquista", "BA", "", ""),
    ("Gov. Valadares", "Governador Valadares", "MG", "", ""),
    ("Montes Claros", "Montes Claros", "MG", "", ""),
    ("Nanuque", "Nanuque", "MG", "", ""),
    ("Teófilo Otoni", "Teófilo Otoni", "MG", "", ""),
    ("Barretos", "Barretos", "SP", "", ""),
    ("Campinas", "Campinas", "SP", "", ""),
    ("Guapiaçu", "Guapiaçu", "SP", "", ""),
    ("Mogi das Cruzes", "Mogi das Cruzes", "SP", "", ""),
    ("Olímpia", "Olímpia", "SP", "", ""),
    ("Piracicaba", "Piracicaba", "SP", "", ""),
    ("Santos", "Santos", "SP", "", ""),
    ("São José do Rio Prêto", "São José do Rio Prêto", "SP", "", ""),
    ("Curitiba", "Curitiba", "PR", "", ""),
]

BCOMERCINDMG_BRANCHES = [
    ("FILIAIS: Belém", "Belém", "PA", "Filial", ""),
    ("FILIAIS: Fortaleza", "Fortaleza", "CE", "Filial", ""),
    ("FILIAIS: Pôrto Alegre", "Porto Alegre", "RS", "Filial", ""),
    ("FILIAIS: Recife", "Recife", "PE", "Filial", ""),
    ("FILIAIS: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial", ""),
    ("FILIAIS: Salvador", "Salvador", "BA", "Filial", ""),
    ("FILIAIS: São Paulo", "São Paulo", "SP", "Filial", ""),
    ("Alto Rio Doce", "Alto Rio Doce", "MG", "", ""),
    ("Araguari", "Araguari", "MG", "", ""),
    ("Araxá", "Araxá", "MG", "", ""),
    ("Areado", "Areado", "MG", "", ""),
    ("Bambuí", "Bambuí", "MG", "", ""),
    ("Bicas", "Bicas", "MG", "", ""),
    ("Bocaiuva", "Bocaiuva", "MG", "", ""),
    ("Campo Belo", "Campo Belo", "MG", "", ""),
    ("Campos Altos", "Campos Altos", "MG", "", ""),
    ("Campos Gerais", "Campos Gerais", "MG", "", ""),
    ("Caratinga", "Caratinga", "MG", "", ""),
    ("Carmo do Rio Claro", "Carmo do Rio Claro", "MG", "", ""),
    ("Cássia", "Cássia", "MG", "", ""),
    ("Cataguases", "Cataguases", "MG", "", ""),
    ("Caxambu", "Caxambu", "MG", "", "OCR read as Cazambu"),
    ("Conceição do Rio Verde", "Conceição do Rio Verde", "MG", "", ""),
    ("Formiga", "Formiga", "MG", "", ""),
    ("Governador Valadares", "Governador Valadares", "MG", "", ""),
    ("Ibiraci", "Ibiraci", "MG", "", ""),
    ("Itabira", "Itabira", "MG", "", ""),
    ("Itapecerica", "Itapecerica", "MG", "", ""),
    ("Itaúna", "Itaúna", "MG", "", "OCR omitted accent"),
    ("Ituiutaba", "Ituiutaba", "MG", "", "OCR read as Itulutaba"),
    ("João Monlevade", "João Monlevade", "MG", "", "OCR read as João Montevade"),
    ("Juiz de Fora", "Juiz de Fora", "MG", "", ""),
    ("Montes Claros", "Montes Claros", "MG", "", ""),
    ("Muriaé", "Muriaé", "MG", "", ""),
    ("Ouro Preto", "Ouro Preto", "MG", "", ""),
    ("Pará de Minas", "Pará de Minas", "MG", "", ""),
    ("Paraguaçu", "Paraguaçu", "MG", "", "OCR omitted cedilla"),
    ("Patos de Minas", "Patos de Minas", "MG", "", ""),
    ("Pirapora", "Pirapora", "MG", "", ""),
    ("Pitangui", "Pitangui", "MG", "", "OCR read as Pitanqui"),
    ("Piuí", "Piuí", "MG", "", ""),
    ("Pompéu", "Pompéu", "MG", "", ""),
    ("Ponte Nova", "Ponte Nova", "MG", "", ""),
    ("Rio Casca", "Rio Casca", "MG", "", ""),
    ("Sacramento", "Sacramento", "MG", "", ""),
    ("Santa Rita do Jacutinga", "Santa Rita do Jacutinga", "MG", "", ""),
    ("Santos Dumont", "Santos Dumont", "MG", "", ""),
    ("São Gotardo", "São Gotardo", "MG", "", ""),
    ("São Sebastião do Paraíso", "São Sebastião do Paraíso", "MG", "", ""),
    ("São Tomás de Aquino", "São Tomás de Aquino", "MG", "", "OCR read as São Tomaz de Aquino"),
    ("Uberaba", "Uberaba", "MG", "", ""),
    ("Uberlândia", "Uberlândia", "MG", "", ""),
    ("Varginha", "Varginha", "MG", "", ""),
    ("Visconde do Rio Branco", "Visconde do Rio Branco", "MG", "", ""),
    (
        "Metropolitanos da Avenida, Barroca, Caetés, Carlos Prates, Floresta, Lagoinha e Mercado (Belo Horizonte)",
        "Belo Horizonte",
        "MG",
        "Avenida; Barroca; Caetés; Carlos Prates; Floresta; Lagoinha; Mercado",
        "Metropolitanos",
    ),
    ("Ilhéus", "Ilhéus", "BA", "", ""),
    (
        "Metropolitanos da Baixa do Sapateiro, Calçada, Rua Chile e São Pedro (Salvador)",
        "Salvador",
        "BA",
        "Baixa do Sapateiro; Calçada; Rua Chile; São Pedro",
        "Metropolitanos",
    ),
    ("Cachoeiro de Itapemirim", "Cachoeiro de Itapemirim", "ES", "", ""),
    ("Colatina", "Colatina", "ES", "", ""),
    ("Guaçuí", "Guaçuí", "ES", "", "OCR read as Guacuí"),
    ("Vila Rubim (Vitória)", "Vitória", "ES", "Vila Rubim", ""),
    ("Vitória", "Vitória", "ES", "", ""),
    ("Anápolis", "Anápolis", "GO", "", ""),
    ("Campinas (Goiânia)", "Goiânia", "GO", "Campinas", ""),
    ("Goiânia", "Goiânia", "GO", "", ""),
    ("Itaberaí", "Itaberaí", "GO", "", ""),
    ("Jataí", "Jataí", "GO", "", ""),
    ("Morrinhos", "Morrinhos", "GO", "", ""),
    ("Pires do Rio", "Pires do Rio", "GO", "", ""),
    ("Rio Verde", "Rio Verde", "GO", "", ""),
    (
        "Metropolitanos da Alfândega-Passos, Avenida Castelo, Bonsucesso, Botafogo, Campo Grande, Carioca, Copacabana, Madureira, Mauá-Acre, Pilares, Praça da Bandeira e Tiradentes (Rio de Janeiro)",
        "Rio de Janeiro",
        "GB",
        "Alfândega-Passos; Avenida Castelo; Bonsucesso; Botafogo; Campo Grande; Carioca; Copacabana; Madureira; Mauá-Acre; Pilares; Praça da Bandeira; Tiradentes",
        "Metropolitanos",
    ),
    (
        "Metropolitanos de Santo Antônio e São José (Recife)",
        "Recife",
        "PE",
        "Santo Antônio; São José",
        "Metropolitanos",
    ),
    ("Angra dos Reis", "Angra dos Reis", "RJ", "", ""),
    ("Barra Mansa", "Barra Mansa", "RJ", "", ""),
    ("Barra do Piraí", "Barra do Piraí", "RJ", "", ""),
    ("Bom Jesus do Itabapoana", "Bom Jesus do Itabapoana", "RJ", "", "OCR read as Bom Jesus do Ifabapoana"),
    ("Campos", "Campos", "RJ", "", ""),
    ("Duque de Caxias", "Duque de Caxias", "RJ", "", ""),
    ("Engenheiro Paulo de Frontin", "Engenheiro Paulo de Frontin", "RJ", "", ""),
    ("Itaperuna", "Itaperuna", "RJ", "", ""),
    ("Magé", "Magé", "RJ", "", ""),
    ("Natividade do Carangola", "Natividade do Carangola", "RJ", "", ""),
    ("Nilópolis", "Nilópolis", "RJ", "", ""),
    ("Niterói", "Niterói", "RJ", "", ""),
    ("Nova Friburgo", "Nova Friburgo", "RJ", "", ""),
    ("Nova Iguaçu", "Nova Iguaçu", "RJ", "", ""),
    ("Petrópolis", "Petrópolis", "RJ", "", ""),
    ("Santo Antônio de Pádua", "Santo Antônio de Pádua", "RJ", "", ""),
    ("São Fidelis", "São Fidelis", "RJ", "", ""),
    ("São João de Meriti", "São João de Meriti", "RJ", "", ""),
    ("Três Rios", "Três Rios", "RJ", "", ""),
    ("Valença", "Valença", "RJ", "", ""),
    ("Volta Redonda", "Volta Redonda", "RJ", "", ""),
    ("Cubatão", "Cubatão", "SP", "", ""),
    ("Santos", "Santos", "SP", "", ""),
    ("São Vicente", "São Vicente", "SP", "", ""),
    (
        "Metropolitanos do Belém, Bom Retiro, Brás, Cambuci, Consolação, Ipiranga, Lapa, Luz, Mooca, Oriente, Penha, Pinheiros, Santa Cecília, Santa Efigênia e Santa Rosa (São Paulo)",
        "São Paulo",
        "SP",
        "Belém; Bom Retiro; Brás; Cambuci; Consolação; Ipiranga; Lapa; Luz; Mooca; Oriente; Penha; Pinheiros; Santa Cecília; Santa Efigênia; Santa Rosa",
        "Metropolitanos",
    ),
]

BCOMERCINDSP_BRANCHES = [
    (
        "Agências Urbanas em São Paulo",
        "São Paulo",
        "SP",
        "Av. São João; Belém; Bom Retiro; Brás; Cambuci; Cardeal Arcoverde; Celso Garcia; Conselheiro Crispiniano; Consolação; Duque de Caxias; Guaicurus; Ipiranga; Jardim América; Lapa; Liberdade; Marechal Deodoro; Mercado; Mooca; Paraíso; Paula Souza; Pinheiros; Praça da República; Rangel Pestana; Santa Cecília; Santa Ifigênia; Santo Amaro; São Miguel Paulista; Tucuruvi; Vila Formosa",
        "Urban agencies; OCR read Mooca as Moica and Santa Ifigênia as Santa Iligénia",
    ),
    ("Osasco", "Osasco", "SP", "", "Listed under urban agencies in São Paulo"),
    ("Adamantina", "Adamantina", "SP", "", ""),
    ("Americana", "Americana", "SP", "", ""),
    ("Amparo", "Amparo", "SP", "", ""),
    ("Araraquara", "Araraquara", "SP", "", ""),
    ("Araras", "Araras", "SP", "", ""),
    ("Bariri", "Bariri", "SP", "", ""),
    ("Bauru", "Bauru", "SP", "", "OCR read as Baurú"),
    ("Bebedouro", "Bebedouro", "SP", "", ""),
    ("Birigui", "Birigui", "SP", "", ""),
    ("Botucatu", "Botucatu", "SP", "", ""),
    ("Bragança Paulista", "Bragança Paulista", "SP", "", ""),
    ("Cafelândia", "Cafelândia", "SP", "", ""),
    ("Campinas", "Campinas", "SP", "", ""),
    ("Campinas (Conceição)", "Campinas", "SP", "Conceição", ""),
    ("Catanduva", "Catanduva", "SP", "", ""),
    ("Cordeirópolis", "Cordeirópolis", "SP", "", ""),
    ("Dracena", "Dracena", "SP", "", ""),
    ("Duartina", "Duartina", "SP", "", ""),
    ("Franca", "Franca", "SP", "", ""),
    ("Garça", "Garça", "SP", "", ""),
    ("Guaratinguetá", "Guaratinguetá", "SP", "", ""),
    ("Ibitinga", "Ibitinga", "SP", "", ""),
    ("Iracemópolis", "Iracemópolis", "SP", "", ""),
    ("Itajobi", "Itajobi", "SP", "", ""),
    ("Itápolis", "Itápolis", "SP", "", ""),
    ("Itu", "Itu", "SP", "", ""),
    ("Jaboticabal", "Jaboticabal", "SP", "", ""),
    ("Jacareí", "Jacareí", "SP", "", ""),
    ("Jales", "Jales", "SP", "", ""),
    ("Jundiaí", "Jundiaí", "SP", "", ""),
    ("Leme", "Leme", "SP", "", ""),
    ("Limeira", "Limeira", "SP", "", ""),
    ("Lins", "Lins", "SP", "", ""),
    ("Marília", "Marília", "SP", "", ""),
    ("Matão", "Matão", "SP", "", ""),
    ("Mirassol", "Mirassol", "SP", "", ""),
    ("Novo Horizonte", "Novo Horizonte", "SP", "", ""),
    ("Olímpia", "Olímpia", "SP", "", ""),
    ("Osvaldo Cruz", "Osvaldo Cruz", "SP", "", ""),
    ("Ourinhos", "Ourinhos", "SP", "", ""),
    ("Piracicaba", "Piracicaba", "SP", "", ""),
    ("Pirassununga", "Pirassununga", "SP", "", ""),
    ("Pres. Prudente", "Presidente Prudente", "SP", "", ""),
    ("Ribeirão Preto", "Ribeirão Preto", "SP", "", ""),
    ("Rio Claro", "Rio Claro", "SP", "", ""),
    ("Salto", "Salto", "SP", "", ""),
    ("Santo André", "Santo André", "SP", "", ""),
    ("Santos", "Santos", "SP", "", ""),
    ("São Bernardo do Campo", "São Bernardo do Campo", "SP", "", ""),
    ("São Caetano do Sul", "São Caetano do Sul", "SP", "", ""),
    ("São Carlos", "São Carlos", "SP", "", ""),
    ("São João da Boa Vista", "São João da Boa Vista", "SP", "", ""),
    ("São José do Rio Preto", "São José do Rio Preto", "SP", "", ""),
    ("São Manuel", "São Manuel", "SP", "", ""),
    ("Sorocaba", "Sorocaba", "SP", "", "OCR read as Soraaba"),
    ("Sumaré", "Sumaré", "SP", "", ""),
    ("Tanabi", "Tanabi", "SP", "", ""),
    ("Taquaritinga", "Taquaritinga", "SP", "", ""),
    ("Taubaté", "Taubaté", "SP", "", ""),
    ("Tupã", "Tupã", "SP", "", ""),
    ("Valinhos", "Valinhos", "SP", "", ""),
    ("Valparaíso", "Valparaíso", "SP", "", ""),
    ("Viradouro", "Viradouro", "SP", "", ""),
    ("Votuporanga", "Votuporanga", "SP", "", ""),
    ("Apucarana", "Apucarana", "PR", "", ""),
    ("Assaí", "Assaí", "PR", "", ""),
    ("Blumenau", "Blumenau", "SC", "", ""),
    ("Brasília", "Brasília", "DF", "", ""),
    ("Cambé", "Cambé", "PR", "", ""),
    ("Campo Grande", "Campo Grande", "MT", "", "Historical state assignment in 1960"),
    ("Colatina", "Colatina", "ES", "", ""),
    ("Cornélio Procópio", "Cornélio Procópio", "PR", "", ""),
    ("Corumbá", "Corumbá", "MT", "", "Historical state assignment in 1960"),
    ("Curitiba", "Curitiba", "PR", "", ""),
    ("Londrina", "Londrina", "PR", "", ""),
    ("Mandaguari", "Mandaguari", "PR", "", "OCR read as Manáguari"),
    ("Maringá", "Maringá", "PR", "", ""),
    ("Paranaguá", "Paranaguá", "PR", "", "OCR read as Paranaquá"),
    ("Poços de Caldas", "Poços de Caldas", "MG", "", "OCR omitted cedilla"),
    ("Porto Alegre", "Porto Alegre", "RS", "", ""),
    ("Recife", "Recife", "PE", "", ""),
    ("Recife (Santo Antônio)", "Recife", "PE", "Santo Antônio", ""),
    ("Rio de Janeiro", "Rio de Janeiro", "GB", "", ""),
    ("Rio de Janeiro (Ana Neri)", "Rio de Janeiro", "GB", "Ana Neri", ""),
    ("Rio de Janeiro (Castelo)", "Rio de Janeiro", "GB", "Castelo", ""),
    ("Rio de Janeiro (Centro)", "Rio de Janeiro", "GB", "Centro", ""),
    ("Rio de Janeiro (Copacabana)", "Rio de Janeiro", "GB", "Copacabana", "OCR read as Cocacabana"),
    ("Salvador", "Salvador", "BA", "", ""),
    ("Salvador (Cidade Alta)", "Salvador", "BA", "Cidade Alta", ""),
    ("Sertanópolis", "Sertanópolis", "PR", "", ""),
    ("Vitória", "Vitória", "ES", "", ""),
]

STATE_HEADER_SPECS = [
    (r"Minas\s+Gerais\s*:", "MG", ""),
    (r"Espírito\s+Santo\s*:", "ES", ""),
    (r"Rio\s+Grande\s+do\s+Sul\s*:", "RS", ""),
    (r"Estado\s+de\s+Paraná", "PR", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Minas Gerais", "MG", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*São Paulo", "SP", ""),
    (r"No Interior do Estado de S\.?\s*Paulo", "SP", ""),
    (r"Na Cidade de São Paulo", "SP", "São Paulo"),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Paraná", "PR", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Rio Grande do Sul", "RS", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Santa Catarina", "SC", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Rio de Janeiro", "RJ", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Guanabara", "GB", "Rio de Janeiro"),
    (r"Na cidade do Rio de Janeiro", "GB", "Rio de Janeiro"),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Bahia", "BA", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Espírito\s+Santo", "ES", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Goiás", "GO", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Pernambuco", "PE", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Mato Grosso", "MT", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Ceará", "CE", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Pará", "PA", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Alagoas", "AL", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Amazonas", "AM", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Maranhão", "MA", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Paraíba", "PB", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Piauí", "PI", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Rio Grande do Norte", "RN", ""),
    (r"(?:No|Na)?\s*Est(?:ado|\.)?\s*(?:do|da|de)?\s*Sergipe", "SE", ""),
    (r"(?:No|Na)?\s*Dist(?:rito|\.)?\s*Federal", "DF", ""),
    (r"(?:No|Na)?\s*Território do Amapá", "AP", ""),
]

CITY_STATE_OVERRIDES = {
    "Apucarana": "PR",
    "Arapongas": "PR",
    "Cambé": "PR",
    "Curitiba": "PR",
    "Londrina": "PR",
    "Mandaguari": "PR",
    "Mandaquari": "PR",
    "Maringá": "PR",
    "Nova Esperança": "PR",
    "Paranaguá": "PR",
    "Paranaquá": "PR",
    "Ponta Grossa": "PR",
    "Rolândia": "PR",
    "Sertanópolis": "PR",
    "Joinville": "SC",
    "Blumenau": "SC",
    "Florianópolis": "SC",
    "Porto Alegre": "RS",
    "Pôrto Alegre": "RS",
    "Rio de Janeiro": "GB",
    "Niterói": "RJ",
    "Petrópolis": "RJ",
    "Campos": "RJ",
    "Duque de Caxias": "RJ",
    "Belo Horizonte": "MG",
    "Juiz de Fora": "MG",
    "Poços de Caldas": "MG",
    "Pocos de Caldas": "MG",
    "Goiânia": "GO",
    "Anápolis": "GO",
    "Brasília": "DF",
    "Belém": "PA",
    "Fortaleza": "CE",
    "Recife": "PE",
    "Salvador": "BA",
    "Vitória": "ES",
    "Maceió": "AL",
    "Manaus": "AM",
    "São Luís": "MA",
    "Campina Grande": "PB",
    "João Pessoa": "PB",
    "Teresina": "PI",
    "Natal": "RN",
    "Aracaju": "SE",
    "Campo Grande": "MT",
    "Corumbá": "MT",
}

NAME_CORRECTIONS = {
    "Aluruoca": "Aiuruoca",
    "Araruva": "Araruna",
    "Baurú": "Bauru",
    "Biriquí": "Birigui",
    "Braz": "Brás",
    "Cach. de Minas": "Cachoeira de Minas",
    "Cach. Itapemirim": "Cachoeiro de Itapemirim",
    "Cach. Macacú": "Cachoeiras de Macacu",
    "Cachoeiro do Ita-pemirim": "Cachoeiro de Itapemirim",
    "Cafelandia": "Cafelândia",
    "Cai": "Caí",
    "Canôas": "Canoas",
    "Carozinho": "Carazinho",
    "Cataquases": "Cataguases",
    "Cataquazes": "Cataguases",
    "Cazambu": "Caxambu",
    "Cleve Jândia": "Clevelândia",
    "Cons. Lafalete": "Conselheiro Lafaiete",
    "Cons. La-faiete": "Conselheiro Lafaiete",
    "Conc. do Rio Verde": "Conceição do Rio Verde",
    "C. do Rio Claro": "Carmo do Rio Claro",
    "C. das Alagôas": "Conceição das Alagoas",
    "Cotatina": "Colatina",
    "Curvêlo": "Curvelo",
    "Dóres de Campos": "Dores de Campos",
    "Dôres do Indaiá": "Dores do Indaiá",
    "Ferriandópolis": "Fernandópolis",
    "Fostaleza": "Fortaleza",
    "Gov. Valadares": "Governador Valadares",
    "Governador Valmares": "Governador Valadares",
    "Guaratingueia": "Guaratinguetá",
    "Guara lingueta": "Guaratinguetá",
    "Iiuí": "Ijuí",
    "Itaiaí": "Itajaí",
    "ITAIAI": "Itajaí",
    "Itamoqi": "Itamogi",
    "Itamoqui": "Itamogi",
    "Itaiubá": "Itajubá",
    "Itulutaba": "Ituiutaba",
    "Jaquapitã": "Jaguapitã",
    "Jaquariaiva": "Jaguariaíva",
    "Jau": "Jaú",
    "Jabotica": "Jaboticabal",
    "Jabotical": "Jaboticabal",
    "Jaraquá de Sul": "Jaraguá do Sul",
    "João Montevade": "João Monlevade",
    "Laquinha": "Lagoinha",
    "Macéio": "Maceió",
    "Mandaquari": "Mandaguari",
    "Mandaque": "Mandaguari",
    "Mandaquacu": "Mandaguaçu",
    "Mandaquáçu": "Mandaguaçu",
    "Mandaquarií Marialva": "Mandaguari",
    "Manáguari": "Mandaguari",
    "Manhuacu": "Manhuaçu",
    "Matczinhos": "Matozinhos",
    "Moqi das Cruzes": "Mogi das Cruzes",
    "Moqi Mirim": "Mogi Mirim",
    "Moçá das Cruzes": "Mogi das Cruzes",
    "Novo Humburgo": "Novo Hamburgo",
    "P. ALEGRE": "Porto Alegre",
    "P. Alegre": "Porto Alegre",
    "Paranaquá": "Paranaguá",
    "Paraguacu": "Paraguaçu",
    "Paraguassú": "Paraguaçu",
    "Patanqi": "Pitangui",
    "Pitanqui": "Pitangui",
    "Poco Fundo": "Poço Fundo",
    "Pocos de Caldas": "Poços de Caldas",
    "Pocos de Caídas": "Poços de Caldas",
    "Pres. Prudente": "Presidente Prudente",
    "Presidente Wensceslau": "Presidente Venceslau",
    "Rib. Prêto": "Ribeirão Preto",
    "Ribeirão Prêto": "Ribeirão Preto",
    "Ribeirão Prêto": "Ribeirão Preto",
    "Rotirendaba": "Potirendaba",
    "S. A. da Platina": "Santo Antônio da Platina",
    "S. Gonçalo": "São Gonçalo",
    "S. J. del Rei": "São João del Rei",
    "S. J. Nepomuceno": "São João Nepomuceno",
    "S. Lourenço": "São Lourenço",
    "S. Paulo": "São Paulo",
    "S. Seb. do Paraíso": "São Sebastião do Paraíso",
    "S. Vitória do Palmar": "Santa Vitória do Palmar",
    "Sta. Cruz do Rio Pardo": "Santa Cruz do Rio Pardo",
    "Sta. Cecília": "Santa Cecília",
    "Sta. Rosa": "Santa Rosa",
    "Sto. André": "Santo André",
    "Santo António do Monte": "Santo Antônio do Monte",
    "São Manoel": "São Manuel",
    "São Tomaz de Aquino": "São Tomás de Aquino",
    "Soraaba": "Sorocaba",
    "Susano": "Suzano",
    "Terezópolis": "Teresópolis",
    "Tenâncio Aires": "Venâncio Aires",
    "Tupaciquara": "Tupaciguara",
    "Vicosa": "Viçosa",
    "Vila dos Lavradores": "Botucatu",
    "Vila Galvão": "Guarulhos",
}

GENERIC_CONFIGS = {
    "bcomercpr": {
        "founding_year": "1942",
        "capital_raw": "",
        "reserve_raw": "",
        "list_after": "DEPARTAMENTOS:",
        "default_state": "PR",
        "pre_rows": [
            ("Matriz: Ponta Grossa", "Ponta Grossa", "PR", "Matriz", ""),
            ("Filial: Curitiba", "Curitiba", "PR", "Filial", ""),
            ("Filial: São Paulo", "São Paulo", "SP", "Filial", ""),
            ("Filial: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial", ""),
        ],
    },
    "bcomercsp": {
        "default_state": "SP",
        "list_after": "AGÊNCIAS: Adamantina",
        "force_list": True,
        "pre_rows": [
            ("Matriz: São Paulo", "São Paulo", "SP", "Matriz; Praça da República; Rangel Pestana; Celso Garcia; Lapa", "Urban agencies grouped"),
            ("Agência de Santo Amaro", "São Paulo", "SP", "Santo Amaro", ""),
            ("Filial: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial", ""),
            ("Filial: Santos", "Santos", "SP", "Filial", ""),
        ],
    },
    "bcreditmg_1960": {"founding_year": "1889"},
    "bdescontos": {
        "founding_year": "1943",
        "list_after": "Estado da Guanabara:",
        "pre_rows": [
            ("Matriz: Cidade de Deus", "Osasco", "SP", "Cidade de Deus", "Matriz"),
            ("São Paulo (Urbana)", "São Paulo", "SP", "Agência Central; Água Rasa; Augusta; Avenida Paulista; Belém; Bom Retiro; Brás; Brooklin Paulista; Butantã; Cambuci; Casa Verde; Consolação; Guaiaúna; Ipiranga; Itaim; Itaquera; Jabaquara; Jardim América; Lapa; Liberdade; Luz; Marechal Deodoro; Mercado; Mooca; Nações Unidas; Nossa Senhora do Ó; Paraíso; Pari; Paula Sousa; Penha; Perdizes; Pinheiros; Praça Júlio Mesquita; Rangel Pestana; Santa Cecília; Santa Ifigênia; Santa Maria; Santana; Santo Amaro; São Miguel Paulista; Senador Queiroz; Tatuapé; Tucuruvi; Vila Anastácio; Vila Formosa; Vila Mariana; Vila Prudente", "Urban agencies grouped"),
        ],
    },
    "bestadopr": {"founding_year": "1928", "default_state": "PR", "list_after": 'CAIXA POSTAL, "A"', "force_list": True},
    "bestadors": {
        "founding_year": "1928",
        "default_state": "RS",
        "list_after": "Departamentos no interior",
        "force_list": True,
        "pre_rows": [
            ("Matriz: Porto Alegre", "Porto Alegre", "RS", "Matriz; Azenha; Bonfim; Caminho do Meio; Cidade Baixa; Cristo Redentor; Floresta; Glória; Menino Deus; Moinhos de Vento; Navegantes; Partenon; Petrópolis; Passo d'Areia; São João; Teresópolis; Tristeza", ""),
            ("Agência: Rio de Janeiro", "Rio de Janeiro", "GB", "Rua da Alfândega", ""),
            ("Agência: Copacabana", "Rio de Janeiro", "GB", "Copacabana", ""),
            ("Agências em São Paulo", "São Paulo", "SP", "Centro; Mercado", ""),
        ],
    },
    "bhipotecario": {
        "founding_year": "1925",
        "pre_rows": [
            ("Matriz: Rio de Janeiro", "Rio de Janeiro", "GB", "Matriz", ""),
            ("Fortaleza", "Fortaleza", "CE", "", ""),
            ("Recife", "Recife", "PE", "", ""),
            ("Salvador", "Salvador", "BA", "", ""),
            ("Niterói", "Niterói", "RJ", "", ""),
            ("São Paulo", "São Paulo", "SP", "", ""),
            ("Santos", "Santos", "SP", "", ""),
            ("Bauru", "Bauru", "SP", "", ""),
            ("Campinas", "Campinas", "SP", "", ""),
            ("Curitiba", "Curitiba", "PR", "", ""),
            ("Porto Alegre", "Porto Alegre", "RS", "", ""),
            ("Belo Horizonte", "Belo Horizonte", "MG", "", ""),
            ("Goiânia", "Goiânia", "GO", "", ""),
            ("Brasília", "Brasília", "DF", "", ""),
            ("Metropolitanas Rio de Janeiro", "Rio de Janeiro", "GB", "Bonsucesso; Cascadura; Catete; Copacabana; Ipanema; Madureira; Méier; Tijuca", "Metropolitanas"),
            ("Metropolitanas São Paulo", "São Paulo", "SP", "Brás; Jardim América; Lapa; Luz; Mooca; Nove de Julho; Perdizes; Pinheiros; Vila Mariana", "Metropolitanas"),
            ("José Menino", "Santos", "SP", "José Menino", "Metropolitana"),
        ],
    },
    "bhipotecariomg": {
        "founding_year": "1911",
        "default_state": "MG",
        "list_after": "Outros Departamentos:",
        "pre_rows": [
            ("Sede: Belo Horizonte", "Belo Horizonte", "MG", "Matriz", ""),
            ("Sucursal: Rio de Janeiro", "Rio de Janeiro", "GB", "Sucursal", ""),
            ("Sucursal: São Paulo", "São Paulo", "SP", "Sucursal", ""),
        ],
    },
    "bindsul": {
        "founding_year": "1919",
        "pre_rows": [
            ("Sede: Porto Alegre", "Porto Alegre", "RS", "Matriz", ""),
            ("Agências no Rio de Janeiro", "Rio de Janeiro", "GB", "Rua do Acre; Rua da Quitanda; São Cristóvão", ""),
            ("Agência em São Paulo", "São Paulo", "SP", "São Bento", ""),
            ("Agências Metropolitanas em Porto Alegre", "Porto Alegre", "RS", "São João; Barros Cassal; Vila Floresta; Benjamin Constant; Cristóvão Colombo", "Metropolitanas"),
        ],
        "default_state": "RS",
        "list_after": "AGÊNCIAS EM:",
        "ignore_after": "CONSELHO DE ADMINISTRAÇÃO",
        "force_list": True,
    },
    "bitau": {
        "founding_year": "1945",
        "pre_rows": [
            ("Sede: São Paulo", "São Paulo", "SP", "Matriz", ""),
            ("Sucursal: Rio de Janeiro", "Rio de Janeiro", "GB", "Sucursal; Copacabana; Rosário", ""),
            ("Sucursal: Belo Horizonte", "Belo Horizonte", "MG", "Sucursal; Calafate; Parque Industrial", ""),
            ("Sucursal: Santos", "Santos", "SP", "Sucursal", ""),
            ("Sucursal: Curitiba", "Curitiba", "PR", "Sucursal", ""),
            ("Agências urbanas São Paulo", "São Paulo", "SP", "Jardim América; Paula Souza; Pinheiros; Piratininga; Vila Maria; Alto Vila Maria; Santa Ifigênia; Itaim", "Urbanas"),
        ],
        "list_after": "DEPARTAMENTOS:",
    },
    "blavoura_1960": {
        "founding_year": "1925",
        "pre_rows": [
            ("Sede: Belo Horizonte", "Belo Horizonte", "MG", "Matriz", ""),
            ("Filial: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial", ""),
            ("Filial: São Paulo", "São Paulo", "SP", "Filial", ""),
            ("Filial: Porto Alegre", "Porto Alegre", "RS", "Filial", ""),
        ],
    },
    "bmercantilmg_1960": {
        "founding_year": "1941",
        "default_state": "MG",
        "list_after": "DEPENDÊNCIAS:",
        "force_list": True,
        "pre_rows": [
            ("Matriz: Belo Horizonte", "Belo Horizonte", "MG", "Matriz; Avenida; Barreiro; Mercado; São José", ""),
            ("Filial: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial; Copacabana", ""),
            ("Filial: São Paulo", "São Paulo", "SP", "Filial", ""),
        ],
    },
    "bmercantilsp": {"founding_year": "1938", "default_state": "SP", "split_periods": True},
    "bmg": {"founding_year": "1930"},
    "bmoreirasalles": {
        "founding_year": "1924",
        "split_periods": True,
        "pre_rows": [
            ("Matriz: Poços de Caldas", "Poços de Caldas", "MG", "Matriz", ""),
            ("Sucursal: São Paulo", "São Paulo", "SP", "Sucursal", ""),
            ("Sucursal: Belo Horizonte", "Belo Horizonte", "MG", "Sucursal", ""),
            ("Sucursal: Santos", "Santos", "SP", "Sucursal", ""),
        ]
    },
    "bnacionalcomerc": {"founding_year": "1835", "split_periods": True},
    "bnacionalmg_1960": {
        "founding_year": "1944",
        "pre_rows": [
            ("Sede: Belo Horizonte", "Belo Horizonte", "MG", "Matriz", ""),
            ("Filial: São Paulo", "São Paulo", "SP", "Filial", ""),
            ("Filial: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial", ""),
        ],
    },
    "bnordeste": {
        "founding_year": "1952",
        "list_after": "FILIAIS:",
        "ignore_after": "CORRESPONDENTES",
        "force_list": True,
        "split_periods": True,
    },
    "bnoroeste": {"founding_year": "1923", "ignore_before": "No Interior do Estado de S. Paulo"},
    "bpredrj": {"founding_year": "1917"},
    "bproducaomg": {
        "founding_year": "1934",
        "pre_rows": [
            ("Matriz: Belo Horizonte", "Belo Horizonte", "MG", "Matriz", ""),
            ("Filial: São Paulo", "São Paulo", "SP", "Filial", ""),
            ("Filial: Rio de Janeiro", "Rio de Janeiro", "GB", "Filial", ""),
            ("Filial: Juiz de Fora", "Juiz de Fora", "MG", "Filial", ""),
        ],
    },
    "bsc": {"founding_year": "1925", "split_periods": True},
}


def parse_md_table(content: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for line in content.splitlines():
        if not line.strip().startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if all(re.fullmatch(r":?-+:?", cell or "-") for cell in cells):
            continue
        rows.append(cells)
    return rows


def clean_space(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def split_parenthetical(entry: str) -> tuple[str, str]:
    entry = clean_space(entry)
    match = re.search(r"\s*\(([^()]*)\)\s*$", entry)
    if not match:
        return entry, ""
    return clean_space(entry[: match.start()]), clean_space(match.group(1))


def markdown_for_stem(stem: str) -> tuple[dict, str]:
    data = json.loads((OCR_DIR / f"{stem}_mistral_raw.json").read_text(encoding="utf-8"))
    page = data["raw_response"]["pages"][0]
    markdown = page.get("markdown", "")
    for table in page.get("tables") or []:
        markdown += "\n" + table.get("content", "")
    return data, markdown


def extract_bank_name(markdown: str) -> str:
    for line in markdown.splitlines():
        line = line.strip()
        if line.startswith("# "):
            return clean_space(line[2:])
        if line.upper().startswith("BANCO "):
            return clean_space(line.lstrip("# "))
    return ""


def extract_balance_date(markdown: str) -> str:
    match = re.search(r"BALANCETE EM ([0-9]{1,2} DE [A-ZÇ]+ DE [0-9]{4})", markdown, re.I)
    return clean_space(match.group(1)) if match else ""


def extract_capital_reserve(markdown: str) -> tuple[str, str]:
    match = re.search(
        r"CAPITAL\s*\.*\s*(Cr\$\s*[\d.]+,\d+)\s*\.*\s*RESERVAS?\s*\.*\s*(Cr\$\s*[\d.]+,\d+)",
        markdown,
        re.I,
    )
    if not match:
        return "", ""
    return clean_space(match.group(1)), clean_space(match.group(2))


def extract_capital_reserve_general(markdown: str) -> tuple[str, str]:
    capital_match = re.search(r"(?:CAPITAL|Capital)\s*(?:E RESERVAS)?\s*\.*\s*(Cr\$\s*[\d.]+,\d+)", markdown)
    capital_raw = clean_space(capital_match.group(1)) if capital_match else ""
    reserve_parts = []
    for pattern in [
        r"RESERVAS?\s*\.*\s*(Cr\$\s*[\d.]+,\d+)",
        r"FUNDO DE RESERVA\s*\.*\s*(Cr\$\s*[\d.]+,\d+)",
        r"Fundo de Reserva(?: Legal)?\s*\.*\s*(Cr\$\s*[\d.]+,\d+)",
        r"FUNDOS DE RESERVA:[^.\n—]*\s*\.*\s*(Cr\$\s*[\d.]+,\d+)",
        r"OUTRAS RESERVAS\s*\.*\s*(Cr\$\s*[\d.]+,\d+)",
    ]:
        reserve_parts.extend(clean_space(value) for value in re.findall(pattern, markdown, re.I))
    seen = []
    for value in reserve_parts:
        if value not in seen:
            seen.append(value)
    return capital_raw, "; ".join(seen)


def extract_founding_year(markdown: str) -> str:
    match = re.search(r"FUNDADO(?:\s+EM)?\s+\d{1,2}\s+DE\s+[A-ZÇ]+(?:\s+DE)?\s+(\d{4})", markdown, re.I)
    if match:
        return match.group(1)
    match = re.search(r"FUNDADO(?:\s+EM)?(?:\s+[A-ZÇ]+)?\s+DE\s+(\d{4})", markdown, re.I)
    if match:
        return match.group(1)
    match = re.search(r"FUNDADO(?:\s+EM)?\s+(\d{4})", markdown, re.I)
    return match.group(1) if match else ""


def split_top_level_list(text: str, *, split_periods: bool = False) -> list[str]:
    separators = {",", ";", "—", "•"}
    if split_periods:
        separators.add(".")
    items: list[str] = []
    current: list[str] = []
    depth = 0
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")" and depth:
            depth -= 1
        if depth == 0 and ch in separators:
            item = clean_space("".join(current))
            if item:
                items.append(item)
            current = []
            i += 1
            continue
        if depth == 0 and text[i : i + 3].lower() == " e ":
            item = clean_space("".join(current))
            if item:
                items.append(item)
            current = []
            i += 3
            continue
        current.append(ch)
        i += 1
    item = clean_space("".join(current))
    if item:
        items.append(item)
    return items


def clean_item(value: str) -> str:
    value = clean_space(value)
    value = re.sub(r"\b(AGÊNCIAS?|AGENCIAS?|ESCRITÓRIOS?|ESCRITORIOS?|DEPARTAMENTOS|OUTROS DEPARTAMENTOS|DEPENDÊNCIAS|DEPENDENCIAS|FILIAIS)\s*(?:NO|NOS|EM)?\s*:?", "", value, flags=re.I)
    value = re.sub(r"^[\s:–—.-]+", "", value)
    value = re.sub(r"[\s:–—.-]+$", "", value)
    value = value.replace("MATRIZ —", "").strip()
    return clean_space(value)


def is_skip_item(value: str) -> bool:
    text = value.upper()
    if not value or len(value) <= 1:
        return True
    skip_tokens = [
        "CAPITAL",
        "CARTA PATENTE",
        "BALANCETE",
        "DIRETOR",
        "CONSELHO",
        "RUA ",
        "AV.",
        "AVENIDA ",
        "CAIXA POSTAL",
        "END.",
        "TELEF",
        "PRESIDENTE",
        "VICE-PRESIDENTE",
        "DEPÓSITOS GARANTIDOS",
        "CORRESPONDENTE SOB CONTROLE",
    ]
    return any(token in text for token in skip_tokens)


def parent_city_from_parenthetical(parenthetical: str) -> tuple[str, str]:
    raw = clean_space(parenthetical)
    text = raw.upper()
    state = ""
    for key, value in {
        "SP": "SP",
        "S. PAULO": "SP",
        "GB": "GB",
        "G.B": "GB",
        "RJ": "RJ",
        "MG": "MG",
        "PR": "PR",
        "SC": "SC",
        "RS": "RS",
        "GO": "GO",
        "DF": "DF",
        "D. F": "DF",
        "BA": "BA",
        "CE": "CE",
        "PA": "PA",
        "AL": "AL",
        "AM": "AM",
        "MA": "MA",
        "PB": "PB",
        "PE": "PE",
        "PI": "PI",
        "RN": "RN",
        "SE": "SE",
        "BE": "SE",
        "MT": "MT",
        "MS": "MT",
        "ES": "ES",
        "AP": "AP",
    }.items():
        if re.search(rf"\b{re.escape(key)}\.?\b", text):
            state = value
            break
    city = ""
    for key, value in {
        "BELO HORIZONTE": "Belo Horizonte",
        "B. HORIZ": "Belo Horizonte",
        "SÃO PAULO": "São Paulo",
        "S. PAULO": "São Paulo",
        "RIO DE JANEIRO": "Rio de Janeiro",
        "R. DE JANEIRO": "Rio de Janeiro",
        "J. DE FORA": "Juiz de Fora",
        "JUIZ DE FORA": "Juiz de Fora",
        "PORTO ALEGRE": "Porto Alegre",
        "P. ALEGRE": "Porto Alegre",
        "SALVADOR": "Salvador",
        "RECIFE": "Recife",
        "VITÓRIA": "Vitória",
        "VITORIA": "Vitória",
        "GOIÂNIA": "Goiânia",
        "GOIANIA": "Goiânia",
        "BRASÍLIA": "Brasília",
        "BRASILIA": "Brasília",
        "LONDRINA": "Londrina",
        "CURITIBA": "Curitiba",
        "NITERÓI": "Niterói",
        "NITEROI": "Niterói",
        "UBERABA": "Uberaba",
        "PELOTAS": "Pelotas",
        "CAXIAS DO SUL": "Caxias do Sul",
        "RIBEIRÃO PRETO": "Ribeirão Preto",
    }.items():
        if key in text:
            city = value
            break
    return city, state


def normalize_municipality(raw_name: str) -> str:
    value = clean_item(raw_name)
    return NAME_CORRECTIONS.get(value, value)


def row_from_item(
    *,
    source_image: str,
    bank_name: str,
    founding_year: str,
    capital_raw: str,
    reserve_raw: str,
    raw_entry: str,
    default_state: str,
    section_parent_city: str = "",
    default_note: str = "",
) -> dict[str, str] | None:
    raw_entry = clean_item(raw_entry)
    if is_skip_item(raw_entry):
        return None
    base, parenthetical = split_parenthetical(raw_entry)
    municipality = normalize_municipality(base)
    state = CITY_STATE_OVERRIDES.get(municipality, default_state)
    branch_location = ""
    notes = default_note
    parent_city, parent_state = parent_city_from_parenthetical(parenthetical)
    if parent_state:
        state = parent_state
    if section_parent_city:
        branch_location = municipality
        municipality = section_parent_city
        state = CITY_STATE_OVERRIDES.get(section_parent_city, state)
        notes = "; ".join(filter(None, [notes, "Urban/metropolitan branch location"]))
    elif parent_city:
        branch_location = municipality
        municipality = parent_city
        state = CITY_STATE_OVERRIDES.get(parent_city, parent_state or state)
    elif default_state == "GB":
        branch_location = municipality
        municipality = "Rio de Janeiro"
        state = "GB"
    if not state:
        state = CITY_STATE_OVERRIDES.get(municipality, "")
    return {
        "source_image": source_image,
        "bank_name": bank_name,
        "founding_year": founding_year,
        "balance_date": "",
        "capital_raw": capital_raw,
        "reserve_raw": reserve_raw,
        "raw_entry": raw_entry,
        "municipality": municipality,
        "state": state,
        "parenthetical_raw": parenthetical,
        "branch_location": branch_location,
        "notes": notes,
    }


def state_sections(markdown: str) -> list[tuple[str, str, str]]:
    matches = []
    for pattern, state, parent_city in STATE_HEADER_SPECS:
        for match in re.finditer(pattern + r"\s*:?", markdown, re.I):
            matches.append((match.start(), match.end(), state, parent_city))
    matches.sort()
    sections: list[tuple[str, str, str]] = []
    stop_re = re.compile(r"\b(BALANCETE|CONSELHO|DIRETORIA|Depósitos garantidos|Correspondente sob controle)\b", re.I)
    for idx, (_start, end, state, parent_city) in enumerate(matches):
        next_start = matches[idx + 1][0] if idx + 1 < len(matches) else len(markdown)
        content = markdown[end:next_start]
        stop = stop_re.search(content)
        if stop:
            content = content[: stop.start()]
        sections.append((state, parent_city, content))
    return sections


def add_config_rows(
    rows: list[dict[str, str]],
    *,
    source_image: str,
    bank_name: str,
    founding_year: str,
    capital_raw: str,
    reserve_raw: str,
    pre_rows: list[tuple[str, str, str, str, str]],
) -> None:
    for raw_entry, municipality, state, branch_location, notes in pre_rows:
        rows.append(
            {
                "source_image": source_image,
                "bank_name": bank_name,
                "founding_year": founding_year,
                "balance_date": "",
                "capital_raw": capital_raw,
                "reserve_raw": reserve_raw,
                "raw_entry": raw_entry,
                "municipality": municipality,
                "state": state,
                "parenthetical_raw": "",
                "branch_location": branch_location,
                "notes": notes,
            }
        )


def build_generic_rows(stem: str) -> list[dict[str, str]]:
    data, markdown = markdown_for_stem(stem)
    config = GENERIC_CONFIGS.get(stem, {})
    source_image = Path(data["source"]).name
    bank_name = extract_bank_name(markdown)
    founding_year = config.get("founding_year") or extract_founding_year(markdown)
    capital_raw, reserve_raw = extract_capital_reserve_general(markdown)
    capital_raw = config.get("capital_raw", capital_raw)
    reserve_raw = config.get("reserve_raw", reserve_raw)
    rows: list[dict[str, str]] = []
    add_config_rows(
        rows,
        source_image=source_image,
        bank_name=bank_name,
        founding_year=founding_year,
        capital_raw=capital_raw,
        reserve_raw=reserve_raw,
        pre_rows=config.get("pre_rows", []),
    )

    markdown_for_sections = markdown
    if config.get("ignore_before") and config["ignore_before"] in markdown_for_sections:
        markdown_for_sections = config["ignore_before"] + markdown_for_sections.split(config["ignore_before"], 1)[1]
    if config.get("ignore_after"):
        markdown_for_sections = markdown_for_sections.split(config["ignore_after"], 1)[0]
    sections = [] if config.get("force_list") else state_sections(markdown_for_sections)
    if sections:
        for state, parent_city, content in sections:
            for item in split_top_level_list(content, split_periods=config.get("split_periods", False)):
                row = row_from_item(
                    source_image=source_image,
                    bank_name=bank_name,
                    founding_year=founding_year,
                    capital_raw=capital_raw,
                    reserve_raw=reserve_raw,
                    raw_entry=item,
                    default_state=state,
                    section_parent_city=parent_city,
                )
                if row:
                    rows.append(row)
    if config.get("list_after") and (config.get("force_list") or not sections):
        content = markdown_for_sections.split(config["list_after"], 1)[-1]
        if content == markdown_for_sections:
            content = markdown_for_sections
        if config.get("ignore_after") and config["ignore_after"] in content:
            content = content.split(config["ignore_after"], 1)[0]
        for item in split_top_level_list(content, split_periods=config.get("split_periods", False)):
            row = row_from_item(
                source_image=source_image,
                bank_name=bank_name,
                founding_year=founding_year,
                capital_raw=capital_raw,
                reserve_raw=reserve_raw,
                raw_entry=item,
                default_state=config.get("default_state", ""),
            )
            if row:
                rows.append(row)
    return rows


def build_bsp_rows() -> list[dict[str, str]]:
    data, markdown = markdown_for_stem("bsp")
    source_image = Path(data["source"]).name
    bank_name = extract_bank_name(markdown)
    capital_raw, reserve_raw = extract_capital_reserve_general(markdown)
    rows: list[dict[str, str]] = []
    current_state = "SP"
    current_parent = "São Paulo"
    for table in data["raw_response"]["pages"][0].get("tables", []):
        for cells in parse_md_table(table["content"]):
            for cell in cells:
                item = clean_item(cell)
                upper = item.upper()
                if not item:
                    continue
                if "NA CIDADE DE SÃO PAULO" in upper:
                    current_state = "SP"
                    current_parent = "São Paulo"
                    continue
                if "NO ESTADO DE SÃO PAULO" in upper:
                    current_state = "SP"
                    current_parent = ""
                    continue
                if "NO ESTADO DO PARANÁ" in upper:
                    current_state = "PR"
                    current_parent = ""
                    continue
                row = row_from_item(
                    source_image=source_image,
                    bank_name=bank_name,
                    founding_year="1889",
                    capital_raw=capital_raw,
                    reserve_raw=reserve_raw,
                    raw_entry=item.title() if item.isupper() else item,
                    default_state=current_state,
                    section_parent_city=current_parent,
                )
                if row:
                    rows.append(row)
    return rows


def build_banespa_rows() -> list[dict[str, str]]:
    data = json.loads((OCR_DIR / "banespa_1960_mistral_raw.json").read_text(encoding="utf-8"))
    page = data["raw_response"]["pages"][0]
    bank_name = extract_bank_name(page.get("markdown", ""))
    balance_date = extract_balance_date(page.get("markdown", ""))
    source_image = Path(data["source"]).name
    rows: list[dict[str, str]] = []

    for table in page.get("tables", []):
        for cells in parse_md_table(table["content"]):
            for raw_entry in cells:
                raw_entry = clean_space(raw_entry)
                if not raw_entry:
                    continue
                base_name, parenthetical = split_parenthetical(raw_entry)
                state = STATE_MAP.get(parenthetical, "SP")
                correction = BANESPA_CORRECTIONS.get(base_name, {})
                municipality = correction.get("municipality", base_name)
                state = correction.get("state", state)
                branch_location = correction.get("branch_location", "")
                notes = correction.get("notes", "")

                rows.append(
                    {
                        "source_image": source_image,
                        "bank_name": bank_name,
                        "founding_year": "1909",
                        "balance_date": balance_date,
                        "capital_raw": "",
                        "reserve_raw": "",
                        "raw_entry": raw_entry,
                        "municipality": municipality,
                        "state": state,
                        "parenthetical_raw": parenthetical,
                        "branch_location": branch_location,
                        "notes": notes,
                    }
                )
    return rows


def build_bbahia_rows() -> list[dict[str, str]]:
    data = json.loads((OCR_DIR / "bbahia_mistral_raw.json").read_text(encoding="utf-8"))
    page = data["raw_response"]["pages"][0]
    markdown = page.get("markdown", "")
    bank_name = extract_bank_name(markdown)
    capital_raw, reserve_raw = extract_capital_reserve(markdown)
    source_image = Path(data["source"]).name
    rows: list[dict[str, str]] = []

    for raw_entry, municipality, state, branch_location, notes in BBAHIA_BRANCHES:
        rows.append(
            {
                "source_image": source_image,
                "bank_name": bank_name,
                "founding_year": extract_founding_year(markdown),
                "balance_date": "",
                "capital_raw": capital_raw,
                "reserve_raw": reserve_raw,
                "raw_entry": raw_entry,
                "municipality": municipality,
                "state": state,
                "parenthetical_raw": "",
                "branch_location": branch_location,
                "notes": notes,
            }
        )
    return rows


def build_bcomercindmg_rows() -> list[dict[str, str]]:
    data = json.loads((OCR_DIR / "bcomercindmg_mistral_raw.json").read_text(encoding="utf-8"))
    page = data["raw_response"]["pages"][0]
    markdown = page.get("markdown", "")
    bank_name = extract_bank_name(markdown)
    source_image = Path(data["source"]).name
    founding_year = extract_founding_year(markdown)
    rows: list[dict[str, str]] = []

    for raw_entry, municipality, state, branch_location, notes in BCOMERCINDMG_BRANCHES:
        rows.append(
            {
                "source_image": source_image,
                "bank_name": bank_name,
                "founding_year": founding_year,
                "balance_date": "",
                "capital_raw": "",
                "reserve_raw": "",
                "raw_entry": raw_entry,
                "municipality": municipality,
                "state": state,
                "parenthetical_raw": "",
                "branch_location": branch_location,
                "notes": notes,
            }
        )
    return rows


def build_bcomercindsp_rows() -> list[dict[str, str]]:
    data = json.loads((OCR_DIR / "bcomercindsp_mistral_raw.json").read_text(encoding="utf-8"))
    page = data["raw_response"]["pages"][0]
    markdown = page.get("markdown", "")
    bank_name = extract_bank_name(markdown)
    source_image = Path(data["source"]).name
    capital_match = re.search(r"Capital\s*\.*\s*(Cr\$\s*[\d.]+,\d+)", markdown, re.I)
    reserve_matches = re.findall(
        r"(Fundo de Reserva(?: Legal)?\s*\.*\s*Cr\$\s*[\d.]+,\d+)", markdown, re.I
    )
    capital_raw = clean_space(capital_match.group(1)) if capital_match else ""
    reserve_raw = "; ".join(clean_space(value) for value in reserve_matches)
    rows: list[dict[str, str]] = []

    for raw_entry, municipality, state, branch_location, notes in BCOMERCINDSP_BRANCHES:
        rows.append(
            {
                "source_image": source_image,
                "bank_name": bank_name,
                "founding_year": "1889",
                "balance_date": "",
                "capital_raw": capital_raw,
                "reserve_raw": reserve_raw,
                "raw_entry": raw_entry,
                "municipality": municipality,
                "state": state,
                "parenthetical_raw": "",
                "branch_location": branch_location,
                "notes": notes,
            }
        )
    return rows


def main() -> None:
    rows = []
    rows.extend(build_banespa_rows())
    rows.extend(build_bbahia_rows())
    rows.extend(build_bcomercindmg_rows())
    rows.extend(build_bcomercindsp_rows())
    for stem in [
        "bcomercpr",
        "bcomercsp",
        "bcreditmg_1960",
        "bdescontos",
        "bestadopr",
        "bestadors",
        "bhipotecario",
        "bhipotecariomg",
        "bindsul",
        "bitau",
        "blavoura_1960",
        "bmercantilmg_1960",
        "bmercantilsp",
        "bmg",
        "bmoreirasalles",
        "bnacionalcomerc",
        "bnacionalmg_1960",
        "bnordeste",
        "bnoroeste",
        "bpredrj",
        "bproducaomg",
        "bsc",
    ]:
        rows.extend(build_generic_rows(stem))
    rows.extend(build_bsp_rows())
    CSV_DIR.mkdir(parents=True, exist_ok=True)
    out_path = CSV_DIR / "bank_branches_1960.csv"
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=OUTPUT_FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {len(rows)} rows to {out_path}")


if __name__ == "__main__":
    main()

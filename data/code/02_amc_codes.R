rm(list = ls())
library(sf)
library(dplyr)
library(ggplot2)
library(haven)
library(magrittr)
library(tmap)
library(readxl)
library(purrr)
library(magick)
library(here)

#################### 1. Plots Coffee Production in SP since 1836 ###############
# bring shapefile and amc panel data
amc_1950 <- st_read("../../data/raw/shapefiles/amc_ehrl_shape/amc_1950_2010.shp") %>%
  rename(codmicro = MICRORREGI, amc = amc_1950_2, state_code = UF,
         codmeso = MESORREGIÃ, amc_name = NOME_MUNIC, state_abbrev = SIGLA,
         micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry) %>%
  mutate(amc = as.double(amc))

amc_1940 <- st_read("../../data/raw/shapefiles/amc_ehrl_shape/amc_1940_2010.shp") %>%
  rename(codmicro = MICRORREGI, amc = amc_1940_2, state_code = UF,
         codmeso = MESORREGIÃ, amc_name = NOME_MUNIC, state_abbrev = SIGLA,
         micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry) %>%
  mutate(amc = as.double(amc))

# save crosswalk codes
amc_codes_1940 <- st_drop_geometry(amc_1940)
amc_codes_1950 <- st_drop_geometry(amc_1950)

write_dta(amc_codes_1940, "../output/amc_codes_1940.dta")
write_dta(amc_codes_1950, "../output/amc_codes_1950.dta")


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

#################### 1. Make Microregion Shapefile #############################

## 1940 ##
amc_1940 <- st_read("../raw/shapefiles/amc_ehrl_shape/amc_1940_2010.shp") %>%
  rename(codmicro = MICRORREGI, amc = amc_1940_2, state_code = UF,
         codmeso = MESORREGIÃ, amc_name = NOME_MUNIC, state_abbrev = SIGLA,
         micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry) %>%
  mutate(amc = as.double(amc),
         codmicro = as.double(codmicro))

micro_1940 <- amc_1940 %>%
  group_by(codmicro) %>% 
  summarise(geometry = st_union(geometry))

# save
st_write(micro_1940, "../output/shapefiles/micro_1940.shp")

## 1950 ##
amc_1950 <- st_read("../raw/shapefiles/amc_ehrl_shape/amc_1950_2010.shp") %>%
  rename(codmicro = MICRORREGI, amc = amc_1950_2, state_code = UF,
         codmeso = MESORREGIÃ, amc_name = NOME_MUNIC, state_abbrev = SIGLA,
         micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry) %>%
  mutate(amc = as.double(amc),
         codmicro = as.double(codmicro))

micro_1950 <- amc_1950 %>%
  group_by(codmicro) %>% 
  summarise(geometry = st_union(geometry))

# save
st_write(micro_1950, "../output/shapefiles/micro_1950.shp")



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

#################### 1. Calcualte Area of AMCs #################################
# bring shapefile and amc panel data
amc_area_1950 <- st_read("../../data/raw/shapefiles/amc_ehrl_shape/amc_1950_2010.shp") %>%
  rename(codmicro = MICRORREGI, amc = amc_1950_2, state_code = UF,
         codmeso = MESORREGIÃ, amc_name = NOME_MUNIC, state_abbrev = SIGLA,
         micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry) %>%
  mutate(amc = as.double(amc))

amc_area_1940 <- st_read("../../data/raw/shapefiles/amc_ehrl_shape/amc_1940_2010.shp") %>%
  rename(codmicro = MICRORREGI, amc = amc_1940_2, state_code = UF,
         codmeso = MESORREGIÃ, amc_name = NOME_MUNIC, state_abbrev = SIGLA,
         micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry) %>%
  mutate(amc = as.double(amc))

# calculate area and save
amc_area_1940 %<>% mutate(area_amc_1940 =  st_area(geometry)/1000000) %>%
  dplyr::select(amc, area_amc_1940) %>%
  st_drop_geometry()
amc_area_1950 %<>% mutate(area_amc_1950 =  st_area(geometry)/1000000) %>%
  dplyr::select(amc, area_amc_1950) %>%
  st_drop_geometry()

write_dta(amc_1940, "../output/amc_area_1940.dta")
write_dta(amc_1950, "../output/amc_area_1950.dta")


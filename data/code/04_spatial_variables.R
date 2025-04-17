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

#################### 1. Calcualate Area of AMCs #################################
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


micro_area_1940 <- st_read("../output/shapefiles/micro_1940.shp")
micro_area_1950 <- st_read("../output/shapefiles/micro_1950.shp")

# calculate area and save
amc_area_1940 %<>% mutate(area_amc_1940 =  st_area(geometry)/1000000) %>%
  dplyr::select(amc, area_amc_1940) %>%
  st_drop_geometry()
amc_area_1950 %<>% mutate(area_amc_1950 =  st_area(geometry)/1000000) %>%
  dplyr::select(amc, area_amc_1950) %>%
  st_drop_geometry()

micro_area_1940 %<>% mutate(micro_area_1940 =  st_area(geometry)/1000000) %>%
  dplyr::select(codmicro, micro_area_1940) %>%
  st_drop_geometry()

micro_area_1950 %<>% mutate(micro_area_1950 =  st_area(geometry)/1000000) %>%
  dplyr::select(codmicro, micro_area_1950) %>%
  st_drop_geometry()

# save
write_dta(amc_area_1940, "../output/amc_area_1940.dta")
write_dta(amc_area_1950, "../output/amc_area_1950.dta")
write_dta(micro_area_1940, "../output/micro_area_1940.dta")
write_dta(micro_area_1950, "../output/micro_area_1950.dta")


#################### 2. Distance to Railroads ##################################
# read 1960 railroad shapefile
rail_1960 <- st_read("../raw/shapefiles/highway_1960/Rodovias_anos60.shp") %>%
  st_transform(crs = st_crs(amc_1940))

# compute centroids
centroid_amc_1940 <- st_centroid(amc_1940)
centroid_amc_1950 <- st_centroid(amc_1950)
centroid_micro_1940 <- st_centroid(micro_1940)
centroid_micro_1950 <- st_centroid(micro_1950)

# compute distance to 1960 rail
dist_rail_amc_1940 <- amc_1940 %>% mutate(rail_dist = st_distance(centroid_amc_1940, st_union(rail_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, rail_dist)

dist_rail_amc_1950 <- amc_1950 %>% mutate(rail_dist = st_distance(centroid_amc_1950, st_union(rail_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, rail_dist)

dist_rail_micro_1940 <- micro_1940 %>% mutate(rail_dist = st_distance(centroid_micro_1940, st_union(rail_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, rail_dist)

dist_rail_micro_1950 <- micro_1950 %>% mutate(rail_dist = st_distance(centroid_micro_1950, st_union(rail_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, rail_dist)


# save
write_dta(dist_rail_amc_1940, "../output/dist_rail_amc_1940.dta")
write_dta(dist_rail_amc_1950, "../output/dist_rail_amc_1950.dta")
write_dta(dist_rail_micro_1940, "../output/dist_rail_micro_1940.dta")
write_dta(dist_rail_micro_1950, "../output/dist_rail_micro_1950.dta")


####################### 3. Distance to Highway #################################






####################### 4. Distance to Ports ###################################
# read port shapefile
port_shp <- st_read("../raw/shapefiles/ports/GEOFT_PORTO.shp") %>%
  st_transform(crs = st_crs(amc_1950))

### Restrict to major ports only ###
major_port <- c("PORTO DE MANAUS", "PORTO DE BELÉM", "PORTO DE ITAQUI", 
                    "PORTO DE LUÍS CORREA", "PORTO DE FORTALEZA", "PORTO DE NATAL", 
                    "PORTO DE CABEDELO", "PORTO DE RECIFE", "PORTO DE MACEIÓ",
                    "TERMINAL DE BARRA DOS COQUEIROS", "PORTO DE SALVADOR", "PORTO DE VITÓRIA",
                    "PORTO DO RIO DE JANEIRO", "PORTO DE SANTOS", "PORTO DE PARANAGUÁ",
                    "TERMINAL HIDROVIÁRIO DE FLORIANÓPOLIS", "PORTO DE PORTO ALEGRE")

port_shp %<>% filter(POR_NM %in% major_port)

# compute distance to major ports
dist_port_amc_1940 <- amc_1940 %>% mutate(port_dist = st_distance(centroid_amc_1940, st_union(port_shp))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, port_dist)

dist_port_amc_1950 <- amc_1950 %>% mutate(port_dist = st_distance(centroid_amc_1950, st_union(port_shp))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, port_dist)

dist_port_micro_1940 <- micro_1940 %>% mutate(port_dist = st_distance(centroid_micro_1940, st_union(port_shp))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, port_dist)

dist_port_micro_1950 <- micro_1950 %>% mutate(port_dist = st_distance(centroid_micro_1950, st_union(port_shp))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, port_dist)


# save
write_dta(dist_port_amc_1940, "../output/dist_port_amc_1940.dta")
write_dta(dist_port_amc_1950, "../output/dist_port_amc_1950.dta")
write_dta(dist_port_micro_1940, "../output/dist_port_micro_1940.dta")
write_dta(dist_port_micro_1950, "../output/dist_port_micro_1950.dta")




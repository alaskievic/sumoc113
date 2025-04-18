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

# read amcs and microregions #
amc_1940 <- st_read("../../data/raw/shapefiles/amc_ehrl_shape/amc_1940_2010.shp") %>%
  rename(amc = amc_1940_2) %>%
  mutate(amc = as.double(amc))

amc_1950 <- st_read("../../data/raw/shapefiles/amc_ehrl_shape/amc_1950_2010.shp") %>%
  rename(amc = amc_1940_2) %>%
  mutate(amc = as.double(amc))

micro_1940 <- st_read("../output/shapefiles/micro_1940.shp")
micro_1950 <- st_read("../output/shapefiles/micro_1950.shp")

# bring shapefile and amc panel data
amc_area_1950 <- amc_1950 %>%
  rename(codmicro = MICRORREGI, state_code = UF, codmeso = MESORREGIÃ,
         amc_name = NOME_MUNIC, state_abbrev = SIGLA, micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry)

amc_area_1940 <- amc_1940 %>%
  rename(codmicro = MICRORREGI, state_code = UF, codmeso = MESORREGIÃ,
         amc_name = NOME_MUNIC, state_abbrev = SIGLA, micro_name = NOME_MICRO) %>%
  dplyr::select(state_code, state_abbrev, amc, amc_name, codmicro, micro_name, codmeso,
                geometry)

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


#################### 2. Distance to Railroads ##################################
# read 1950 railroad shapefile
rail_1950 <- st_read("../raw/shapefiles/railroads/1954/rail_1954.shp") %>%
  st_transform(crs = st_crs(amc_1940))

# compute centroids
centroid_amc_1940 <- st_centroid(amc_1940)
centroid_amc_1950 <- st_centroid(amc_1950)
centroid_micro_1940 <- st_centroid(micro_1940)
centroid_micro_1950 <- st_centroid(micro_1950)

# compute distance to 1950 rail
dist_rail_amc_1940 <- amc_1940 %>% mutate(rail_dist = st_distance(centroid_amc_1940, st_union(rail_1950))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, rail_dist)

dist_rail_amc_1950 <- amc_1950 %>% mutate(rail_dist = st_distance(centroid_amc_1950, st_union(rail_1950))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, rail_dist)

dist_rail_micro_1940 <- micro_1940 %>% mutate(rail_dist = st_distance(centroid_micro_1940, st_union(rail_1950))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, rail_dist)

dist_rail_micro_1950 <- micro_1950 %>% mutate(rail_dist = st_distance(centroid_micro_1950, st_union(rail_1950))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, rail_dist)

####################### 3. Distance to Highway #################################

# read 1960 highway shapefile
road_1960 <- st_read("../raw/shapefiles/highway_1960/Rodovias_anos60.shp") %>%
  st_transform(crs = st_crs(amc_1940))

# compute distance to 1960 road
dist_road_amc_1940 <- amc_1940 %>% mutate(road_dist = st_distance(centroid_amc_1940, st_union(road_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, road_dist)

dist_road_amc_1950 <- amc_1950 %>% mutate(road_dist = st_distance(centroid_amc_1950, st_union(road_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(amc, road_dist)

dist_road_micro_1940 <- micro_1940 %>% mutate(road_dist = st_distance(centroid_micro_1940, st_union(road_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, road_dist)

dist_road_micro_1950 <- micro_1950 %>% mutate(road_dist = st_distance(centroid_micro_1950, st_union(road_1960))/1000) %>%
  st_drop_geometry %>%
  dplyr::select(codmicro, road_dist)

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



####################### 5. Capital Dummies #####################################

capital_amc_1940   <- c(1015, 1041, 2008, 3039, 4011, 4080, 5027, 6008, 7050, 8024,
                        9003, 10057, 11062, 11317, 12039, 13202, 14079, 14004, 
                        15065, 16011, 21001)
capital_micro_1940 <- c(12004, 13007, 15007, 21002, 22006, 23016, 24018, 25023, 26019,
                        27011, 28011, 29021, 31030, 32009, 33018, 35057, 41037, 
                        42016, 43033, 51016, 52010)

capital_amc_1950   <- c(1047, 21001, 1015, 2015, 3039, 4011, 4081, 5027, 6008, 7078, 
                        8028, 9003, 10057, 11417, 11063, 12044, 13264, 14041, 
                        14115, 15069, 16011)
capital_micro_1950 <- c(12004, 13007, 15007, 21002, 22006, 23016, 24018, 25023, 
                        26017, 27011, 28011, 29021, 31030, 32009, 33018, 35057, 
                        41037, 42016, 43033, 51016, 52010)


dcapital_amc_1940 <- mutate(amc_1940, d_capital = case_when(amc %in% capital_amc_1940 ~ 1, .default = 0)) %>%
  dplyr::select(amc, d_capital) %>%
  st_drop_geometry()

dcapital_micro_1940 <- mutate(micro_1940, d_capital = case_when(codmicro %in% capital_micro_1940 ~ 1, .default = 0)) %>%
  dplyr::select(codmicro, d_capital) %>%
  st_drop_geometry()


dcapital_amc_1950 <- mutate(amc_1950, d_capital = case_when(amc %in% capital_amc_1950 ~ 1, .default = 0)) %>%
  dplyr::select(amc, d_capital) %>%
  st_drop_geometry()


dcapital_micro_1950 <- mutate(micro_1950, d_capital = case_when(codmicro %in% capital_micro_1950 ~ 1, .default = 0)) %>%
  dplyr::select(codmicro, d_capital) %>%
  st_drop_geometry()


####################### 6. Append Dummy Dataset ################################

control_amc_1940 <- inner_join(amc_area_1940, dist_rail_amc_1940, by = "amc") %>%
                    inner_join(., dist_road_amc_1940, by = "amc") %>%
                    inner_join(., dist_port_amc_1940, by = "amc") %>%
                    inner_join(., dcapital_amc_1940, by = "amc")

control_amc_1950 <- inner_join(amc_area_1950, dist_rail_amc_1950, by = "amc") %>%
  inner_join(., dist_road_amc_1950, by = "amc") %>%
  inner_join(., dist_port_amc_1950, by = "amc") %>%
  inner_join(., dcapital_amc_1950, by = "amc")

control_micro_1940 <- inner_join(micro_area_1940, dist_rail_micro_1940, by = "codmicro") %>%
  inner_join(., dist_road_micro_1940, by = "codmicro") %>%
  inner_join(., dist_port_micro_1940, by = "codmicro") %>%
  inner_join(., dcapital_micro_1940, by = "codmicro")

control_micro_1950 <- inner_join(micro_area_1950, dist_rail_micro_1950, by = "codmicro") %>%
  inner_join(., dist_road_micro_1950, by = "codmicro") %>%
  inner_join(., dist_port_micro_1950, by = "codmicro") %>%
  inner_join(., dcapital_micro_1950, by = "codmicro")

# save
write_dta(control_amc_1940, "../output/control_amc_1940.dta")
write_dta(control_amc_1940, "../output/control_amc_1940.dta")
write_dta(control_amc_1940, "../output/control_amc_1940.dta")
write_dta(control_amc_1940, "../output/control_amc_1940.dta")

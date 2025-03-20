rm(list = ls())
library(sf)
library(dplyr)
library(ggplot2)
library(haven)
library(magrittr)
library(tmap)

# bring shapefile and csv
mun_shape <- st_read("../../data/output/mun_consistent_1872_1950.shp")
mun_data <- read_dta("../../data/output/panel_mun_1872_1950.dta")

# dataset
get_vars <- mun_data %>% filter(year == 1950) 
get_vars <- get_vars %>% select(mun_code, manufac_emp, share_tr, 
                                num_farm, num_farm_coffee, foreign_pop_share,
                                total_foreign)
get_vars <- get_vars %>% rename(cd2010_ = mun_code)
mun_shape <- mun_shape %>% left_join(get_vars, by = "cd2010_")

# plot map with mfg in 1950
map_plot <- ggplot(data = mun_shape) +
  geom_sf(aes(fill = log(manufac_emp+1)), color = "black", lwd = 0.03) +
  scale_fill_viridis_c() +
  labs(fill = "log of mfg emp")
print(map_plot)
ggsave("../output/map_mfg_share_1950.png", plot = map_plot, device = "png")

# plot map with coffee in 1950
map_plot <- ggplot(data = mun_shape) +
  geom_sf(aes(fill = log(num_farm_coffee+1)), color = "black", lwd = 0.03) +
  scale_fill_viridis_c() +
  labs(fill = "log of coffee production")
print(map_plot)
ggsave("../output/map_coffee_prod_1950.png", plot = map_plot, device = "png")

# plot map with terra roxa
map_plot <- ggplot(data = mun_shape) +
  geom_sf(aes(fill = log(share_tr+0.01)), color = "black", lwd = 0.03) +
  scale_fill_viridis_c() +
  labs(fill = "log of share")
print(map_plot)
ggsave("../output/map_share_tr.png", plot = map_plot, device = "png")

# plot map with immigrants
mun_shape <- mun_shape %>% mutate(map_var = total_foreign)
mun_shape <- mun_shape %>% mutate(quintile = ntile(map_var, 5))
mun_shape <- mun_shape %>% group_by(quintile) %>% mutate(avg_values = mean(map_var))
map_plot <- ggplot(data = mun_shape) +
  geom_sf(aes(fill = log(total_foreign+1)), color = "black", lwd = 0.03) +
  scale_fill_viridis_c() +
  labs(fill = "log of foreign workers")
print(map_plot)
ggsave("../output/map_foreign.png", plot = map_plot, device = "png")



######################### 1. Cross-Section Maps ################################
mun_shape <- st_read("../../data/output/mun_consistent_1872_1950.shp") %>%
  rename(mun_code = cd2010_)
mun_data <- read_dta("../../data/output/panel_mun_1872_1950.dta")
state_1950 <- st_read("../../data/output/shapefiles/state_1950/04-limite estadual 1950.shp") %>%
  filter(nome != "Território do Acre")
sp_border <- state_1950 %>% filter(nome == "São Paulo")

mun_data %<>% dplyr::select(year, mun_code, mun_name, state_code, state_name,
                            meso_code_1872, total_pop, total_br, total_foreign, br_pop_share,
                            foreign_pop_share, manufac_emp, agri_emp, service_emp,
                            manufac_emp_share, agri_emp_share, service_emp_share,
                            share_tr, share_red, total_area) %>%
  filter(year %in% c(1872, 1890, 1920, 1940, 1950)) %>%
  mutate(total_tr = (share_tr*total_area)/1000, total_red = (share_red*total_area)/1000)

mun_data_1872 <- filter(mun_data, year == 1872)
mun_data_1872 <- full_join(mun_shape, mun_data_1872)





share_tr <- tm_shape(mun_data_1872) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "share_tr",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.1, 0.25, 0.5, 0.75, 1),
          title = "Share of Terra Roxa",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(share_tr)
tmap_save(share_tr, "../output/share_tr.png")



share_red <- tm_shape(mun_data_1872) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "share_red",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.1, 0.25, 0.5, 0.75, 1),
          title = "Share of Terra Roxa",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(share_red)
tmap_save(share_red, "../output/share_tr.png")


area_red <- tm_shape(mun_data_1872) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "total_red",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 10, 25, 50, 75, 100),
          title = "Total Terra Roxa Area (Thousands of Km2)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(area_red)
tmap_save(area_red, "../output/area_red.png")






manufac_sh_1872 <- tm_shape(mun_data_1872) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_emp_share",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.1, 0.2, 0.3, 0.4),
          title = "Manufacturing Employment Share in 1872",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(manufac_sh_1872)
tmap_save(manufac_sh_1872, "../output/manufac_sh_1872.png")


agri_sh_1872 <- tm_shape(mun_data_1872) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_emp_share",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.3, 0.5, 0.7, 0.9, 1),
          title = "Agriculture Employment Share in 1872",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(agri_sh_1872)
tmap_save(agri_sh_1872, "../output/agri_sh_1872.png")


mun_data_1950 <- filter(mun_data, year == 1950)
mun_data_1950 <- full_join(mun_shape, mun_data_1950)


manufac_sh_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_emp_share",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.1, 0.2, 0.3, 0.6),
          title = "Manufacturing Employment Share in 1950",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(manufac_sh_1950)
tmap_save(manufac_sh_1950, "../output/manufac_sh_1950.png")


agri_sh_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_emp_share",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.3, 0.5, 0.7, 0.9, 1),
          title = "Agriculture Employment Share in 1950",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(agri_sh_1950)
tmap_save(agri_sh_1950, "../output/agri_sh_1950.png")







######################### 2. Growth Rate Maps ##################################
# bring shapefile and dta
mun_shape <- st_read("../../data/output/mun_consistent_1872_1950.shp") %>%
  rename(mun_code = cd2010_)
mun_data <- read_dta("../../data/output/panel_mun_1872_1950.dta")
state_1950 <- st_read("../../data/output/shapefiles/state_1950/04-limite estadual 1950.shp") %>%
  filter(nome != "Território do Acre")
sp_border <- state_1950 %>% filter(nome == "São Paulo")

meso_shp <- st_read("../../data/output/shapefiles/meso_2022/BR_Mesorregioes_2022.shp")

mun_data %<>% dplyr::select(year, mun_code, mun_name, state_code, state_name,
                            meso_code_1872, total_pop, total_br, total_foreign, br_pop_share,
                            foreign_pop_share, manufac_emp, agri_emp, service_emp,
                            manufac_emp_share, agri_emp_share, service_emp_share) %>%
  mutate(manufac_emp_total = sum(manufac_emp)) %>%
  mutate(manufac_sh_total = manufac_emp/manufac_emp_total) %>%
  mutate(agri_emp_total = sum(agri_emp)) %>%
  mutate(agri_sh_total = agri_emp/agri_emp_total) %>%
  filter(year %in% c(1872, 1890, 1920, 1940, 1950))


# Calculate growth rates - 1920
mun_data_1920 <- filter(mun_data, year %in% c(1872,1920)) %>% arrange(mun_code, year) %>%
  group_by(mun_code) %>%
  mutate(manufac_ppch_1920 = manufac_emp_share - lag(manufac_emp_share)) %>%
  mutate(manufac_perctch_1920 = 100*(manufac_emp - lag(manufac_emp))/lag(manufac_emp)) %>%
  mutate(agri_ppch_1920 = agri_emp_share - lag(agri_emp_share)) %>%
  mutate(service_ppch_1920 = service_emp_share - lag(service_emp_share)) %>%
  mutate(total_pop_perctch_1920 = 100*(total_pop - lag(total_pop))/lag(total_pop)) %>%
  mutate(foreign_ppch_1920 = foreign_pop_share - lag(foreign_pop_share)) %>%
  ungroup()

mun_data_1920 <- full_join(mun_shape, mun_data_1920)

manufac_ppch_1920 <- tm_shape(mun_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, 0, 0.1, 0.3, 0.5),
          title = "Change in Manufacturing Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(manufac_ppch_1920)
tmap_save(manufac_ppch_1920, "../output/manufac_ppch_1920.png")



agri_ppch_1920 <- tm_shape(mun_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, -0.25, 0, 0.1, 0.3, 0.6),
          title = "Change in Agricultural Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(agri_ppch_1920)
tmap_save(agri_ppch_1920, "../output/agri_ppch_1920.png")



service_ppch_1920 <- tm_shape(mun_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "service_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, -0.25, 0, 0.05, 0.1, 0.5),
          title = "Change in Services Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(service_ppch_1920)
tmap_save(service_ppch_1920, "../output/service_ppch_1920.png")






foreign_ppch_1920 <- tm_shape(mun_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "foreign_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, -0.25, 0, 0.1, 0.2, 0.3),
          title = "Change in Foreign Population Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(foreign_ppch_1920)
tmap_save(foreign_ppch_1920, "../output/foreign_ppch_1920.png")






###########  1950 ###########
mun_data_1950 <- filter(mun_data, year %in% c(1872,1950)) %>% arrange(mun_code, year) %>%
  group_by(mun_code) %>%
  mutate(manufac_ppch_1950 = manufac_emp_share - lag(manufac_emp_share)) %>%
  mutate(manufac_perctch_1950 = 100*(manufac_emp - lag(manufac_emp))/lag(manufac_emp)) %>%
  mutate(agri_ppch_1950 = agri_emp_share - lag(agri_emp_share)) %>%
  mutate(service_ppch_1950 = service_emp_share - lag(service_emp_share)) %>%
  mutate(total_pop_perctch_1950 = 100*(total_pop - lag(total_pop))/lag(total_pop)) %>%
  mutate(foreign_ppch_1950 = foreign_pop_share - lag(foreign_pop_share)) %>%
  ungroup()

mun_data_1950 <- full_join(mun_shape, mun_data_1950)

manufac_ppch_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, 0, 0.1, 0.2, 0.6),
          title = "Change in Manufacturing Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(manufac_ppch_1950)
tmap_save(manufac_ppch_1950, "../output/manufac_ppch_1950.png")


agri_ppch_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.8, -0.4, 0, 0.2, 0.4, 0.8),
          title = "Change in Agricultural Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(agri_ppch_1950)
tmap_save(agri_ppch_1950, "../output/agri_ppch_1950.png")



service_ppch_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "service_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.8, -0.4, 0, 0.2, 0.4, 0.8),
          title = "Change in Services Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(service_ppch_1950)
tmap_save(service_ppch_1950, "../output/service_ppch_1950.png")




foreign_ppch_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "foreign_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, -0.25, 0, 0.02, 0.05, 0.15),
          title = "Change in Foreign Population Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(foreign_ppch_1950)
tmap_save(foreign_ppch_1950, "../output/foreign_ppch_1950.png")

mun_data_1950 %<>% filter(is.infinite(total_pop_perctch_1950) == FALSE)

total_pop_perctch_1950 <- tm_shape(mun_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "total_pop_perctch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-75, 0, 1000, 5000, 10000, 20000),
          title = "Total Population Growth \n 1872-1950 (%)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(total_pop_perctch_1950)
tmap_save(total_pop_perctch_1950, "../output/total_pop_perctch_1950.png")




### State Level ###
state_data <- read_dta("../../data/output/panel_state_1872_1950.dta")
state_1872 <- st_read("../../data/output/shapefiles/state_1872/04-limite de província 1872.shp") %>%
  filter(nome != "Município neutro") %>%
  mutate(state_code = case_when(nome == "Amazonas" ~13,
                                  nome == "Piauhy" ~22,
                                  nome == "Ceará" ~23,
                                  nome == "Rio Grande do Norte" ~24,
                                  nome == "Pernambuco" ~26,
                                  nome == "Alagôas" ~27,
                                  nome == "Sergipe" ~28,
                                  nome == "Minas Geraes" ~31,
                                  nome == "Paraná" ~41,
                                  nome == "Rio Grande do Sul" ~43,
                                  nome == "Goyaz" ~52,
                                  nome == "Pará" ~15,
                                  nome == "Maranhão" ~21,
                                  nome == "Parahyba" ~25,
                                  nome == "Bahia" ~29,
                                  nome == "Município neutro" ~33,
                                  nome == "Espirito Santo" ~32,
                                  nome == "Rio de Janeiro" ~33,
                                  nome == "São Paulo" ~35,
                                  nome == "Santa Catharina" ~42,
                                  nome == "Matto Grosso" ~51,))


sp_border <- state_1950 %>% filter(nome == "São Paulo")

state_data %<>% filter(year %in% c(1872, 1890, 1920, 1940, 1950))


  
# 1920 #
state_data_1920 <-  filter(state_data, year %in% c(1872,1920)) %>% 
  arrange(state_code, year) %>%
  group_by(state_code) %>%
  mutate(manufac_emp_share = manufac_emp/total_emp) %>%
  mutate(agri_emp_share = agri_emp/total_emp) %>%
  mutate(service_emp = total_emp - agri_emp - manufac_emp) %>%
  mutate(service_emp_share = service_emp/total_emp) %>%
  mutate(manufac_ppch_1920 = manufac_emp_share - lag(manufac_emp_share)) %>%
  mutate(manufac_perctch_1920 = 100*(manufac_emp - lag(manufac_emp))/lag(manufac_emp)) %>%
  mutate(agri_ppch_1920 = agri_emp_share - lag(agri_emp_share)) %>%
  mutate(service_ppch_1920 = service_emp_share - lag(service_emp_share)) %>%
  group_by(year) %>%
  mutate(manufac_emp_total = sum(manufac_emp)) %>%
  mutate(agri_emp_total = sum(agri_emp)) %>%
  ungroup() %>%
  mutate(manufac_sh_total = manufac_emp/manufac_emp_total) %>%
  mutate(agri_sh_total = agri_emp/agri_emp_total)

state_data_1920 <- full_join(state_1872, state_data_1920)

state_manufac_ppch_1920 <- tm_shape(state_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.03, 0, 0.025, 0.05, 0.2),
          title = "Change in Manufacturing Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#252525")) +
  tm_shape(state_1872) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(state_manufac_ppch_1920)
tmap_save(state_manufac_ppch_1920, "../output/state_manufac_ppch_1920.png")



### 1950 ###
state_data_1950 <-  filter(state_data, year %in% c(1872,1950)) %>%
  arrange(state_code, year) %>%
  group_by(state_code) %>%
  mutate(manufac_emp_share = manufac_emp/total_emp) %>%
  mutate(agri_emp_share = agri_emp/total_emp) %>%
  mutate(service_emp = total_emp - agri_emp - manufac_emp) %>%
  mutate(service_emp_share = service_emp/total_emp) %>%
  mutate(manufac_ppch_1950 = manufac_emp_share - lag(manufac_emp_share)) %>%
  mutate(manufac_perctch_1950 = 100*(manufac_emp - lag(manufac_emp))/lag(manufac_emp)) %>%
  mutate(agri_ppch_1950 = agri_emp_share - lag(agri_emp_share)) %>%
  mutate(service_ppch_1950 = service_emp_share - lag(service_emp_share)) %>%
  mutate(total_pop_perctch_1950 = 100*(total_pop - lag(total_pop))/lag(total_pop)) %>%
  mutate(foreign_pop = total_pop - total_br) %>%
  mutate(foreign_pop_share = foreign_pop/total_pop) %>%
  mutate(foreign_ppch_1950 = foreign_pop_share - lag(foreign_pop_share)) %>%
  ungroup() %>%
  group_by(year) %>%
  mutate(manufac_emp_total = sum(manufac_emp)) %>%
  mutate(agri_emp_total = sum(agri_emp)) %>%
  ungroup() %>%
  group_by(state_code) %>%
  arrange(state_code, year) %>%
  mutate(manufac_sh_total = manufac_emp/manufac_emp_total) %>%
  mutate(agri_sh_total = agri_emp/agri_emp_total) %>%
  mutate(manufac_sh_total_ch = manufac_sh_total - lag(manufac_sh_total)) %>%
  mutate(agri_sh_total_ch = agri_sh_total - lag(agri_sh_total)) %>%
  ungroup()


state_data_1950 <- full_join(state_1872, state_data_1950)


state_data_1950 %<>% filter(year == 1950)
state_manufac_sh_total_1950 <- tm_shape(state_data_1950) +
  tm_borders(col = "darkgrey",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_sh_total",
          tm_scale_intervals("fixed",
                          breaks = c(0, 0.05, 0.1, 0.2, 0.35),
                          label.na = "No Data",
                          midpoint = NA,
                          values = c("#F7F7F7", "#CCCCCC", "#969696", "#252525")),
          fill.legend = tm_legend("Contribution to Total Manufacturing Share (pp.)")) +
  tm_shape(state_1872) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom")) 


print(state_manufac_sh_total_1950)
tmap_save(state_manufac_sh_total_1950, "../output/state_manufac_sh_total_1950.png")



state_manufac_ppch_1950 <- tm_shape(state_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.07, 0, 0.05, 0.1, 0.2),
          title = "Change in Manufacturing Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#252525")) +
  tm_shape(state_1872) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(state_manufac_ppch_1950)
tmap_save(state_manufac_ppch_1950, "../output/state_manufac_ppch_1950.png")


state_agri_ppch_1950 <- tm_shape(state_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.35, -0.1, 0, 0.05, 0.1, 0.2),
          title = "Change in Agricultural Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1872) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(state_agri_ppch_1950)
tmap_save(state_agri_ppch_1950, "../output/state_agri_ppch_1950.png")


state_service_ppch_1950 <- tm_shape(state_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "service_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.2, 0, 0.05, 0.1, 0.2),
          title = "Change in Services Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#252525")) +
  tm_shape(state_1872) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(state_service_ppch_1950)
tmap_save(state_service_ppch_1950, "../output/state_service_ppch_1950.png")




state_manufac_totch_1950 <- tm_shape(state_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.15, -0.05, 0, 0.05, 0.1, 0.25),
          title = "Change in Total Contribution to \n Manufac. Emp. Share 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1872) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(state_manufac_totch_1950)
tmap_save(state_manufac_totch_1950, "../output/state_manufac_totch_1950.png")








############################ 3 - Mesoregion Level ##############################
mun_data <- read_dta("../../data/output/panel_mun_1872_1950.dta")
state_1950 <- st_read("../../data/output/shapefiles/state_1950/04-limite estadual 1950.shp") %>%
  filter(nome != "Território do Acre")
sp_border <- state_1950 %>% filter(nome == "São Paulo")

meso_shp <- st_read("../../data/output/meso_consistent_1872.shp") %>%
  rename(meso_code_1872 = m__1872) %>%
  mutate(meso_code_1872 = as.numeric(meso_code_1872)) %>%
  st_simplify(dTolerance = 1000) %>%
  filter(meso_code_1872 != 1201)

mun_data %<>% dplyr::select(year, mun_code, mun_name, state_code, state_name,
                            meso_code_1872, total_pop, total_br, total_foreign,
                            manufac_emp, agri_emp, service_emp,total_emp)

mun_data_meso <- filter(mun_data, year %in% c(1872, 1890, 1920, 1940, 1950)) %>%
  group_by(year, meso_code_1872) %>%
  summarise(across(total_pop:total_emp, sum, na.rm = TRUE)) %>%
  ungroup()

### 1920 ###
meso_data_1920 <- filter(mun_data_meso, year %in% c(1872, 1920))

meso_data_1920 <- full_join(meso_shp, meso_data_1920, by = "meso_code_1872") %>%
  mutate(agri_emp_share = agri_emp/total_emp) %>%
  mutate(manufac_emp_share = manufac_emp/total_emp) %>%
  mutate(service_emp_share = service_emp/total_emp) %>%
  mutate(foreign_pop_share = total_foreign/total_pop) %>%
  mutate(log_pop = log(total_pop)) %>%
  group_by(year) %>%
  mutate(manufac_emp_total = sum(manufac_emp)) %>%
  mutate(agri_emp_total = sum(agri_emp)) %>%
  mutate(total_pop_country = sum(total_pop)) %>%
  mutate(total_foreign_country = sum(total_foreign)) %>%
  ungroup() %>%
  mutate(manufac_sh_total = manufac_emp/manufac_emp_total) %>%
  mutate(agri_sh_total = agri_emp/agri_emp_total) %>%
  mutate(pop_sh_total = total_pop/total_pop_country) %>%
  mutate(foreign_sh_total = total_foreign/total_foreign_country) %>%
  arrange(meso_code_1872, year) %>%
  group_by(meso_code_1872) %>%
  mutate(manufac_ppch_1920 = manufac_emp_share - lag(manufac_emp_share)) %>%
  mutate(manufac_perctch_1920 = 100*(manufac_emp - lag(manufac_emp))/lag(manufac_emp)) %>%
  mutate(agri_ppch_1920 = agri_emp_share - lag(agri_emp_share)) %>%
  mutate(service_ppch_1920 = service_emp_share - lag(service_emp_share)) %>%
  mutate(total_pop_perctch_1920 = 100*(total_pop - lag(total_pop))/lag(total_pop)) %>%
  mutate(foreign_ppch_1920 = foreign_pop_share - lag(foreign_pop_share)) %>%
  mutate(logpop_ch_1920 = log_pop - lag(log_pop)) %>%
  mutate(manufac_sh_total_ch = manufac_sh_total - lag(manufac_sh_total)) %>%
  mutate(agri_sh_total_ch = agri_sh_total - lag(agri_sh_total)) %>%
  mutate(pop_sh_total_ch = pop_sh_total - lag(pop_sh_total)) %>%
  mutate(foreign_sh_total_ch = foreign_sh_total - lag(foreign_sh_total)) %>%
  ungroup()

meso_agri_ppch_1920 <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.5, -0.25, 0, 0.2, 0.25, 0.5),
          title = "Change in Agricultural Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_agri_ppch_1920)
tmap_save(meso_agri_ppch_1920, "../output/meso_agri_ppch_1920.png")


meso_service_ppch_1920 <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "service_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.4, -0.2, 0, 0.05, 0.15),
          title = "Change in Services Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_service_ppch_1920)
tmap_save(meso_service_ppch_1920, "../output/meso_service_ppch_1920.png")




meso_manufac_ppch_1920 <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.2, -0.1, 0, 0.1, 0.2, 0.4),
          title = "Change in Manufacturing Employment Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufac_ppch_1920)
tmap_save(meso_manufac_ppch_1920, "../output/meso_manufac_ppch_1920.png")

meso_foreign_ppch_1920 <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "foreign_ppch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.3, -0.2, -0.1, 0, 0.15, 0.3),
          title = "Change in Foreign Population Share \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_foreign_ppch_1920)
tmap_save(meso_foreign_ppch_1920, "../output/meso_foreign_ppch_1920.png")



meso_logpop_ch_1920 <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "logpop_ch_1920",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.5, 1, 1.5, 2, 2.75),
          title = "Change in Log Populatuion \n 1872-1920 (log points)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_logpop_ch_1920)
tmap_save(meso_logpop_ch_1920, "../output/meso_logpop_ch_1920.png")



meso_totpop_ch_1920  <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "pop_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.02, -0.01, 0, 0.01, 0.02),
          title = "Change in Contribution to Total Population \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_totpop_ch_1920)
tmap_save(meso_totpop_ch_1920, "../output/meso_totpop_ch_1920.png")


meso_totforeign_ch_1920  <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "foreign_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.15, -0.05, 0, 0.05, 0.1, 0.15),
          title = "Change in Contribution to Foreign Population \n 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_totforeign_ch_1920)
tmap_save(meso_totforeign_ch_1920, "../output/meso_totforeign_ch_1920.png")



meso_manufactot_ch_1920  <- tm_shape(meso_data_1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.03, -0.01, 0, 0.05, 0.1),
          title = "Change in Contribution to Total \n Manufacturing Employment 1872-1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufactot_ch_1920)
tmap_save(meso_manufactot_ch_1920, "../output/meso_manufactot_ch_1920.png")



## Cross-Sectional
meso_data_c1872 <- filter(meso_data_1920, year == 1872)
meso_data_c1920 <- filter(meso_data_1920, year == 1920)


meso_manufac_sh_total_1872  <- tm_shape(meso_data_c1872) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_sh_total",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.01, 0.05, 0.1, 0.15),
          title = "Contribution to Manufacturing Employment \n 1872 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufac_sh_total_1872)
tmap_save(meso_manufac_sh_total_1872, "../output/meso_manufac_sh_total_1872.png")



meso_manufac_sh_total_1920  <- tm_shape(meso_data_c1920) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_sh_total",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.01, 0.05, 0.1, 0.2),
          title = "Contribution to Manufacturing Employment \n 1920 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufac_sh_total_1920)
tmap_save(meso_manufac_sh_total_1920, "../output/meso_manufac_sh_total_1920.png")




### 1950 ###
meso_data_1950 <- filter(mun_data_meso, year %in% c(1872, 1950))


meso_data_1950 <- full_join(meso_shp, meso_data_1950, by = "meso_code_1872") %>%
  mutate(agri_emp_share = agri_emp/total_emp) %>%
  mutate(manufac_emp_share = manufac_emp/total_emp) %>%
  mutate(service_emp_share = service_emp/total_emp) %>%
  mutate(foreign_pop_share = total_foreign/total_pop) %>%
  mutate(log_pop = log(total_pop)) %>%
  group_by(year) %>%
  mutate(manufac_emp_total = sum(manufac_emp)) %>%
  mutate(agri_emp_total = sum(agri_emp)) %>%
  mutate(total_pop_country = sum(total_pop)) %>%
  mutate(total_foreign_country = sum(total_foreign)) %>%
  ungroup() %>%
  mutate(manufac_sh_total = manufac_emp/manufac_emp_total) %>%
  mutate(agri_sh_total = agri_emp/agri_emp_total) %>%
  mutate(pop_sh_total = total_pop/total_pop_country) %>%
  mutate(foreign_sh_total = total_foreign/total_foreign_country) %>%
  arrange(meso_code_1872, year) %>%
  group_by(meso_code_1872) %>%
  mutate(manufac_ppch_1950 = manufac_emp_share - lag(manufac_emp_share)) %>%
  mutate(manufac_perctch_1950 = 100*(manufac_emp - lag(manufac_emp))/lag(manufac_emp)) %>%
  mutate(agri_ppch_1950 = agri_emp_share - lag(agri_emp_share)) %>%
  mutate(service_ppch_1950 = service_emp_share - lag(service_emp_share)) %>%
  mutate(total_pop_perctch_1950 = 100*(total_pop - lag(total_pop))/lag(total_pop)) %>%
  mutate(foreign_ppch_1950 = foreign_pop_share - lag(foreign_pop_share)) %>%
  mutate(logpop_ch_1950 = log_pop - lag(log_pop)) %>%
  mutate(manufac_sh_total_ch = manufac_sh_total - lag(manufac_sh_total)) %>%
  mutate(agri_sh_total_ch = agri_sh_total - lag(agri_sh_total)) %>%
  mutate(pop_sh_total_ch = pop_sh_total - lag(pop_sh_total)) %>%
  mutate(foreign_sh_total_ch = foreign_sh_total - lag(foreign_sh_total)) %>%
  ungroup()

meso_manufac_sh_1950  <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_emp_share",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.1, 0.2, 0.3, 0.6),
          title = "Manufacturing Employment Share in 1950",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufac_sh_1950)
tmap_save(meso_manufac_sh_1950, "../output/meso_manufac_sh_1950.png")





meso_agri_ppch_1950 <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "agri_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.8, -0.4, 0, 0.2, 0.4, 0.8),
          title = "Change in Agricultural Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_agri_ppch_1950)
tmap_save(meso_agri_ppch_1950, "../output/meso_agri_ppch_1950.png")


meso_service_ppch_1950 <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "service_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.4, -0.2, 0, 0.2, 0.3, 0.3),
          title = "Change in Services Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_service_ppch_1950)
tmap_save(meso_service_ppch_1950, "../output/meso_service_ppch_1950.png")




meso_manufac_ppch_1950 <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.2, -0.1, 0, 0.1, 0.2, 0.4),
          title = "Change in Manufacturing Employment Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufac_ppch_1950)
tmap_save(meso_manufac_ppch_1950, "../output/meso_manufac_ppch_1950.png")

meso_foreign_ppch_1950 <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "foreign_ppch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.3, -0.2, -0.1, 0, 0.1, 0.2),
          title = "Change in Foreign Population Share \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_foreign_ppch_1950)
tmap_save(meso_foreign_ppch_1950, "../output/meso_foreign_ppch_1950.png")





meso_logpop_ch_1950 <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "logpop_ch_1950",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 1, 2, 3, 4.5),
          title = "Change in Log Population 1872-1950 \n (log points)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_logpop_ch_1950)
tmap_save(meso_logpop_ch_1950, "../output/meso_logpop_ch_1950.png")



meso_totpop_ch_1950  <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "pop_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.03, -0.015, 0, 0.01, 0.05),
          title = "Change in Contribution to Total Population \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_totpop_ch_1950)
tmap_save(meso_totpop_ch_1950, "../output/meso_totpop_ch_1950.png")


meso_totforeign_ch_1950  <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "foreign_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.10, -0.05, 0, 0.05, 0.15, 0.35),
          title = "Change in Contribution to Foreign Population \n 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_totforeign_ch_1950)
tmap_save(meso_totforeign_ch_1950, "../output/meso_totforeign_ch_1950.png")


meso_manufactot_ch_1950  <- tm_shape(meso_data_1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_sh_total_ch",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(-0.04, -0.02, 0, 0.05, 0.1, 0.2),
          title = "Change in Contribution to Total \n Manufacturing Employment 1872-1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#969696", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufactot_ch_1950)
tmap_save(meso_manufactot_ch_1950, "../output/meso_manufactot_ch_1950.png")



# Cross Section #
meso_data_c1950 <- filter(meso_data_1950, year == 1950)


meso_manufac_sh_total_1950  <- tm_shape(meso_data_c1950) +
  tm_borders(col = "darkgrey", alpha = 0.5, lwd = 1.5) +
  tm_fill(col = "manufac_sh_total",  midpoint = NA,
          showNA = FALSE, style = "fixed",
          breaks = c(0, 0.01, 0.05, 0.1, 0.2),
          title = "Contribution to Manufacturing Employment \n 1950 (pp.)",
          pal = c("#F7F7F7", "#CCCCCC", "#636363", "#252525")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_shape(sp_border) + 
  tm_borders(col = "red", lwd = 2) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) +
  tm_compass(position = c("right", "bottom")) +
  tm_scale_bar(position = c("right", "bottom")) 

print(meso_manufac_sh_total_1950)
tmap_save(meso_manufac_sh_total_1950, "../output/meso_manufac_sh_total_1950.png")

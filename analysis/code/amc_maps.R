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

state_1950 <- group_by(amc_1950, state_code) %>% 
  summarise(geometry = st_union(geometry)) %>%
  ungroup()

amc_panel <- read_dta("../../data/output/amc_panel.dta")

amc_shp <- full_join(amc_1950, amc_panel, by = "amc")

# Variables
amc_shp %<>% mutate(agri_share = agri_emp/emp_total,
                    manufac_share = manufac_emp/emp_total,
                    service_share = service_emp/emp_total,
                    manufac_va_share = gdp_manufac/gdp_tot,
                    agri_va_share = gdp_agri/gdp_tot,
                    serv_va_share = gdp_serv/gdp_tot)

rwb_2 <-  c("#FF0000", "#BF1900", "#7F3200", "#3F4B00", "#006400")


# 1950 Manufac Shares #
amc_shp_1950 <- filter(amc_shp, year == 1950)
manufac_sh_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.05, 0.25, 0.5, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Manufacturing Employment\nShare 1950 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

manufac_sh_1950
tmap_save(manufac_sh_1950, "../output/manufac_sh_1950.png")

# 1970 Manufac Shares #
amc_shp_1970 <- filter(amc_shp, year == 1970)
manufac_sh_1970 <- tm_shape(amc_shp_1970) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.05, 0.25, 0.5, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Manufacturing Employment\nShare 1970 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

manufac_sh_1970
tmap_save(manufac_sh_1970, "../output/manufac_sh_1970.png")

# 1990 Manufac Shares #
amc_shp_1990 <- filter(amc_shp, year == 1990)
manufac_sh_1990 <- tm_shape(amc_shp_1990) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.05, 0.25, 0.5, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Manufacturing Employment\nShare 1990 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

manufac_sh_1990
tmap_save(manufac_sh_1990, "../output/manufac_sh_1990.png")








# 1950 Agri Shares #
amc_shp_1950 <- filter(amc_shp, year == 1950)
agri_sh_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "agri_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.15, 0.3, 0.5, 0.75, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Agriculture Employment\nShare 1950 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

agri_sh_1950
tmap_save(agri_sh_1950, "../output/agri_sh_1950.png")

# 1970 Agri Shares #
amc_shp_1970 <- filter(amc_shp, year == 1970)
agri_sh_1970 <- tm_shape(amc_shp_1970) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "agri_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.15, 0.3, 0.5, 0.75, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Agriculture Employment\nShare 1970 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

agri_sh_1970
tmap_save(agri_sh_1970, "../output/agri_sh_1970.png")

# 1990 Agri Shares #
amc_shp_1990 <- filter(amc_shp, year == 1990)
agri_sh_1990 <- tm_shape(amc_shp_1990) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "agri_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.15, 0.3, 0.5, 0.75, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Agriculture Employment\nShare 1990 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

agri_sh_1990
tmap_save(agri_sh_1990, "../output/agri_sh_1990.png")





# 1950 Serv Shares #
amc_shp_1950 <- filter(amc_shp, year == 1950)
serv_sh_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "service_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.15, 0.3, 0.5, 0.75, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Service Employment\nShare 1950 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

serv_sh_1950
tmap_save(serv_sh_1950, "../output/serv_sh_1950.png")

# 1970 Serv Shares #
amc_shp_1970 <- filter(amc_shp, year == 1970)
serv_sh_1970 <- tm_shape(amc_shp_1970) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "service_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.15, 0.3, 0.5, 0.75, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Service Employment\nShare 1970 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

serv_sh_1970
tmap_save(serv_sh_1970, "../output/serv_sh_1970.png")

# 1990 Serv Shares #
amc_shp_1990 <- filter(amc_shp, year == 1990)
serv_sh_1990 <- tm_shape(amc_shp_1990) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "service_share",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.15, 0.3, 0.5, 0.75, 1),
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Service Employment\nShare 1990 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

serv_sh_1990
tmap_save(serv_sh_1990, "../output/serv_sh_1990.png")




# 1950 Value Prod #
amc_shp_1950 <- filter(amc_shp, year == 1950) %>% mutate(log_value_prod = log(value_prod))
value_prod_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "log_value_prod",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "YlOrRd"),
          fill.legend = tm_legend("Log Production Value in 1950 (Thousands of Cruzeiros)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

value_prod_1950
tmap_save(value_prod_1950, "../output/value_prod_1950.png")





# 1960 Value Prod #
amc_shp_1960 <- filter(amc_shp, year == 1960) %>% mutate(log_value_prod = log(value_prod))
value_prod_1960 <- tm_shape(amc_shp_1960) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "log_value_prod",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "YlOrRd"),
          fill.legend = tm_legend("Log Production Value in 1960 (Thousands of Cruzeiros)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

value_prod_1960
tmap_save(value_prod_1960, "../output/value_prod_1960.png")





# 1950 Number of Firms #
amc_shp_1950 <- filter(amc_shp, year == 1950) %>% mutate(log_value_prod = log(value_prod))
num_firm_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "num_firm",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "YlOrRd"),
          fill.legend = tm_legend("Number of Manufacturing Firms in 1950")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

num_firm_1950
tmap_save(num_firm_1950, "../output/num_firm_1950.png")




# 1960 Number of Firms #
amc_shp_1960 <- filter(amc_shp, year == 1960) %>% mutate(log_value_prod = log(value_prod))
num_firm_1960 <- tm_shape(amc_shp_1960) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "num_firm",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "YlOrRd"),
          fill.legend = tm_legend("Number of Manufacturing Firms in 1960")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

num_firm_1960
tmap_save(num_firm_1960, "../output/num_firm_1960.png")

# 1950 Manufac VA Shares #
amc_shp_1950 <- filter(amc_shp, year == 1950)
manufac_va_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_va_share",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Manufacturing VA\nShare 1950 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

manufac_va_1950
tmap_save(manufac_va_1950, "../output/manufac_va_1950.png")

# 1970 Manufac VA Shares #
amc_shp_1970 <- filter(amc_shp, year == 1970)
manufac_va_1970 <- tm_shape(amc_shp_1970) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_va_share",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Manufacturing VA\nShare 1970 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

manufac_va_1970
tmap_save(manufac_va_1970, "../output/manufac_va_1970.png")

# 1995 Manufac VA Shares #
amc_shp_1995 <- filter(amc_shp, year == 1995)
manufac_va_1995 <- tm_shape(amc_shp_1995) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "manufac_va_share",
          tm_scale_intervals(style = "quantile",
                             label.na = "No Data",
                             midpoint = NA,
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend("Manufacturing VA\nShare 1995 (pp.)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

manufac_va_1995
tmap_save(manufac_va_1995, "../output/manufac_va_1995.png")

















# Teste
amc_shp_1950 <- filter(amc_shp, year == 1950) %>%
  mutate(capital = case_when(capital_app < 5000 ~ 0,
                             is.na(capital_app) == TRUE ~ 0,
                             .default = capital_app)) %>%
  mutate(capital = capital/1000, capital_pw = (capital*1000/emp_total))


capital_1950 <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "capital",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 1, 100, 1000, 10000),
                             midpoint = NA,
                             labels = c("0", "1 to 100", "100 to 1000", "1000 to 10000"),
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend(title = "Value of SUMOC 113 Licenses\n(Thousand US$)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

capital_1950
tmap_save(capital_1950, "../output/capital_1950.png")



capital_1950_pw <- tm_shape(amc_shp_1950) +
  tm_borders(col = "black",fill_alpha = 0.5, lwd = 1.5) +
  tm_fill(fill = "capital_pw",
          tm_scale_intervals(style = "fixed",
                             label.na = "No Data",
                             breaks = c(0, 0.01, 5, 50, 200),
                             midpoint = NA,
                             labels = c("0", "0.01 to 5", "5 to 50", "50 to 200"),
                             values = "brewer.yl_or_rd"),
          fill.legend = tm_legend(title = "Value of SUMOC 113 Licenses\n(US$ per Worker)")) +
  tm_shape(state_1950) + 
  tm_borders(col = "black", lwd = 1) +
  tm_layout(legend.position = c("left", "bottom"),
            legend.text.size = 0.8,
            frame = FALSE) + 
  tm_compass(position = c("bottom", "right")) +
  tm_scalebar(width = 20, position = c("right", "bottom"))

capital_1950_pw
tmap_save(capital_1950_pp, "../output/capital_1950_pw.png")

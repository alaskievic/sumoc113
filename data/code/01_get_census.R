library(censobr)
library(haven)
library(tidyverse)

# 1960 #
data_dictionary(year = 1960, dataset = "population", showProgress = TRUE, cache = TRUE)
pop_1960 <- read_population(year = 1960,
                columns = c('uf', 'V223b', 'V202', 'V204', 'V204b',
                            'V219', 'V221', 'censobr_source', 'code_muni_1960'), 
                as_data_frame = TRUE)
write_dta(pop_1960, "censo_1960_ocup.dta")


# 1970 #
data_dictionary(year = 1970, dataset = "population", showProgress = TRUE, cache = TRUE)
pop_1970 <- read_population(year = 1970,
                            columns = c('V002', 'V054', 'V023', 'V026', 'V027',
                                        'V044', 'V045', 'V041', 'V035', 'code_muni'), 
                            as_data_frame = TRUE)
write_dta(pop_1970, "censo_1970_ocup.dta")


# 1980 #
data_dictionary(year = 1980, dataset = "population", showProgress = TRUE, cache = TRUE)
pop_1980 <- read_population(year = 1980, columns = c('code_muni', 'V519', 'V530', 'V532', 'V607',
                            'V501', 'V604'),
                            as_data_frame = TRUE)
write_dta(pop_1980, "censo_1980_ocup.dta")



# 1990 #
data_dictionary(year = 1991, dataset = "population", showProgress = TRUE, cache = TRUE)
pop_1990 <- read_population(year = 1991, columns = c('code_muni', 'V0301', 'V3072',
                                                     'V0346', 'V0347', 'V0356', 
                                                     'V7301'),
                            as_data_frame = TRUE)
write_dta(pop_1990, "censo_1990_ocup.dta")



# 2000 #
data_dictionary(year = 2000, dataset = "population", showProgress = TRUE, cache = TRUE)
pop_2000 <- read_population(year = 2000, columns = c('code_muni', 'V0102', 'V0103',
                                                     'V0401', 'V4752', 'V0428', 'P001',
                                                     'V4300', 'V4452', 'V4462', 'V4513'),
                            as_data_frame = TRUE)
write_dta(pop_2000, "../raw/census_demog_1950_2010/original/censo_2000_ocup.dta")

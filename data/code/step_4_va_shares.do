clear

import excel "../raw/ipeadata/gdp_agriculture.xls", first clear

rename(D-L N S X AC AH) (agri1920 agri1940 agri1950 agri1960 agri1970 agri1975 ///
						agri1980 agri1985 agri1995 agri2000 agri2005 ///
						agri2010 agri2015 agri2020)

rename (Sigla Codigo Município) (state code2010 mun_name)				
keep state code2010 mun_nam agri*				

reshape long agri, i(code2010) j(year)

rename agri gdp_agri
keep if year >= 1950
destring code2010, force replace

tempfile agri_gdp
save "`agri_gdp'"


* Manufacturing
import excel "../raw/ipeadata/gdp_manufacturing.xls", first clear

rename(D-L N S X AC AH) (manufac1920 manufac1940 manufac1950 manufac1960 manufac1970 manufac1975 ///
						manufac1980 manufac1985 manufac1995 manufac2000 manufac2005 ///
						manufac2010 manufac2015 manufac2020)

rename (Sigla Codigo Município) (state code2010 mun_name)				
keep state code2010 mun_nam manufac*				

reshape long manufac, i(code2010) j(year)

rename manufac gdp_manufac
keep if year >= 1950
destring code2010, force replace

tempfile manufac_gdp
save "`manufac_gdp'"


* Services
import excel "../../data/raw/ipeadata/gdp_services.xls", clear first

rename(D-L N S X AC AH) (serv1920 serv1940 serv1950 serv1960 serv1970 serv1975 ///
						serv1980 serv1985 serv1995 serv2000 serv2005 ///
						serv2010 serv2015 serv2020)

rename (Sigla Codigo Município) (state code2010 mun_name)				
keep state code2010 mun_nam serv*				

reshape long serv, i(code2010) j(year)

rename serv gdp_serv
keep if year >= 1950
destring code2010, force replace

tempfile serv_gdp
save "`serv_gdp'"


* Public Services
import excel "../../data/raw/ipeadata/gdp_services_public.xls", clear first

rename(D E F G H I J L Q V AA AF) (serv_pub1920 serv_pub1940 serv_pub1970 serv_pub1975 ///
								   serv_pub1980 serv_pub1985 serv_pub1995 serv_pub2000 serv_pub2005 ///
								   serv_pub2010 serv_pub2015 serv_pub2020)

rename (Sigla Codigo Município) (state code2010 mun_name)				
keep state code2010 mun_nam serv_pub*				

reshape long serv_pub, i(code2010) j(year)

rename serv_pub gdp_serv_pub
keep if year >= 1950
destring code2010, force replace

merge 1:1 year code2010 using "`agri_gdp'", nogen
merge 1:1 year code2010 using "`manufac_gdp'", nogen
merge 1:1 year code2010 using "`serv_gdp'", nogen

foreach v of varlist gdp_agri gdp_manufac gdp_serv gdp_serv_pub{
	replace `v' = 0 if `v' == .
	replace `v' = (-1) * `v' if `v' < 0
}

replace gdp_serv = gdp_serv + gdp_serv_pub
drop gdp_serv_pub

gen gdp_tot = gdp_agri + gdp_manufac + gdp_serv
gen gdp_agri_share 		= gdp_agri/gdp_tot
gen gdp_manufac_share 	= gdp_manufac/gdp_tot
gen gdp_serv_share 		= gdp_serv/gdp_tot

save "../output/mun_va.dta", replace

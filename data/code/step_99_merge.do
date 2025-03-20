

* 1950 emp share *
use ".././output/ocup_mun_total_1950.dta", clear
* Without domestic *
rename agri_tot agri_emp

gen manufac_emp 	= extract_tot + transf_tot 
gen service_emp 	= com_merc_tot + com_est_tot + serv_tot + transp_tot + liberal_tot + social_tot + pub_tot + def_tot
gen emp_total 		= agri_emp + manufac_emp + service_emp
gen year = 1950
keep code2010 year agri_emp manufac_emp service_emp emp_total

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) agri_emp manufac_emp service_emp emp_total, by(amc year)
gsort amc

tempfile amc_1950
save "`amc_1950'"

* 1960 emp share *
use ".././output/censo_emp_shares_1960.dta", clear
keep code2010 year agri_emp manufac_emp service_emp other_emp emp_total

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) agri_emp manufac_emp service_emp other_emp emp_total, by(amc year)
gsort amc

tempfile amc_1960
save "`amc_1960'"


* 1970 emp share *
use ".././output/censo_emp_shares_1970.dta", clear
keep code2010 year agri_emp manufac_emp service_emp other_emp emp_total

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) agri_emp manufac_emp service_emp other_emp emp_total, by(amc year)
gsort amc

tempfile amc_1970
save "`amc_1970'"


* 1980 emp share *
use ".././output/censo_emp_shares_1980.dta", clear
keep code2010 year agri_emp manufac_emp service_emp other_emp emp_total

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) agri_emp manufac_emp service_emp other_emp emp_total, by(amc year)
gsort amc

tempfile amc_1980
save "`amc_1980'"



* 1990 emp share *
use ".././output/censo_emp_shares_1990.dta", clear
keep code2010 year agri_emp manufac_emp service_emp other_emp emp_total

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) agri_emp manufac_emp service_emp other_emp emp_total, by(amc year)
gsort amc


append using "`amc_1950'"
append using "`amc_1960'"
append using "`amc_1970'"
append using "`amc_1980'"
gsort amc year


tempfile amc_emp
save "`amc_emp'"




* Population *
use ".././output/pop_mun.dta", clear

keep if year <= 2000

merge m:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) poptot popurb poprur, by(amc year)

drop if amc == .
gsort amc year

tempfile amc_pop
save "`amc_pop'"

* Value Added *
use ".././output/mun_va.dta", clear
keep code2010-gdp_tot

keep if year <= 2000

merge m:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) gdp_agri gdp_manufac gdp_serv gdp_tot, by(amc year)
gsort amc year

merge 1:1 amc year using "`amc_pop'", nogen
merge 1:1 amc year using "`amc_emp'", nogen

gsort amc year


save "../output/amc_panel.dta", replace

clear all

* amc state codes *
use "../output/_Crosswalk_final_1950_2000.dta", clear

duplicates drop amc, force
keep uf_amc final_name amc

tempfile amc_codes
save "`amc_codes'"

* codmicro state codes *
use "../output/amc_codes_1950.dta", clear

duplicates drop codmicro, force
keep micro_name codmicro state_code

tempfile micro_codes
save "`micro_codes'"

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

tempfile amc_1990
save "`amc_1990'"

* 2000 emp share *
use ".././output/censo_emp_shares_2000.dta", clear
keep code2010 year agri_emp manufac_emp service_emp other_emp emp_total

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) agri_emp manufac_emp service_emp other_emp emp_total, by(amc year)
gsort amc

append using "`amc_1950'"
append using "`amc_1960'"
append using "`amc_1970'"
append using "`amc_1980'"
append using "`amc_1990'"
gsort amc year


tempfile amc_emp
save "`amc_emp'"



*** Manufac 1950 ***
use ".././raw/census_ind_1950_1985/manufac_mun_1950.dta", clear

keep code2010 num_firm capital_app num_work horsepower manufac_wages exp_input value_prod

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) num_firm capital_app num_work horsepower manufac_wages exp_input value_prod, by(amc)
gsort amc
gen year = 1950

foreach v of varlist num_firm capital_app num_work manufac_wages exp_input value_prod{
	replace `v' = . if `v' == 0
}

tempfile manufac_amc_1950
save "`manufac_amc_1950'"




*** Manufac 1960 ***
use ".././raw/census_ind_1950_1985/manufac_mun_1960.dta", clear

keep code2010 num_firm num_work hp wage_tot exp_tot exp_input prod_value

rename (hp wage_tot prod_value) (horsepower manufac_wages value_prod)

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) num_firm num_work horsepower manufac_wages exp_tot exp_input value_prod, by(amc)
gsort amc
gen year = 1960

foreach v of varlist num_firm num_work manufac_wages exp_tot exp_input value_prod{
	replace `v' = . if `v' == 0
}

append using "`manufac_amc_1950'"
gsort amc year

tempfile manufac_amc
save "`manufac_amc'"



* Population *
use ".././output/pop_mun.dta", clear

keep if year <= 2000

merge m:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) poptot popurb poprur, by(amc year)

drop if amc == .
gsort amc year

tempfile amc_pop
save "`amc_pop'"

* Foreign Pop 1940 *
use ".././output/foreign_mun_1940.dta", clear

keep code2010 foreign_tot br_tot

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) foreign_tot br_tot, by(amc)
gsort amc

gen year = 1940

tempfile foreign_1940
save "`foreign_1940'"


* Foreign Pop 1950 *
use ".././output/foreign_mun_1950.dta", clear

keep code2010 foreign_tot br_tot

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) foreign_tot br_tot, by(amc)
gsort amc

gen year = 1950

append using "`foreign_1940'"

tempfile foreign_pop
save "`foreign_pop'"

* Literacy 1950
use ".././output/literacy_mun_1950.dta", clear

keep code2010 total_illiterat total_literat

merge 1:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) total_illiterat total_literat, by(amc)
gsort amc

gen year = 1950

tempfile literacy_1950
save "`literacy_1950'"


* Value Added *
use ".././output/mun_va.dta", clear
keep code2010-gdp_tot

keep if year <= 2000

merge m:1 code2010 using "../output/_Crosswalk_final_1950_2000.dta", keep(3)
collapse (sum) gdp_agri gdp_manufac gdp_serv gdp_tot, by(amc year)
gsort amc year

merge 1:1 amc year using "`amc_pop'", nogen
merge 1:1 amc year using "`amc_emp'", nogen
merge 1:1 amc year using  "`manufac_amc'", nogen
merge 1:1 amc year using  "`foreign_pop'", nogen
merge 1:1 amc year using  "`literacy_1950'", nogen
merge m:1 amc using  "`amc_codes'", nogen
gsort amc year

* merge back with codes
merge m:1 amc using "../output/amc_codes_1950.dta", nogen
drop if amc == .

tempfile amc_1950
save "`amc_1950'"

* Add controls 
merge m:1 amc using "../output/control_amc_1950", nogen

save "../output/amc_panel_1950.dta", replace


***** Collapse at the microregion level *****
use "`amc_1950'", clear

collapse (sum) gdp_agri-total_literat, by(codmicro year)

* Add controls *
merge m:1 codmicro using "../output/control_micro_1950", nogen

* merge back with codes
merge m:1 codmicro using "`micro_codes'", nogen

order codmicro micro_name state_code year

save "../output/micro_panel_1950.dta", replace

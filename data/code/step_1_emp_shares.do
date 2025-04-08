clear all

program state_code
	gen state_name = ""
	replace state_name = "Rondonia" 				if state_code == 11
	replace state_name = "Acre" 					if state_code == 12
	replace state_name = "Amazonas" 				if state_code == 13
	replace state_name = "Roraima" 					if state_code == 14
	replace state_name = "Para" 					if state_code == 15
	replace state_name = "Amapa" 					if state_code == 16
	replace state_name = "Maranhao" 				if state_code == 21
	replace state_name = "Piaui" 					if state_code == 22
	replace state_name = "Ceara" 					if state_code == 23
	replace state_name = "Rio Grande do Norte" 		if state_code == 24
	replace state_name = "Paraiba" 					if state_code == 25
	replace state_name = "Pernambuco" 				if state_code == 26
	replace state_name = "Alagoas" 					if state_code == 27
	replace state_name = "Sergipe" 					if state_code == 28
	replace state_name = "Bahia" 					if state_code == 29
	replace state_name = "Minas Gerais" 			if state_code == 31
	replace state_name = "Espirito Santo" 			if state_code == 32
	replace state_name = "Rio de Janeiro" 			if state_code == 33
	replace state_name = "Sao Paulo" 				if state_code == 35
	replace state_name = "Parana" 					if state_code == 41
	replace state_name = "Santa Catarina" 			if state_code == 42
	replace state_name = "Rio Grande do Sul" 		if state_code == 43
	replace state_name = "Mato Grosso do Sul" 		if state_code == 50
	replace state_name = "Mato Grosso" 				if state_code == 51
	replace state_name = "Goias" 					if state_code == 52
	replace state_name = "Distrito Federal" 		if state_code == 53
	replace state_name = "Tocantins" 				if state_code == 17
end




*** 1960 ***
use ".././raw/census_demog_1950_2010/census_1960_alt.dta", clear

keep code_muni_1960 censobr_weight sex activity state_code broad_activity

drop if sex == .
* replace code2010 = 5300108 if code2010 == . & state_code == 53
* replace code2010 = 3304557 if code2010 == . & state_code == 34

* keep only working population
drop if activity == .

* remove domestic work
* drop if broad_activity == "domestic services"
* drop if broad_activity == "other"

* keep only men
* drop if sex == 0

* Aggregate at the municipality level
collapse (count) emp_num = activity [pweight = censobr_weight], by(broad_activity code_muni_1960)

gen d_agri 			= 0
gen d_manufac 		= 0
gen d_service 		= 0
gen d_transform     = 0
gen d_other			= 0

replace d_agri  		= 1 if broad_activity == "agriculture"
replace d_manufac  		= 1 if broad_activity == "manufacturing" | broad_activity == "mining"
replace d_transf     	= 1 if broad_activity == "manufacturing"
replace d_other			= 1 if broad_activity == "other"
replace d_service  		= 1 if d_agri == 0 & d_manufac == 0 & d_other == 0

collapse (sum) emp_num, by(d_* code_muni_1960)


gen agri_emp 	= emp_num if d_agri 	== 1
gen manufac_emp = emp_num if d_manufac 	== 1
gen transf_emp 	= emp_num if d_transf 	== 1
gen service_emp = emp_num if d_service 	== 1
gen other_emp 	= emp_num if d_other    == 1

gsort code_muni_1960

forvalues i = 1/10{
	bysort code_muni_1960: replace agri_emp 	= agri_emp[_n - `i']    if agri_emp == .
	bysort code_muni_1960: replace agri_emp 	= agri_emp[_n + `i']    if agri_emp == .
	bysort code_muni_1960: replace manufac_emp 	= manufac_emp[_n - `i'] if manufac_emp == .
	bysort code_muni_1960: replace manufac_emp 	= manufac_emp[_n + `i'] if manufac_emp == .
	bysort code_muni_1960: replace transf_emp 	= transf_emp[_n - `i']  if transf_emp == .
	bysort code_muni_1960: replace transf_emp 	= transf_emp[_n + `i']  if transf_emp == .
	bysort code_muni_1960: replace service_emp 	= service_emp[_n - `i'] if service_emp == .
	bysort code_muni_1960: replace service_emp 	= service_emp[_n + `i'] if service_emp == .
	bysort code_muni_1960: replace other_emp 	= other_emp[_n - `i'] 	if other_emp == .
	bysort code_muni_1960: replace other_emp 	= other_emp[_n + `i'] 	if other_emp == .
}

egen emp_total = total(emp_num), by(code_muni_1960)

gen agri_share    = agri_emp/emp_total
gen manufac_share = manufac_emp/emp_total
gen transf_share  = transf_emp/emp_total
gen service_share = service_emp/emp_total

keep if d_agri == 1
drop d_agri-emp_num


foreach v of varlist agri_emp-service_share {
	replace `v' = 0 if `v' == .
}

* generate state codes and labels *
rename code_muni_1960 code2010

gen state_code = int(code2010/100000)
gsort state_code
drop if code2010 == .

state_code

gen year = 1960

* Save
save "../output/censo_emp_shares_1960_part1.dta", replace



*** 1970 ***
use ".././raw/census_demog_1950_2010/original/censo_1970_ocup.dta", clear

drop V002

rename (V054 V023 V026 V027 V044 V045 V041 V035 code_muni) ///
	   (weight_1970 sex age_type age ocup_code act_code income literat code2010)

* Notice that sex is not assigned the same way across the other censuses
drop if sex == .

* Assign activity
gen activity_name = ""
replace activity_name = "agriculture" 		if act_code < 300
replace activity_name = "mining" 			if act_code > 300 & act_code < 310
replace activity_name = "manufacturing" 	if act_code > 310 & act_code < 335
replace activity_name = "construction" 		if act_code == 341 | act_code == 342
replace activity_name = "services" 			if act_code >= 351 & act_code < 930
replace activity_name = "other" 			if act_code >= 931

* keep only working population
drop if act_code == .
drop if act_code == 933 /* looking for job */
gsort act_code

* remove domestic work
* drop if activity_name == "domesticservice"
* drop if activity_name == "other"

* Aggregate at the municipality level
collapse (count) emp_num = act_code [pweight = weight_1970], by(activity_name code2010)

gen d_agri 			= 0
gen d_mining		= 0
gen d_transf		= 0
gen d_const			= 0
gen d_service 		= 0
gen d_other			= 0

replace d_agri  		= 1 if activity_name == "agriculture"
replace d_mining		= 1 if activity_name == "mining"
replace d_transf  		= 1 if activity_name == "manufacturing"
replace d_const 		= 1 if activity_name == "construction"
replace d_service  		= 1 if activity_name == "services"
replace d_other			= 1 if activity_name == "other"

collapse (sum) emp_num, by(d_* code2010)

foreach v in agri mining transf const service other{
	gen `v'_emp 	= emp_num if d_`v' 	== 1
}

gsort code2010

foreach v of varlist agri_emp mining_emp transf_emp const_emp service_emp other_emp{
	forvalues i = 1/10{
		bysort code2010: replace `v' 		= `v'[_n - `i']    if `v'  == .
		bysort code2010: replace `v'  		= `v'[_n + `i']    if `v'  == .
	}
}

egen emp_total = total(emp_num), by(code2010)

keep if d_agri == 1
drop d_agri-emp_num

foreach v of varlist agri_emp-emp_total {
	replace `v' = 0 if `v' == .
}

* generate state codes and labels *
gen state_code = int(code2010/100000)
gsort state_code
drop if code2010 == .

state_code

gen year = 1970

tempfile censo_1970
save "`censo_1970'"

* Merge with names *
import excel ".././raw/amc_name_1872_2010.xls", clear first
keep code2010 mun1970 mun2010

drop if missing(mun1970)
drop if substr(mun1970, 1, 11) == "desmembrado"	
drop if substr(mun1970, 1, 7)  == "anexado"
drop if substr(mun1970, 1, 4)  == "sede"

merge 1:1 code2010 using `censo_1970', nogen

drop if state_name == ""

* Save
save "../output/censo_emp_shares_1970.dta", replace





*** 1980 ***
use ".././raw/census_demog_1950_2010/original/censo_1980_ocup.dta", clear

rename (V519 V530 V532 V607 V501 V604 code_muni) ///
	   (literat ocup_code act_code income sex weight_1980 code2010)

* Notice that sex is not assigned the same way across the other censuses
destring act_code, force replace
destring sex, force replace

drop if sex == .

* Assign activity
gen activity_name = ""
replace activity_name = "agriculture" 		if act_code <  50
replace activity_name = "mining" 			if act_code >= 50  & act_code < 60
replace activity_name = "manufacturing" 	if act_code >= 100 & act_code <= 300
replace activity_name = "construction" 		if act_code == 340
replace activity_name = "services" 			if act_code >= 351 & act_code < 930
replace activity_name = "other" 			if act_code >= 900

* keep only working population
drop if act_code == .
gsort act_code

* remove domestic work
* drop if activity_name == "domesticservice"
* drop if activity_name == "other"

* Aggregate at the municipality level
collapse (count) emp_num = act_code [pweight = weight_1980], by(activity_name code2010)

gen d_agri 			= 0
gen d_mining		= 0
gen d_transf		= 0
gen d_const			= 0
gen d_service 		= 0
gen d_other			= 0

replace d_agri  		= 1 if activity_name == "agriculture"
replace d_mining		= 1 if activity_name == "mining"
replace d_transf  		= 1 if activity_name == "manufacturing"
replace d_const 		= 1 if activity_name == "construction"
replace d_service  		= 1 if activity_name == "services"
replace d_other			= 1 if activity_name == "other"

collapse (sum) emp_num, by(d_* code2010)

foreach v in agri mining transf const service other{
	gen `v'_emp 	= emp_num if d_`v' 	== 1
}

gsort code2010

foreach v of varlist agri_emp mining_emp transf_emp const_emp service_emp other_emp{
	forvalues i = 1/10{
		bysort code2010: replace `v' 		= `v'[_n - `i']    if `v'  == .
		bysort code2010: replace `v'  		= `v'[_n + `i']    if `v'  == .
	}
}

egen emp_total = total(emp_num), by(code2010)

keep if d_agri == 1
drop d_agri-emp_num

foreach v of varlist agri_emp-emp_total {
	replace `v' = 0 if `v' == .
}

* generate state codes and labels *
gen state_code = int(code2010/100000)
gsort state_code
drop if code2010 == .

state_code

gen year = 1980

tempfile censo_1980
save "`censo_1980'"

* Merge with names *
import excel ".././raw/amc_name_1872_2010.xls", clear first
keep code2010 mun1980 mun2010

drop if missing(mun1980)
drop if substr(mun1980, 1, 11) == "desmembrado"	
drop if substr(mun1980, 1, 7)  == "anexado"
drop if substr(mun1980, 1, 4)  == "sede"

merge 1:1 code2010 using `censo_1980', nogen

drop if state_name == ""

* Save
save "../output/censo_emp_shares_1980.dta", replace





*** 1990 ***
use ".././raw/census_demog_1950_2010/original/censo_1990_ocup.dta", clear

rename (V0301 V3072 V0346 V0347 V0356 V7301 code_muni) ///
	   (sex age ocup_code act_code income weight_1990 code2010)
   
* Notice that sex is not assigned the same way across the other censuses
drop if sex == .

* Assign activity
gen activity_name = ""
replace activity_name = "agriculture" 		if act_code < 50
replace activity_name = "mining" 			if act_code >= 50 & act_code <= 59
replace activity_name = "manufacturing" 	if act_code >= 100 & act_code <= 300
replace activity_name = "construction" 		if act_code == 340
replace activity_name = "services" 			if act_code >= 351 & act_code < 900
replace activity_name = "other" 			if act_code >= 900

* keep only working population
drop if act_code == .
gsort act_code


* remove domestic work
* drop if activity_name == "domesticservice"
* drop if activity_name == "other"

* Aggregate at the municipality level
collapse (count) emp_num = act_code [pweight = weight_1990], by(activity_name code2010)

gen d_agri 			= 0
gen d_mining		= 0
gen d_transf		= 0
gen d_const			= 0
gen d_service 		= 0
gen d_other			= 0

replace d_agri  		= 1 if activity_name == "agriculture"
replace d_mining		= 1 if activity_name == "mining"
replace d_transf  		= 1 if activity_name == "manufacturing"
replace d_const 		= 1 if activity_name == "construction"
replace d_service  		= 1 if activity_name == "services"
replace d_other			= 1 if activity_name == "other"

collapse (sum) emp_num, by(d_* code2010)

foreach v in agri mining transf const service other{
	gen `v'_emp 	= emp_num if d_`v' 	== 1
}

gsort code2010

foreach v of varlist agri_emp mining_emp transf_emp const_emp service_emp other_emp{
	forvalues i = 1/10{
		bysort code2010: replace `v' 		= `v'[_n - `i']    if `v'  == .
		bysort code2010: replace `v'  		= `v'[_n + `i']    if `v'  == .
	}
}

egen emp_total = total(emp_num), by(code2010)

keep if d_agri == 1
drop d_agri-emp_num

foreach v of varlist agri_emp-emp_total {
	replace `v' = 0 if `v' == .
}

* generate state codes and labels *
gen state_code = int(code2010/100000)
gsort state_code
drop if code2010 == .

state_code

gen year = 1990

tempfile censo_1990
save "`censo_1990'"

* Merge with names *
import excel ".././raw/amc_name_1872_2010.xls", clear first
keep code2010 mun1991 mun2010

drop if missing(mun1991)
drop if substr(mun1991, 1, 11) == "desmembrado"	
drop if substr(mun1991, 1, 7)  == "anexado"
drop if substr(mun1991, 1, 4)  == "sede"

merge 1:1 code2010 using `censo_1990', nogen

drop if state_name == ""

* Save
save "../output/censo_emp_shares_1990.dta", replace





*** 2000 ***
use ".././raw/census_demog_1950_2010/original/censo_2000_ocup.dta", clear

drop V0103 V0102

rename (code_muni V0401 V4752 V0428 V4300 V4452 V4462 V4513 P001) ///
	   (code2010 sex age literat year_study ocup_code act_code income weight_2000)
   
* Notice that sex is not assigned the same way across the other censuses
drop if sex == .

* Assign activity
gen activity_name = ""
replace activity_name = "agriculture" 		if act_code > 0 & act_code <= 5002
replace activity_name = "mining" 			if act_code >= 10000 & act_code <= 14004
replace activity_name = "manufacturing" 	if act_code >= 15010 & act_code <= 41000
replace activity_name = "construction" 		if act_code >= 45001 & act_code <= 45999
replace activity_name = "services" 			if act_code >= 50010 & act_code <= 99000
replace activity_name = "other" 			if act_code == 0

* keep only working population
drop if act_code == .
gsort act_code


* remove domestic work
* drop if activity_name == "domesticservice"
* drop if activity_name == "other"

* Aggregate at the municipality level
collapse (count) emp_num = act_code [pweight = weight_2000], by(activity_name code2010)

gen d_agri 			= 0
gen d_mining		= 0
gen d_transf		= 0
gen d_const			= 0
gen d_service 		= 0
gen d_other			= 0

replace d_agri  		= 1 if activity_name == "agriculture"
replace d_mining		= 1 if activity_name == "mining"
replace d_transf  		= 1 if activity_name == "manufacturing"
replace d_const 		= 1 if activity_name == "construction"
replace d_service  		= 1 if activity_name == "services"
replace d_other			= 1 if activity_name == "other"

collapse (sum) emp_num, by(d_* code2010)

foreach v in agri mining transf const service other{
	gen `v'_emp 	= emp_num if d_`v' 	== 1
}

gsort code2010

foreach v of varlist agri_emp mining_emp transf_emp const_emp service_emp other_emp{
	forvalues i = 1/10{
		bysort code2010: replace `v' 		= `v'[_n - `i']    if `v'  == .
		bysort code2010: replace `v'  		= `v'[_n + `i']    if `v'  == .
	}
}

egen emp_total = total(emp_num), by(code2010)

keep if d_agri == 1
drop d_agri-emp_num

foreach v of varlist agri_emp-emp_total {
	replace `v' = 0 if `v' == .
}

* generate state codes and labels *
gen state_code = int(code2010/100000)
gsort state_code
drop if code2010 == .

state_code

gen year = 2000

tempfile censo_2000
save "`censo_2000'"

* Merge with names *
import excel ".././raw/amc_name_1872_2010.xls", clear first
keep code2010 mun2000 mun2010

drop if missing(mun2000)
drop if substr(mun2000, 1, 11) == "desmembrado"	
drop if substr(mun2000, 1, 7)  == "anexado"
drop if substr(mun2000, 1, 4)  == "sede"

merge 1:1 code2010 using `censo_2000', nogen

drop if state_name == ""

* Save
save "../output/censo_emp_shares_2000.dta", replace

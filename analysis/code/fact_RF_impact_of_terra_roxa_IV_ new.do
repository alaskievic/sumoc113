clear all

********************************************************************************
* bring coffee production data
use "../../data/output/historic_trade/coffee_prod.dta", clear
keep year coffee_prod region
keep if region == "Brazil" | region == "Outros Paises"
gen region_d = region == "Brazil"
drop region
reshape wide coffee_prod, i(year) j(region_d)
save "../output/prod.dta", replace

* explanatory variable
use "../../data/output/panel_mun_1872_1950.dta", clear	
merge m:1 year using "../output/prod.dta", keep(3)
gen tr = share_tr
egen access_tr_01_min = min(access_tr_01)
egen access_tr_01_max = max(access_tr_01)
gen access_tr = ((access_tr_01 - access_tr_01_min)/(access_tr_01_max - access_tr_01_min))

egen state_access = min(port_dist), by(state_name)
gen dp = state_access == 0 
gen treat_tr = tr*log(coffee_prod1)
gen treat_access = access_tr*log(coffee_prod1)	
gen IV_treat_tr = treat_tr*log(coffee_prod0)
gen IV_treat_access = treat_access*log(coffee_prod0)	
gen ltotal_pop = log(total_pop)
gen lforeign_pop = log(total_foreign)
gen lforeign_share = log(total_foreign/total_pop)
gen ldrr = drr/1000

gen dp_treat_tr = tr*log(coffee_prod1)*log(port_dist)
gen dp_treat_access = access_tr*log(coffee_prod1)*log(port_dist)	

* dummies for year
tab year, gen(d_year_)	
foreach var of varlist manufac_emp_share agri_emp_share service_emp_share ///
	lforeign_pop ltotal_pop ldrr {
		egen X_`var'_1872 = min(cond(year==1872,`var', ., .)), by(mun_code)
		foreach var2 of varlist d_year_* {
			gen X_`var'_`var2' = X_`var'_1872 * `var2'
		}
	}

reghdfe manufac_emp_share treat_tr, absorb(year mun_code) cluster(mun_code)
reghdfe manufac_emp_share treat_access, absorb(year mun_code) cluster(mun_code)
reghdfe manufac_emp_share treat_tr treat_access, absorb(year mun_code) cluster(mun_code)

reghdfe ltotal_pop treat_tr, absorb(year mun_code) cluster(mun_code)
reghdfe ltotal_pop treat_access, absorb(year mun_code) cluster(mun_code)
reghdfe ltotal_pop treat_tr treat_access, absorb(year mun_code) cluster(mun_code)
ivreghdfe ltotal_pop (treat_tr treat_access = IV*), absorb(year mun_code) cluster(mun_code)
ivreghdfe ltotal_pop (treat_tr treat_access = IV*) X_ltotal_pop_d_*, absorb(year mun_code) cluster(mun_code)





ivreghdfe lforeign_share (treat_tr treat_access = IV*) X_ltotal_pop_d_*, absorb(year mun_code) cluster(mun_code)

reghdfe ltotal_pop treat_tr, absorb(year mun_code) cluster(mun_code)
reghdfe ltotal_pop treat_tr treat_access, absorb(year mun_code) cluster(mun_code)

reghdfe lforeign_share treat_tr, absorb(year mun_code) cluster(mun_code)
reghdfe lforeign_share treat_tr treat_access, absorb(year mun_code) cluster(mun_code)


// ivreghdfe manufac_emp_share (treat_tr treat_access = IV_treat_tr IV_treat_access), absorb(year mun_code) cluster(mun_code)
//
// reghdfe lforeign_pop treat_tr treat_access, absorb(year mun_code) cluster(mun_code)
// reghdfe ltotal_pop treat_tr treat_access, absorb(year mun_code) cluster(mun_code)
//
// reghdfe ltotal_pop treat_tr, absorb(year mun_code) cluster(mun_code)
// reghdfe ltotal_pop treat_tr treat_access, absorb(year mun_code) cluster(mun_code)
//
// reghdfe ldrr treat_tr, absorb(year mun_code) cluster(mun_code)
// reghdfe ldrr treat_tr treat_access, absorb(year mun_code) cluster(mun_code)

********************************************************************************

clear all

program main 
	
	prepare_data
	run_regressions
	make_table
	
end

program prepare_data 
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
	gen tr = share_tr > 0
	
	egen state_access = min(dport_min), by(state_name)
	gen dp = state_access == 0
	
	
	*** Exploration of port distance measures starts here
	
	* gen dp = 1
	* replace dp = 0 if inlist(state_name, "MT", "TO", "GO", "MG")
	
	** keep only top major ports **
	* gen dp = 0
	* replace dp = 1 if inlist(state_name, "SP", "RJ", "AM", "PA", "PE", "RS", "BA")
	
	** keep only top major ports **
	* gen dp = 0
	* replace dp = 1 if inlist(state_name, "SP", "RJ", "ES", "BA")
	
	
	** dummy 200km 
	* gen dp = dport_dist < 200
	
	* gen dp = -1*log(dport_dist_coffee)
	* gen dp = 1/dport_dist_major
	
	* gen dp = dport_dist_major
	
	* replace dp = 1 if inlist(state_name, "PE", "ES", "PA", "PI")
	
	***
	
	
	gen tr_c = tr*log(coffee_prod1)
	gen dp_c = dp*log(coffee_prod1)
	gen treat = tr*dp*log(coffee_prod1)
	gen IV_tr_c = tr*log(coffee_prod0)
	gen IV_dp_c = dp*log(coffee_prod0)
	gen IV_treat = tr*dp*log(coffee_prod0)
	gen ltotal_pop = log(total_pop)
	gen lforeign_pop = log(total_foreign)
	gen ldrr = drr/1000
	
	* dummies for year
	tab year, gen(d_year_)	
	foreach var of varlist manufac_emp_share agri_emp_share service_emp_share ///
		lforeign_pop ltotal_pop ldrr {
			egen X_`var'_1872 = min(cond(year==1872,`var', ., .)), by(mun_code)
			foreach var2 of varlist d_year_* {
				gen X_`var'_`var2' = X_`var'_1872 * `var2'
			}
		}
	* human capital
// 	gen X_lit1872 = log(lit_rate_1872)*year
// 	gen X_lit1920 = log(lit_rate_1920)*year
end

program run_regressions

	mat coef = J(16,12,.)
	
	reghdfe manufac_emp_share treat tr_c dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 1 1 0
	reghdfe agri_emp_share treat tr_c dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 1 2 0	
	reghdfe service_emp_share treat tr_c dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 1 3 0
	reghdfe lforeign_pop treat tr_c dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 1 4 0
	reghdfe ltotal_pop treat tr_c dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 1 5 0
	reghdfe ldrr treat tr_c dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 1 6 0
	
	ivreghdfe manufac_emp_share (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 2 1 1
	ivreghdfe agri_emp_share (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 2 2 1
	ivreghdfe service_emp_share (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 2 3 1
	ivreghdfe lforeign_pop (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 2 4 1
	ivreghdfe ltotal_pop (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 2 5 1
	ivreghdfe ldrr (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c, absorb(year mun_code) cluster(mun_code)
	get_results 2 6 1
	
	reghdfe manufac_emp_share treat tr_c dp_c X_manufac_emp_share*, absorb(year mun_code) cluster(mun_code)
	get_results 3 1 0
	reghdfe agri_emp_share treat tr_c dp_c X_agri_emp_share*, absorb(year mun_code) cluster(mun_code)
	get_results 3 2 0	
	reghdfe service_emp_share treat tr_c dp_c X_service_emp_share*, absorb(year mun_code) cluster(mun_code)
	get_results 3 3 0
	reghdfe lforeign_pop treat tr_c dp_c X_lforeign_pop*, absorb(year mun_code) cluster(mun_code)
	get_results 3 4 0
	reghdfe ltotal_pop treat tr_c dp_c X_ltotal_pop*, absorb(year mun_code) cluster(mun_code)
	get_results 3 5 0
	reghdfe ldrr treat tr_c dp_c X_ldrr*, absorb(year mun_code) cluster(mun_code)
	get_results 3 6 0
	
	ivreghdfe manufac_emp_share (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c X_manufac_emp_share*, absorb(year mun_code) cluster(mun_code)
	get_results 4 1 1
	ivreghdfe agri_emp_share (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c X_agri_emp_share*, absorb(year mun_code) cluster(mun_code)
	get_results 4 2 1
	ivreghdfe service_emp_share (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c X_service_emp_share*, absorb(year mun_code) cluster(mun_code)
	get_results 4 3 1
	ivreghdfe lforeign_pop (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c X_lforeign_pop*, absorb(year mun_code) cluster(mun_code)
	get_results 4 4 1
	ivreghdfe ltotal_pop (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c X_ltotal_pop*, absorb(year mun_code) cluster(mun_code)
	get_results 4 5 1
	ivreghdfe ldrr (treat = IV_treat) tr_c dp_c IV_tr_c IV_dp_c X_ldrr*, absorb(year mun_code) cluster(mun_code)
	get_results 4 6 1

end

program get_results

	mat coef[4*(`1'-1)+1,`2'] = _b[treat]
	mat coef[4*(`1'-1)+2,`2'] = _se[treat]	
	mat coef[4*(`1'-1)+1,`2' + 6] = 2*ttail(10000,abs(_b[treat]/_se[treat]))
	mat coef[4*(`1'-1)+3,`2'] = e(N_full)
	if `3' == 0 {
		mat coef[4*(`1'-1)+4,`2'] = e(r2)
	}
	if `3' == 1 {
		mat coef[4*(`1'-1)+4,`2'] = e(idp)
	}
	
end

program make_table

	clear 
	svmat coef
	foreach var of varlist coef1-coef6 {
		gen aux_var = string(`var')
		tostring `var', replace force format(%9.3f)		
		replace `var' = "0.001" if `var' == "0.000"
		replace `var' = "(" + `var' + ")" if _n == 2 | _n == 6 | _n == 10 | _n == 14 | _n == 18 | _n == 22 | _n == 26 
		replace `var' = "" if `var' == "." | `var' == "(.)" | `var' == "(0)"
		replace `var' = "-0.001" if `var' == "-0"
		replace `var' = aux_var if _n == 3 | _n == 7 | _n == 11 | _n == 15 | _n == 19 | _n == 23 | _n == 27
		drop aux_var
	}
	forvalues ix = 1/6 {
		local pv = `ix' + 6
		replace coef`ix' = coef`ix' + "***" if coef`pv' < 0.01
		replace coef`ix' = coef`ix' + "**" if coef`pv' >= 0.01 & coef`pv' < 0.05
		replace coef`ix' = coef`ix' + "*" if coef`pv' >= 0.05 & coef`pv' < 0.10
	}
	drop if coef1 == "" | coef1 == "."
	
	* make 1st column
	gen col_1 = "$\text{TR}_{i}\times\text{AP}_{i}\times\text{CE}_{t}$" if _n == 1 | _n == 5 | _n == 9 | _n == 13 | _n == 17 | _n == 21 | _n == 25
	replace col_1 = "Obs" if _n == 3 | _n == 7 | _n == 11 | _n == 15
	replace col_1 = "R2" if _n == 4 | _n == 12
	replace col_1 = "KP p-value" if _n == 8 | _n == 16
	
	* fill panel info
	gen col_aux = ""
	replace col_1 = "\multicolumn{7}{l}{\emph{a. Specification: OLS}} \\ " + col_1 if _n == 1	
	replace col_1 = "\\ \multicolumn{7}{l}{\emph{b. Specification: IV}} \\ " + col_1 if _n == 5
	replace col_1 = "\\ \multicolumn{7}{l}{\emph{c. Specification: OLS + Controls for initial condition}} \\ " + col_1 if _n == 9	
	replace col_1 = "\\ \multicolumn{7}{l}{\emph{d. Specification: IV + Controls for initial condition}} \\ " + col_1 if _n == 13	
	
	* make table
	#delimit;
	listtab col_1 coef1 coef2 coef3 coef4 coef5 coef6
			using "../output/rf_iv.tex", type
			rstyle(tabular) 									
			head("\begin{tabular}{lrrrrrrr}\hline"					
			"           & \multicolumn{6}{c}{Dependent Variable}  \\ \cline{2-7} "								
			"           & Mfg   & Agr   & Ser    & Foreign Pop.  & Total Pop. & Dist. RR  \\ "								
			"           & Share & Share & Share  & Log           & Log       & Levels       \\ "								
			"           & (1)   & (2)   & (3)    & (4)           & (5)       & (6)       \\ \hline")								
			foot("\hline \end{tabular}")
				replace;
	#delimit cr	
end

main

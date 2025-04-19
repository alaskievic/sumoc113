clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel_1950.dta", clear	

* Define treatment variable
gen log_cap 	= log(capital_app + 1)
gen asinh_cap 	= asinh(capital_app)

* Alternative *
gen alt		  = capital_app
replace alt   = 0 if capital_app < 5000
gen asinh_alt = asinh(alt)

* Per population and total emplyoment *
gen asinh_cap_pp = asinh(capital_app + 1/poptot)
gen asinh_cap_pw = asinh(capital_app + 1/emp_total)

gen asinh_alt_pp 	= asinh(alt/poptot)
gen asinh_alt_pw 	= asinh(alt/emp_total)

* Define instrument
gen foreign_share 			= .
replace foreign_share 		= foreign_tot/poptot 		if year == 1950

* Define some controls
gen illit_share_1950 		= .
gen urb_share_1950   		= .
gen log_pop_1950			= .
replace illit_share_1950 	= total_illiterat/poptot 	if year == 1950
replace urb_share_1950 		= popurb/poptot 			if year == 1950
replace log_pop_1950 		= log(poptot) 				if year == 1950

* Region fixed effects
gen d_region = .
replace d_region = 1 if uf_amc <= 2 | uf_amc == 21
replace d_region = 2 if uf_amc >= 3  & uf_amc <= 10
replace d_region = 3 if uf_amc >= 11 & uf_amc <= 13
replace d_region = 4 if uf_amc >= 14 & uf_amc <= 15
replace d_region = 5 if uf_amc == 16 | state_code == 51 | state_code == 50

* Define some LHS variables
gen log_pop 		= log(poptot)
gen log_urb			= log(popurb)
gen log_rur			= log(poprur)
gen urb_share		= popurb/poptot
gen rur_share		= poprur/poptot

gen agri_share 		= agri_emp/emp_total
gen manufac_share 	= manufac_emp/emp_total
gen serv_share		= service_emp/emp_total

gen log_va_agri			= log(gdp_agri/poptot)
gen log_va_manufac		= log(gdp_manufac/poptot)
gen log_va_serv			= log(gdp_serv/poptot)
gen log_va_total		= log(gdp_tot/poptot)

gen va_agri_share		= gdp_agri/gdp_tot
gen va_manufac_share	= gdp_manufac/gdp_tot
gen va_serv_share		= gdp_serv/gdp_tot

* Change between 1950 and 1970
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share{
	gen `v'_dshort			= `v' - `v'[_n-2] if year == 1970 & amc == amc[_n-1]
}

* Change between 1970 and 2000
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share{
	gen `v'_dlong			= `v' - `v'[_n-6] if year == 2000 & amc == amc[_n-1]
}

* Change between 1950 and 2000
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share{
	gen `v'_dlongest			= `v' - `v'[_n-8] if year == 2000 & amc == amc[_n-1]
}

* Arrange variables of 1950
foreach x in 1/20{
	replace foreign_share 		= foreign_share[_n-1]    if foreign_share == .
	replace capital_app 		= capital_app[_n-1] 	 if capital_app == .
	replace alt 				= alt[_n-1] 	 		 if alt == .
	replace log_cap 			= log_cap[_n-1] 		 if log_cap == .
	replace illit_share_1950 	= illit_share_1950[_n-1] if illit_share_1950 == .
	replace urb_share_1950 		= urb_share_1950[_n-1] 	 if urb_share_1950 == .
	replace asinh_cap 			= asinh_cap[_n-1] 	 	 if asinh_cap == .
	replace asinh_alt 			= asinh_alt[_n-1] 	 	 if asinh_alt == .
	replace asinh_alt_pp 		= asinh_alt_pp[_n-1] 	 if asinh_alt_pp == .
	replace asinh_alt_pw 		= asinh_alt_pw[_n-1] 	 if asinh_alt_pw == .
	replace log_pop_1950 		= log_pop_1950[_n-1] 	 if log_pop_1950 == .
}






program reg_short_base{
	local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

	local c2list `c1list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

	local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital i.d_region
						  

	mat coef = J(32,24,.)
		
	reg agri_share_dshort asinh_alt_pw, cluster(amc)
	get_results 1 1 0
	reg manufac_share_dshort asinh_alt_pw,  cluster(amc)
	get_results 1 2 0	
	reg ser_share_dshort asinh_alt_pw,  cluster(amc)
	get_results 1 3 0
	reg log_pop_dshort asinh_alt_pw, cluster(amc)
	get_results 1 4 0
	reg log_urb_dshort asinh_alt_pw, cluster(amc)
	get_results 1 5 0
	reg log_rur_dshort treat asinh_alt_pw, cluster(amc)
	get_results 1 6 0
		
	reg agri_share_dshort asinh_alt_pw `c1list', cluster(amc)
	get_results 2 1 0
	reg manufac_share_dshort asinh_alt_pw `c1list', cluster(amc)
	get_results 2 2 0
	reg ser_share_dshort asinh_alt_pw `c1list', cluster(amc)
	get_results 2 3 0
	reg log_pop_dshort asinh_alt_pw `c1list', cluster(amc)
	get_results 2 4 0
	reg log_urb_dshort asinh_alt_pw `c1list', cluster(amc)
	get_results 2 5 0
	reg log_rur_dshort treat asinh_alt_pw `c1list', cluster(amc)
	get_results 2 6 0


	reg agri_share_dshort asinh_alt_pw `c2list', cluster(amc)
	get_results 3 1 0
	reg manufac_share_dshort asinh_alt_pw `c2list', cluster(amc)
	get_results 3 2 0
	reg ser_share_dshort asinh_alt_pw `c2list', cluster(amc)
	get_results 3 3 0
	reg log_pop_dshort asinh_alt_pw `c2list', cluster(amc)
	get_results 3 4 0
	reg log_urb_dshort asinh_alt_pw `c2list', cluster(amc)
	get_results 3 5 0
	reg log_rur_dshort treat asinh_alt_pw `c2list', cluster(amc)
	get_results 3 6 0


	reg agri_share_dshort asinh_alt_pw `c3list', cluster(amc)
	get_results 4 1 0
	reg manufac_share_dshort asinh_alt_pw `c3list', cluster(amc)
	get_results 4 2 0
	reg ser_share_dshort asinh_alt_pw `c3list',cluster(amc)
	get_results 4 3 0
	reg log_pop_dshort asinh_alt_pw `c3list', cluster(amc)
	get_results 4 4 0
	reg log_urb_dshort asinh_alt_pw `c3list', cluster(amc)
	get_results 4 5 0
	reg log_rur_dshort asinh_alt_pw `c3list', cluster(amc)
	get_results 4 6 0

	ivreg2 agri_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 5 1 1
	ivreg2 manufac_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 5 2 1
	ivreg2 ser_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 5 3 1
	ivreg2 log_pop_dshort asinh_alt_pw (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 5 4 1
	ivreg2 log_urb_dshort (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 5 5 1
	ivreg2 log_rur_dshort (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 5 6 1
		
	ivreg2 agri_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 6 1 1
	ivreg2 manufac_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 6 2 1
	ivreg2 ser_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 6 3 1
	ivreg2 log_pop_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 6 4 1
	ivreg2 log_urb_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 6 5 1
	ivreg2 log_rur_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 6 6 

	ivreg2 agri_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 7 1 1
	ivreg2 manufac_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 7 2 1
	ivreg2 ser_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 7 3 1
	ivreg2 log_pop_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 7 4 1
	ivreg2 log_urb_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 7 5 1
	ivreg2 log_rur_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 7 6 1


	ivreg2 agri_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 8 1 1
	ivreg2 manufac_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 8 2 1
	ivreg2 ser_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 8 3 1
	ivreg2 log_pop_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 8 4 1
	ivreg2 log_urb_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 8 5 1
	ivreg2 log_rur_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)
	get_results 8 6 1
}



program get_results{
	mat coef[8*(`1'-1)+1,`2'] = _b[treat]
	mat coef[8*(`1'-1)+2,`2'] = _se[treat]	
	mat coef[8*(`1'-1)+1,`2' + 6] = 2*ttail(10000,abs(_b[treat]/_se[treat]))
	mat coef[8*(`1'-1)+3,`2'] = e(N_full)
	if `3' == 0 {
		mat coef[8*(`1'-1)+8,`2'] = e(r2_a)
	}
	if `3' == 1 {
		mat coef[8*(`1'-1)+8,`2'] = e(widstat)
}}}}


reg_short_base
get_results

clear 
svmat coef
foreach var of varlist coef1-coef8 {
	gen aux_var = string(`var')
	tostring `var', replace force format(%9.3f)		
	replace `var' = "0.001" if `var' == "0.000"
	replace `var' = "(" + `var' + ")" if _n == 2 | _n == 6 | _n == 10 | _n == 14 | _n == 18 | _n == 22 | _n == 26
	replace `var' = "" if `var' == "." | `var' == "(.)" | `var' == "(0)"
	replace `var' = "-0.001" if `var' == "-0"
	replace `var' = aux_var if _n == 3 | _n == 7 | _n == 11 | _n == 15 | _n == 19 | _n == 23 | _n == 27
	drop aux_var
}
forvalues ix = 1/8 {
	local pv = `ix' + 8
	replace coef`ix' = coef`ix' + "***" if coef`pv' < 0.01
	replace coef`ix' = coef`ix' + "**" if coef`pv' >= 0.01 & coef`pv' < 0.05
	replace coef`ix' = coef`ix' + "*" if coef`pv' >= 0.05 & coef`pv' < 0.10
}
drop if coef1 == "" | coef1 == "."
	
* make 1st column
gen col_1 = "$asinh(FDI per Worker)$" if _n == 1 | _n == 5 | _n == 9 | _n == 13 | _n == 17 | _n == 21 | _n == 25
replace col_1 = "Observations" if _n == 3 | _n == 7 | _n == 11 | _n == 15
replace col_1 = "Adj. R2" if _n == 4 | _n == 12
replace col_1 = "KP p-value" if _n == 8 | _n == 16
	
* fill panel info
gen col_aux = ""
replace col_1 = "\multicolumn{7}{l}{\emph{a. Specification: OLS}} \\ " + col_1 if _n == 1	
replace col_1 = "\\ \multicolumn{7}{l}{\emph{b. Specification: IV}} \\ " + col_1 if _n == 5
replace col_1 = "\\ \multicolumn{7}{l}{\emph{c. Specification: OLS + Controls for initial condition}} \\ " + col_1 if _n == 9	
replace col_1 = "\\ \multicolumn{7}{l}{\emph{d. Specification: IV + Controls for initial condition}} \\ " + col_1 if _n == 13	
	
* make table
#delimit;
listtab col_1 coef1 coef2 coef3 coef4 coef5 coef6 coef7 coef8
		using "../output/short_diff_base.tex", type
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









* OLS Regressions *

** Short **
eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_cap, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


* Alt *
eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_alt, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_alt) star(* 0.10 ** 0.05 *** 0.01) compress


* Alt per pop *
eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_alt_pp, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_alt_pp) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_alt_pp urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_alt_pp) star(* 0.10 ** 0.05 *** 0.01) compress

eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_alt_pp urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_alt_pp) star(* 0.10 ** 0.05 *** 0.01) compress



* Other Outcomes *
eststo clear
foreach v in log_va_agri_dshort log_va_manufac_dshort log_va_serv_dshort log_va_total_dshort{
eststo: qui reg `v' asinh_cap, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dshort log_urb_dshort log_rur_dshort urb_share_dshort{
eststo: qui reg `v' asinh_cap, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dshort log_va_manufac_dshort log_va_serv_dshort log_va_total_dshort{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dshort log_urb_dshort log_rur_dshort urb_share_dshort{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress



eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dshort log_va_manufac_dshort log_va_serv_dshort log_va_total_dshort{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dshort log_urb_dshort log_rur_dshort urb_share_dshort{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress




** Long **
eststo clear
foreach v in agri_share_dlong manufac_share_dlong serv_share_dlong va_agri_share_dlong ///
			 va_manufac_share_dlong va_serv_share_dlong{
eststo: qui reg `v' asinh_cap, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dlong log_va_manufac_dlong log_va_serv_dlong log_va_total_dlong{
eststo: qui reg `v' asinh_cap, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dlong log_urb_dlong log_rur_dlong urb_share_dlong{
eststo: qui reg `v' asinh_cap, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share_dlong manufac_share_dlong serv_share_dlong va_agri_share_dlong ///
			 va_manufac_share_dlong va_serv_share_dlong{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dlong log_va_manufac_dlong log_va_serv_dlong log_va_total_dlong{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dlong log_urb_dlong log_rur_dlong urb_share_dlong{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress



eststo clear
foreach v in agri_share_dlong manufac_share_dlong serv_share_dlong va_agri_share_dlong ///
			 va_manufac_share_dlong va_serv_share_dlong{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dlong log_va_manufac_dlong log_va_serv_dlong log_va_total_dlong{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dlong log_urb_dlong log_rur_dlong urb_share_dlong{
eststo: qui reg `v' asinh_cap urb_share_1950 illit_share_1950 log_pop_1950 i.d_region, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress




*** IV Regressions ***
** Short **
eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui ivreg2 `v' (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dshort log_va_manufac_dshort log_va_serv_dshort log_va_total_dshort{
eststo: qui ivreg2 `v' (asinh_cap = foreign_share), cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dshort log_urb_dshort log_rur_dshort urb_share_dshort{
eststo: qui ivreg2 `v' (asinh_cap = foreign_share), cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dshort log_va_manufac_dshort log_va_serv_dshort log_va_total_dshort{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dshort log_urb_dshort log_rur_dshort urb_share_dshort{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress




eststo clear
foreach v in agri_share_dshort manufac_share_dshort serv_share_dshort va_agri_share_dshort ///
			 va_manufac_share_dshort va_serv_share_dshort{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 i.d_region (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dshort log_va_manufac_dshort log_va_serv_dshort log_va_total_dshort{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 i.d_region (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dshort log_urb_dshort log_rur_dshort urb_share_dshort{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 i.d_region (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress




** Long **
eststo clear
foreach v in agri_share_dlong manufac_share_dlong serv_share_dlong va_agri_share_dlong ///
			 va_manufac_share_dlong va_serv_share_dlong{
eststo: qui ivreg2 `v' (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dlong log_urb_dlong log_rur_dlong urb_share_dlong{
eststo: qui ivreg2 `v' (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share_dlong manufac_share_dlong serv_share_dlong va_agri_share_dlong ///
			 va_manufac_share_dlong va_serv_share_dlong{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dlong log_va_manufac_dlong log_va_serv_dlong log_va_total_dlong{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dlong log_urb_dlong log_rur_dlong urb_share_dlong{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress



eststo clear
foreach v in agri_share_dlong manufac_share_dlong serv_share_dlong va_agri_share_dlong ///
			 va_manufac_share_dlong va_serv_share_dlong{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 i.d_region (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_va_agri_dlong log_va_manufac_dlong log_va_serv_dlong log_va_total_dlong{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 i.d_region (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_pop_dlong log_urb_dlong log_rur_dlong urb_share_dlong{
eststo: qui ivreg2 `v' urb_share_1950 illit_share_1950 log_pop_1950 i.d_region (asinh_cap = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_cap) star(* 0.10 ** 0.05 *** 0.01) compress





* Longest *
eststo clear
foreach v in agri_share_dlongest manufac_share_dlongest serv_share_dlongest va_agri_share_dlongest ///
			 va_manufac_share_dlongest va_serv_share_dlongest{
eststo: qui reg `v' asinh_alt, vce (cluster amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(asinh_alt) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share_dlongest manufac_share_dlongest serv_share_dlongest va_agri_share_dlongest ///
			 va_manufac_share_dlongest va_serv_share_dlongest{
eststo: qui ivreg2 `v' (asinh_alt = foreign_share),cluster (amc)
}
esttab, se(3) ar2 stat (r2_a N widstat, fmt(%9.3f)) keep(asinh_alt) star(* 0.10 ** 0.05 *** 0.01) compress




























local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital i.d_region

eststo clear
eststo: qui reg agri_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 agri_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 manufac_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1950-1970)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 serv_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_pop_dshort (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1950-1970)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 urb_share_dshort (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (amc)

esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel E.} & \multicolumn{8}{c}{$\Delta$ Urban Population Shares (1950-1970)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")















gen time_treat 		= 0
replace time_treat 	= 1 if year >= 1970
gen did_cont 	= time_treat*asinh_cap

gsort amc year
drop if agri share == .



did_multiplegt_stat  agri_share amc  year did_cont


did_multiplegt_stat agri_share amc year did_cont

did_multiplegt_dyn agri_share amc year did_cont

use "https://github.com/chaisemartinPackages/ApplicationData/raw/main/data_gazoline.dta", clear

keep if year <= 1967

// Example 1 //
did_multiplegt_stat lngca id year tau


	
	* Regressions with Share of Terra Roxa
	eststo clear
	eststo: qui reg dltotal_pop_1950 share_tr, vce (cluster mun_code)
	eststo: qui reg dltotal_pop_1950 share_tr i.state_code, vce (cluster mun_code)
	eststo: qui reg dltotal_pop_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) replace f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{3}{c}{$\Delta$ Log Population (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	eststo clear
	eststo: qui reg dlmanufac_emp_share_1950 share_tr, vce (cluster mun_code)
	eststo: qui reg dlmanufac_emp_share_1950 share_tr i.state_code, vce (cluster mun_code)
	eststo: qui reg dlmanufac_emp_share_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{3}{c}{$\Delta$ Log Manufacturing Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")



	eststo clear
	eststo: qui reg dlagri_emp_share_1950 share_tr, vce (cluster mun_code)
	eststo: qui reg dlagri_emp_share_1950 share_tr i.state_code, vce (cluster mun_code)
	eststo: qui reg dlagri_emp_share_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{3}{c}{$\Delta$ Log Agriculture Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	
	eststo clear
	eststo: qui reg dlservice_emp_share_1950 share_tr, vce (cluster mun_code)
	eststo: qui reg dlservice_emp_share_1950 share_tr i.state_code, vce (cluster mun_code)
	eststo: qui reg dlservice_emp_share_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{3}{c}{$\Delta$ Log Services Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")
	
	
	eststo clear
	eststo: qui reg dlforeign_pop_share_1950 share_tr, vce (cluster mun_code)
	eststo: qui reg dlforeign_pop_share_1950 share_tr i.state_code, vce (cluster mun_code)
	eststo: qui reg dlforeign_pop_share_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
	

	esttab * using "../output/mun_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) plain prehead("\noalign{\vskip 0.25cm}") ///
	posthead("\textbf{Panel E.} & \multicolumn{3}{c}{$\Delta$ Log Foreign Population Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.1cm}" "\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" "State FE & \multicolumn{1}{c}{} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Baseline Controls & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
	

	
	
eststo clear
	eststo: qui reg dltotal_pop_1950 tr_dp_d1950, vce (cluster mun_code)
	eststo: qui reg dltotal_pop_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
	eststo: qui reg dltotal_pop_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff_fmm.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(tr_dp_d1950) replace f noobs noabbrev varlabels (tr_dp_d1950 "Inverse FMM * Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{3}{c}{$\Delta$ Log Population (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	eststo clear
	eststo: qui reg dmanufac_emp_share_1950 tr_dp_d1950, vce (cluster mun_code)
	eststo: qui reg dmanufac_emp_share_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals  X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)	
	eststo: qui reg dmanufac_emp_share_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals  X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff_fmm.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(tr_dp_d1950) append f noobs noabbrev varlabels (tr_dp_d1950 "Inverse FMM * Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{3}{c}{$\Delta$ Manufacturing Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")



	eststo clear
	eststo: qui reg dagri_emp_share_1950 tr_dp_d1950, vce (cluster mun_code)
	eststo: qui reg dagri_emp_share_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
	eststo: qui reg dagri_emp_share_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff_fmm.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(tr_dp_d1950) append f noobs noabbrev varlabels (tr_dp_d1950 "Inverse FMM * Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{3}{c}{$\Delta$Agriculture Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	
	eststo clear
	eststo: qui reg dservice_emp_share_1950 tr_dp_d1950, vce (cluster mun_code)
	eststo: qui reg dservice_emp_share_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
	eststo: qui reg dservice_emp_share_1950 tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)

	esttab * using "../output/mun_long_diff_fmm.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(tr_dp_d1950) append f noobs noabbrev varlabels (tr_dp_d1950 "Inverse FMM * Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{3}{c}{$\Delta$ Services Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")
	
	
	eststo clear
	eststo: qui reg dlforeign_pop_share_1950 share_tr, vce (cluster mun_code)
	eststo: qui reg dlforeign_pop_share_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
	eststo: qui reg dlforeign_pop_share_1950 share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
	

	esttab * using "../output/mun_long_diff_fmm.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (tr_dp_d1950 "Inverse FMM * Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) plain prehead("\noalign{\vskip 0.25cm}") ///
	posthead("\textbf{Panel E.} & \multicolumn{3}{c}{$\Delta$ Log Foreign Population Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.1cm}" "\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" "State FE & & & \multicolumn{1}{c}{\checkmark}\\" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")




program state_long_diff
	use "../../data/output/panel_mun_1872_1950.dta", clear	
	keep if inlist(year, 1872, 1950)
	
	gen tr_total = share_tr * total_area
	keep year state_code total_foreign total_pop manufac_emp agri_emp service_emp total_emp total_area tr_total
	
	collapse (sum) total_foreign total_pop manufac_emp agri_emp service_emp total_emp total_area tr_total, by(year state_code)
	
	gen share_tr = tr_total/total_area
	
	gen manufac_emp_share = manufac_emp/total_emp
	gen agri_emp_share    = agri_emp/total_emp
	gen service_emp_share = service_emp/total_emp
	gen foreign_pop_share  = total_foreign/total_pop

	* controls
	gen pop_dens = total_pop/total_area
	foreach var of varlist manufac_emp_share total_pop total_emp foreign_pop_share agri_emp agri_emp_share service_emp_share pop_dens{
		gen  l`var' 		= log(`var')				
		egen l`var'_1872 	= max(cond(year == 1872, l`var', ., .)), by(state_code)
	}
	gen larea_km2 = log(total_area)
	foreach v of varlist  larea_km2 ltotal_emp_1872 ltotal_pop_1872 lagri_emp_1872 {
		egen X_CV_1872_`v' = max(cond(year == 1872, `v', ., .)), by(state_code)
	}
	
	* Generate long differences
	gsort state_code year
	
	foreach v of varlist manufac_emp_share agri_emp_share service_emp_share total_pop foreign_pop_share pop_dens{
		gen d`v'_1950 = `v' - `v'[_n-1] if year == 1950 & state_code == state_code[_n-1]
	}
	foreach v of varlist lmanufac_emp_share lagri_emp_share lservice_emp_share ltotal_pop lforeign_pop_share lpop_dens{
		gen d`v'_1950 = `v' - `v'[_n-1] if year == 1950 & state_code == state_code[_n-1]
	}
	
	* Regressions with Share of Terra Roxa
	eststo clear
	eststo: qui reg dltotal_pop_1950 share_tr, vce (cluster state_code)
	eststo: qui reg dltotal_pop_1950 share_tr X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) replace f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{2}{c}{$\Delta$ Log Population (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	eststo clear
	eststo: qui reg dlmanufac_emp_share_1950 share_tr, vce (cluster state_code)
	eststo: qui reg dlmanufac_emp_share_1950 share_tr X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{2}{c}{$\Delta$ Log Manufacturing Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")


	eststo clear
	eststo: qui reg dlagri_emp_share_1950 share_tr, vce (cluster state_code)
	eststo: qui reg dlagri_emp_share_1950 share_tr X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{2}{c}{$\Delta$ Log Agriculture Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	
	eststo clear
	eststo: qui reg dlservice_emp_share_1950 share_tr, vce (cluster state_code)
	eststo: qui reg dlservice_emp_share_1950 share_tr X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{2}{c}{$\Delta$ Log Services Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")
	
	
	eststo clear
	eststo: qui reg dlforeign_pop_share_1950 share_tr, vce (cluster state_code)
	eststo: qui reg dlforeign_pop_share_1950 share_tr X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)
	

	esttab * using "../output/state_long_diff.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(share_tr) append f noobs noabbrev varlabels (share_tr "Share of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) plain prehead("\noalign{\vskip 0.25cm}") ///
	posthead("\textbf{Panel E.} & \multicolumn{2}{c}{$\Delta$ Log Foreign Population Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.1cm}" "\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
	
	
	/*
	foreach v of varlist dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950 dlpop_dens_1950 {
		reg `v' share_tr, r
	}
	foreach v of varlist dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950 dlpop_dens_1950 {
		reg `v' share_tr i.state_code, r
	}
	foreach v of varlist dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950 dlpop_dens_1950 {
		reg `v' share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, r
	} */
	
	* Regressions with Levels of Terra Roxa - Control for Total Area
	gen ltr_total = asinh(tr_total)
	eststo clear
	eststo: qui reg dltotal_pop_1950 ltr_total X_CV_1872_larea_km2, vce (cluster state_code)
	eststo: qui reg dltotal_pop_1950 ltr_total X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff_level.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(ltr_total) replace f noobs noabbrev varlabels (ltr_total "Total Area Of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}"  "\textbf{Panel A.} & \multicolumn{2}{c}{$\Delta$ Log Population (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	eststo clear
	eststo: qui reg dlmanufac_emp_share_1950 ltr_total X_CV_1872_larea_km2, vce (cluster state_code)
	eststo: qui reg dlmanufac_emp_share_1950 ltr_total X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff_level.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(ltr_total) append f noobs noabbrev varlabels (ltr_total "Total Area Of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines ///
	posthead("\noalign{\vskip 0.1cm}"  "\textbf{Panel B.} & \multicolumn{2}{c}{$\Delta$ Log Manufacturing Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")



	eststo clear
	eststo: qui reg dlagri_emp_share_1950 ltr_total X_CV_1872_larea_km2, vce (cluster state_code)
	eststo: qui reg dlagri_emp_share_1950 ltr_total X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff_level.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(ltr_total) append f noobs noabbrev varlabels (ltr_total "Total Area Of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines///
	posthead("\noalign{\vskip 0.1cm}"  "\textbf{Panel C.} & \multicolumn{2}{c}{$\Delta$ Log Agriculture Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")

	
	eststo clear
	eststo: qui reg dlservice_emp_share_1950 ltr_total X_CV_1872_larea_km2, vce (cluster state_code)
	eststo: qui reg dlservice_emp_share_1950 ltr_total X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)

	esttab * using "../output/state_long_diff_level.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(ltr_total) append f noobs noabbrev varlabels (ltr_total "Total Area Of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines///
	posthead("\noalign{\vskip 0.1cm}"  "\textbf{Panel D.} & \multicolumn{2}{c}{$\Delta$ Log Services Employment Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}")
	
	
	eststo clear
	eststo: qui reg dlforeign_pop_share_1950 ltr_total X_CV_1872_larea_km2, vce (cluster state_code)
	eststo: qui reg dlforeign_pop_share_1950 ltr_total X_CV_1872_larea_km2 X_CV_1872_ltotal_pop_1872, vce (cluster state_code)
	

	esttab * using "../output/state_long_diff_level.tex", style(tex) label notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(ltr_total) append f noobs noabbrev varlabels (ltr_total "Total Area Of Terra Roxa") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) plain prehead("\noalign{\vskip 0.25cm}")///
	posthead("\textbf{Panel E.} & \multicolumn{2}{c}{$\Delta$ Log Foreign Population Share (1872-1950)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.1cm}" "\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" "Total Area Control &  \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
end program


program tr_distribution
	use "../../data/output/panel_mun_1872_1950.dta", clear	
	keep if year == 1872	
	#delimit;
	twoway histogram share_tr, percent
		ytitle("% of Municipalities")
		xtitle("Share of Terra Roxa")
		ylabel(, grid gmax glpattern(solid) glcolor(gs15))
		graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
		lpattern(blank) ilpattern(blank)) plotregion(style(none))
		scheme(s1mono);
	#delimit cr
	graph export "../output/share_tr_dist.eps", as(eps) replace
end


clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel_1940.dta", clear	

merge m:1 amc using "../output/matched_ps_75.dta", keep(3) nogen

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
gen log_dens		= log(poptot/area_amc_1940)
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

gen log_agri_emp		= log(agri_emp)
gen log_manufac_emp		= log(manufac_emp)
gen log_serv_emp		= log(service_emp)
gen log_tot_emp			= log(emp_total)

gen va_agri_share		= gdp_agri/gdp_tot
gen va_manufac_share	= gdp_manufac/gdp_tot
gen va_serv_share		= gdp_serv/gdp_tot

* Change between 1950 and 1970
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share log_agri_emp ///
					 log_manufac_emp log_serv_emp log_tot_emp{
	gen `v'_dshort			= `v' - `v'[_n-2] if year == 1970 & amc == amc[_n-1]
}

* Change between 1970 and 2000
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share log_agri_emp ///
					 log_manufac_emp log_serv_emp log_tot_emp{
	gen `v'_dlong			= `v' - `v'[_n-6] if year == 2000 & amc == amc[_n-1]
}

* Change between 1950 and 2000
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share log_agri_emp ///
					 log_manufac_emp log_serv_emp log_tot_emp{
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
	replace asinh_cap_pp 		= asinh_cap_pp[_n-1] 	 if asinh_cap_pp == .
	replace asinh_alt_pp 		= asinh_alt_pp[_n-1] 	 if asinh_alt_pp == .
	replace asinh_alt 			= asinh_alt[_n-1] 	 	 if asinh_alt == .
	replace log_pop_1950 		= log_pop_1950[_n-1] 	 if log_pop_1950 == .
}

foreach year in 1940 1950 1960 1970 1980 1990 2000 {
		gen X_CV_`year'_illit_share_1950 	= illit_share_1950*(year == `year')
		gen X_CV_`year'_urb_share_1950 		= urb_share_1950*(year == `year')
		gen X_CV_`year'_log_pop_1950 		= log_pop_1950*(year == `year')
}



* For DiD *

/*
egen asinh_cap_med = median(asinh_cap)
egen asinh_alt_med = median(asinh_alt)

xtile asinh_cap_pc = asinh_cap, nquantiles(4)
xtile asinh_alt_pc = asinh_alt, nquantiles(4)

gen d_alt_med = 0
gen d_alt_75  = 0
replace d_alt_med 	= 1 if asinh_alt_pc 	>= 3
replace d_alt_75 	= 1 if asinh_alt_pc 	== 4
*/

egen asing_alt_pp_med = median(asinh_alt_pp)
egen asing_alt_pw_med = median(asinh_alt_pw)

xtile asing_alt_pp_pc = asinh_alt_pp, nquantiles(4)
xtile asing_alt_pw_pc = asinh_alt_pw, nquantiles(4)

gen d_alt_med = 0
gen d_alt_75  = 0
replace d_alt_med 	= 1 if asing_alt_pp_pc 	>= 3
replace d_alt_75 	= 1 if asing_alt_pp_pc 	== 4

gen d_plus = 	0
replace d_plus = 1 if asinh_alt > 0
************** Time Dummies **************
foreach year in 1940 1950 1970 1980 1990 2000 {
		gen X_asinh_cap_`year' 			= asinh_cap*(year == `year')
		gen X_asinh_alt_`year' 			= asinh_alt*(year == `year')
		gen X_foreign_share_iv_`year' 	= foreign_share*(year == `year')
		gen X_asinh_cap_pp_`year' 		= asinh_cap_pp*(year == `year')
		gen X_asinh_alt_pp_`year' 		= asinh_alt_pp*(year == `year')
		gen d_alt_75_`year' 			= d_alt_75*(year == `year')
}


* run regressions based on specifications and make figures - Baseline OLS
program make_event_cap
	mat coef = J(7,3,0)		
	reghdfe `1' X_asinh_alt_pp_* X_CV_*_illit_share_1950 ///
			X_CV_*_urb_share_1950 X_CV_*_log_pop_1950 , absorb(amc year) cluster(amc)
	local row = 2
	foreach year in 1940 1950 1970 1980 1990 2000 {
		mat coef[`row',1] = _b[X_asinh_alt_pp_`year']
		mat coef[`row',2] = _b[X_asinh_alt_pp_`year'] + 1.96*_se[X_asinh_alt_pp_`year']
		mat coef[`row',3] = _b[X_asinh_alt_pp_`year'] - 1.96*_se[X_asinh_alt_pp_`year']
		local row = `row' + 1
	}

	* make figures
	preserve
	clear 
	svmat coef
	gen year = 1960 if _n == 1
	replace year = 1940 if _n == 2
	replace year = 1950 if _n == 3
	replace year = 1970 if _n == 4
	replace year = 1980 if _n == 5
	replace year = 1990 if _n == 6
	replace year = 2000 if _n == 7
	* replace coef1 = . if _n == 2
	* replace coef2 = . if _n == 2
	* replace coef3 = . if _n == 2
	drop if coef1 == 0 & year != 1960

	#delimit;
	twoway (scatter coef1 year, mcolor(gs1))
			(rcap coef2 coef3 year, lcolor(gs1)),
			  xlabel(1940 1950 1960 1970 1980 1990 2000, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
				lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
				xtitle("")								
				ytitle("`2'")
				ylabel(, grid glpattern(solid))
				xsize(6) ysize(4) 
				legend(off)
				scheme(s1mono);		
	#delimit cr
	graph export "../output/event_asinh_`1'_matched_ps75.png", as(png) replace
end



make_event_cap agri_share 		"Agriculture Employment Share"
make_event_cap manufac_share 	"Manufacturing Employment Share"
make_event_cap serv_share 		"Services Employment Share"


make_event_cap log_pop 		"Log Total Population"
make_event_cap log_urb 		"Log Urban Population"
make_event_cap log_rur 		"Log Rural Population"
make_event_cap urb_share 	"Urban Population Share"


make_event_cap agri_share 		"Agriculture Employment Share"
make_event_cap manufac_share 	"Manufacturing Employment Share"
make_event_cap serv_share 		"Services Employment Share"




* run regressions based on specifications and make figures - Baseline OLS
program make_event_cap
	mat coef = J(7,3,0)		
	reghdfe `1' d_alt_75_* X_CV_*_illit_share_1950 ///
			X_CV_*_urb_share_1950 X_CV_*_log_pop_1950 , absorb(amc year) cluster(amc)
	local row = 2
	foreach year in 1940 1950 1970 1980 1990 2000 {
		mat coef[`row',1] = _b[d_alt_75_`year']
		mat coef[`row',2] = _b[d_alt_75_`year'] + 1.96*_se[d_alt_75_`year']
		mat coef[`row',3] = _b[d_alt_75_`year'] - 1.96*_se[d_alt_75_`year']
		local row = `row' + 1
	}

	* make figures
	preserve
	clear 
	svmat coef
	gen year = 1960 if _n == 1
	replace year = 1940 if _n == 2
	replace year = 1950 if _n == 3
	replace year = 1970 if _n == 4
	replace year = 1980 if _n == 5
	replace year = 1990 if _n == 6
	replace year = 2000 if _n == 7
	* replace coef1 = . if _n == 2
	* replace coef2 = . if _n == 2
	* replace coef3 = . if _n == 2
	drop if coef1 == 0 & year != 1960

	#delimit;
	twoway (scatter coef1 year, mcolor(gs1))
			(rcap coef2 coef3 year, lcolor(gs1)),
			  xlabel(1940 1950 1960 1970 1980 1990 2000, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
				lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
				xtitle("")								
				ytitle("`2'")
				ylabel(, grid glpattern(solid))
				xsize(6) ysize(4) 
				legend(off)
				scheme(s1mono);		
	#delimit cr
	graph export "../output/event_asinh_`1'_matched_dummy_ps75.png", as(png) replace
end



make_event_cap agri_share 		"Agriculture Employment Share"
make_event_cap manufac_share 	"Manufacturing Employment Share"
make_event_cap serv_share 		"Services Employment Share"


make_event_cap log_pop 		"Log Total Population"
make_event_cap log_urb 		"Log Urban Population"
make_event_cap log_rur 		"Log Rural Population"
make_event_cap urb_share 	"Urban Population Share"



make_event_cap log_agri_emp 		"Log Agricutlure Emplotment"
make_event_cap log_manufac_emp 		"Log Manufacturing Employment"
make_event_cap log_serv_emp 		"Log Service Employment"
make_event_cap log_tot_emp 			"Log Total Employment"







* run regressions based on specifications and make figures - Baseline OLS
program make_event_cap
	mat coef = J(7,3,0)		
	reghdfe `1' d_alt_75 X_CV_*_illit_share_1950 ///
			X_CV_*_urb_share_1950 X_CV_*_log_pop_1950 , absorb(amc year) cluster(amc)
	local row = 2
	foreach year in 1940 1950 1970 1980 1990 2000 {
		mat coef[`row',1] = _b[X_asinh_cap_`year']
		mat coef[`row',2] = _b[X_asinh_cap_`year'] + 1.96*_se[X_asinh_cap_`year']
		mat coef[`row',3] = _b[X_asinh_cap_`year'] - 1.96*_se[X_asinh_cap_`year']
		local row = `row' + 1
	}

	* make figures
	preserve
	clear 
	svmat coef
	gen year = 1960 if _n == 1
	replace year = 1940 if _n == 2
	replace year = 1950 if _n == 3
	replace year = 1970 if _n == 4
	replace year = 1980 if _n == 5
	replace year = 1990 if _n == 6
	replace year = 2000 if _n == 7
	* replace coef1 = . if _n == 2
	* replace coef2 = . if _n == 2
	* replace coef3 = . if _n == 2
	drop if coef1 == 0 & year != 1960

	#delimit;
	twoway (scatter coef1 year, mcolor(gs1))
			(rcap coef2 coef3 year, lcolor(gs1)),
			  xlabel(1940 1950 1960 1970 1980 1990 2000, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
				lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
				xtitle("")								
				ytitle("`2'")
				ylabel(, grid glpattern(solid))
				xsize(6) ysize(4) 
				legend(off)
				scheme(s1mono);		
	#delimit cr
	graph export "../output/event_asinh_`1'.png", as(png) replace
end



make_event_cap agri_share 		"Agriculture Employment Share"
make_event_cap manufac_share 	"Manufacturing Employment Share"
make_event_cap serv_share 		"Services Employment Share"


make_event_cap log_pop 		"Log Total Population"
make_event_cap log_urb 		"Log Urban Population"
make_event_cap log_rur 		"Log Rural Population"
make_event_cap urb_share 	"Urban Population Share"










































* run regressions based on specifications and make figures - IV
program make_event_iv
	mat coef = J(7,3,0)		
	ivreghdfe `1' X_CV_*_illit_share_1950 X_CV_*_urb_share_1950 X_CV_*_log_pop_1950 /// 
				  (X_asinh_cap_* = X_foreign_share_iv_*) , absorb(amc year) cluster(amc)
	local row = 2
	foreach year in 1940 1950 1970 1980 1990 2000 {
		mat coef[`row',1] = _b[X_asinh_cap_`year']
		mat coef[`row',2] = _b[X_asinh_cap_`year'] + 1.96*_se[X_asinh_cap_`year']
		mat coef[`row',3] = _b[X_asinh_cap_`year'] - 1.96*_se[X_asinh_cap_`year']
		local row = `row' + 1
	}

	* make figures
	preserve
	clear 
	svmat coef
	gen year = 1960 if _n == 1
	replace year = 1940 if _n == 2
	replace year = 1950 if _n == 3
	replace year = 1970 if _n == 4
	replace year = 1980 if _n == 5
	replace year = 1990 if _n == 6
	replace year = 2000 if _n == 7
	* replace coef1 = . if _n == 2
	* replace coef2 = . if _n == 2
	* replace coef3 = . if _n == 2
	drop if coef1 == 0 & year != 1960

	#delimit;
	twoway (scatter coef1 year, mcolor(gs1))
			(rcap coef2 coef3 year, lcolor(gs1)),
			  xlabel(1940 1950 1960 1970 1980 1990 2000, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
				lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
				xtitle("")								
				ytitle("`2'")
				ylabel(, grid glpattern(solid))
				xsize(6) ysize(4) 
				legend(off)
				scheme(s1mono);		
	#delimit cr	
end



make_event_iv agri_share 		"Agriculture Employment Share"
make_event_iv manufac_share 	"Manufacturing Employment Share"
make_event_iv serv_share 		"Services Employment Share"


make_event_iv log_pop "Log Total Population"
make_event_iv log_urb "Log Urban Population"
make_event_iv log_rur "Log Rural Population"
make_event_iv urb_share "Urban Population Share"





* DiD *
gen time_treat 		= 0
replace time_treat 	= 1 if year >= 1970


gen did_med 	= time_treat*d_alt_med
gen did_75	 	= time_treat*d_alt_75
gen did_cont 	= time_treat*asinh_alt

xtset amc year

drop if agri_share == .
































did_multiplegt_dyn agri_share amc year did_cont,  effects(4) placebo(2) cluster(amc)


did_multiplegt_dyn agri_share amc year did_cont,  effects(4) placebo(2) continuous(3) bootstrap(50, 42) cluster(amc)



eststo clear
foreach v in agri_share manufac_share serv_share{
	eststo: qui  reghdfe `v' did_75 , absorb(amc year) cluster(amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(did_75) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share manufac_share serv_share{
	eststo: qui   reghdfe `v' did_75 X_CV_*_illit_share_1950 X_CV_*_urb_share_1950 X_CV_*_log_pop_1950, absorb(amc year) cluster(amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(did_75) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in agri_share manufac_share serv_share{
	eststo: qui   reghdfe `v' did_75 X_CV_*_illit_share_1950 X_CV_*_urb_share_1950 X_CV_*_log_pop_1950 i.d_region#i.year, absorb(amc year) cluster(amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(did_75) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in log_dens log_urb log_rur urb_share{
	eststo: qui   reghdfe `v' did_75 , absorb(amc year) cluster(amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(did_75) star(* 0.10 ** 0.05 *** 0.01) compress

eststo clear
foreach v in log_dens log_urb log_rur urb_share{
	eststo: qui   reghdfe `v' did_75 X_CV_*_illit_share_1950 X_CV_*_urb_share_1950 X_CV_*_log_pop_1950, absorb(amc year) cluster(amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(did_75) star(* 0.10 ** 0.05 *** 0.01) compress

eststo clear
foreach v in log_dens log_urb log_rur urb_share{
	eststo: qui   reghdfe `v' did_75 X_CV_*_illit_share_1950 X_CV_*_urb_share_1950 X_CV_*_log_pop_1950 i.d_region#i.year, absorb(amc year) cluster(amc)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(did_75) star(* 0.10 ** 0.05 *** 0.01) compress


/*
foreach v in agri_share manufac_share serv_share{
	xtdidregress (`v' X_CV_*_illit_share_1950 X_CV_*_urb_share_1950 X_CV_*_log_pop_1950) (did_75), group(amc) time(year)
}

foreach v in agri_share manufac_share serv_share{			 
	xtdidregress (`v') (did_cont, continuous), group(amc) time(year)
}

*/



* Scatter Plots in 1950 *
keep if year == 1950


#delimit;
twoway (scatter log_dens agri_share if d_alt_75 == 0, mcolor(blue))
	   (scatter log_dens agri_share if d_alt_75 == 1, mcolor(orange)),
			   ytitle("Log Population Density (1950)") 
			   xtitle("Agriculture Employment Share (1950)")
			   legend(order(1 "Below 75th Treatment" 0 "Above 75th Treatment") rows(3) position(12) ring(0) region(lstyle(black)))
			   graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			   lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../output/scatter_dens_agri.png", as(png) replace

#delimit;
twoway (scatter log_dens manufac_share if d_alt_75 == 0, mcolor(blue))
	   (scatter log_dens manufac_share if d_alt_75 == 1, mcolor(orange)),
			   ytitle("Log Population Density (1950)") 
			   xtitle("Manufacturing Employment Share (1950)")
			   legend(order(1 "Below 75th Treatment" 0 "Above 75th Treatment") rows(3) position(12) ring(0) region(lstyle(black)))
			   graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			   lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../output/scatter_dens_manufac.png", as(png) replace



#delimit;
twoway (scatter log_dens serv_share if d_alt_75 == 0, mcolor(blue))
	   (scatter log_dens serv_share if d_alt_75 == 1, mcolor(orange)),
			   ytitle("Log Population Density (1950)") 
			   xtitle("Service Employment Share (1950)")
			   legend(order(1 "Below 75th Treatment" 0 "Above 75th Treatment") rows(3) position(12) ring(0) region(lstyle(black)))
			   graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			   lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../output/scatter_dens_serv.png", as(png) replace

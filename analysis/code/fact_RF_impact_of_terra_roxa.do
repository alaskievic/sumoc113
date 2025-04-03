clear all

program main
	prepare_data
	* button 1 - specification
	* button 2 - explanatory variable (continuous vs dummy)
	* button 3 - drop the west
	run_regressions 0 0 0
	run_regressions 1 0 0
	run_regressions 2 0 0
	run_regressions 3 0 0
	run_regressions 0 1 0
	run_regressions 1 1 0
	run_regressions 2 1 0
	run_regressions 3 1 0
	run_regressions 0 0 1
	run_regressions 1 0 1
	run_regressions 2 0 1
	run_regressions 3 0 1
end

program prepare_data
	* for continuous
	use "../../data/output/panel_mun_1872_1950.dta", clear	
	* controls
	foreach var of varlist 	manufac_emp_share total_pop foreign_pop_share agri_emp ///
							agri_emp_share service_emp_share{
		gen  l`var' 		= log(`var')				
		egen l`var'_1872 	= max(cond(year == 1872, l`var', ., .)), by(mun_code)
	}
	gen larea_km2 = log(total_area)	
	foreach year in 1890 1920 1940 1950 {
		gen X_CV_`year'_west 			= west*(year == `year')
		gen X_CV_`year'_larea_km2 		= larea_km2*(year == `year')
		gen X_CV_`year'_capitals 		= capitals*(year == `year')
		gen X_CV_`year'_port_min 		= dport_min*(year == `year')
		gen X_CV_`year'_total_emp 		= ltotal_pop_1872*(year == `year')
		gen X_CV_`year'_agri_emp 		= lagri_emp_1872*(year == `year')
		gen X_CV_`year'_gaez_cocoa 		= gaez_cocoa*(year == `year')
		gen X_CV_`year'_gaez_sugarcane 	= gaez_sugarcane*(year == `year')
		gen X_CV_`year'_gaez_rubbaer 	= gaez_rubber*(year == `year')
	}
	foreach year in 1860 1890 1900 1910 1920 1930 1940 1950 {
		gen Xrr_DV_`year' = share_tr*(year == `year')
	}
	foreach year in 1860 1890 1900 1910 1920 1930 1940 1950 {
		gen Xrr_CV_`year'_west 				= west*(year == `year')
		gen Xrr_CV_`year'_larea_km2 		= larea_km2*(year == `year')
		gen Xrr_CV_`year'_capitals 			= capitals*(year == `year')
		gen Xrr_CV_`year'_port_min 			= dport_min*(year == `year')
		gen Xrr_CV_`year'_total_emp 		= ltotal_pop_1872*(year == `year')
		gen Xrr_CV_`year'_agri_emp 			= lagri_emp_1872*(year == `year')		
		gen Xrr_CV_`year'_gaez_cocoa 		= gaez_cocoa*(year == `year')
		gen Xrr_CV_`year'_gaez_sugarcane 	= gaez_sugarcane*(year == `year')
		gen Xrr_CV_`year'_gaez_rubber		= gaez_rubber*(year == `year')
	}	
	* state-level dummies
	tab state_code, gen(dstate)
	foreach var of varlist dstate1-dstate22 {
		foreach year in 1890 1920 1940 1950 {
			gen dX_`var'_`year' = `var'*(year == `year')
		}
		foreach year in 1860 1890 1900 1910 1920 1930 1940 1950 {
			gen dXrr_`var'_`year' = `var'*(year == `year')
		}
	}
	* explanatory variable
	foreach year in 1890 1920 1940 1950 {
		gen X_DV_`year' = share_tr*(year == `year')
	}
	* interaction with exports
	gen lcoffee_br_exp = log(coffee_br_exp)
	gen X_DV_exp = share_tr*lcoffee_br_exp
	save "../output/mun_data_for_reg.dta", replace
	
	* for dummy explanatory variable
	replace share_tr = share_tr > 0.5
	drop X_DV*
	foreach year in 1890 1920 1940 1950 {
		gen X_DV_`year' = share_tr*(year == `year')
	}
	save "../output/mun_data_for_reg_dummy.dta", replace
end

program run_regressions	
	local spec = `1'	
	local dummy = `2'
	local drop_west = `3'
	
	* call dataset based on explanatory variable
	if `dummy' == 0 {
		use "../output/mun_data_for_reg.dta", clear	
	}
	if `dummy' == 1 {
		use "../output/mun_data_for_reg_dummy.dta", clear	
	}
	if `drop_west' == 1 {
		drop if west == 1
	}
	
	* run regressions based on specifications
	mat coef = J(5,9,0)
	mat coef_rr = J(9,3,0)
	if `spec' == 0 {
		reghdfe lmanufac_emp_share X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 1
		reghdfe lforeign_pop_share X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 4
		reghdfe ltotal_pop X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 7
		reghdfe d_10km Xrr_DV_* Xrr_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef_rr 1
	}
	if `spec' == 1 {
		drop if mun_name == "São Paulo"
		drop if mun_name == "Rio de Janeiro"
		
		reghdfe lmanufac_emp_share X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 1
		reghdfe lforeign_pop_share X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 4
		reghdfe ltotal_pop X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 7
		reghdfe d_10km Xrr_DV_* Xrr_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef_rr 1
	}
	if `spec' == 2 {
		drop if state_code == 35
		
		reghdfe lmanufac_emp_share X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 1
		reghdfe lforeign_pop_share X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 4
		reghdfe ltotal_pop X_DV_* X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 7
		reghdfe d_10km Xrr_DV_* Xrr_CV_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef_rr 1
	}
	if `spec' == 3 {
		reghdfe lmanufac_emp_share X_DV_* X_CV_* dX_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 1
		reghdfe lforeign_pop_share X_DV_* X_CV_* dX_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 4
		reghdfe ltotal_pop X_DV_* X_CV_* dX_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef 7
		reghdfe d_10km Xrr_DV_* Xrr_CV_* dXrr_*, absorb(mun_code year) cluster(meso_code_1872)
		get_coef_rr 1
	}

	* make figures
	preserve
	clear 
	svmat coef
	gen year = 1872 if _n == 1
	replace year = 1890 if _n == 2
	replace year = 1920 if _n == 3
	replace year = 1940 if _n == 4
	replace year = 1950 if _n == 5
	replace coef1 = . if _n == 2
	replace coef2 = . if _n == 2
	replace coef3 = . if _n == 2
	drop if coef1 == 0 & year != 1872

	#delimit;
	twoway (scatter coef1 year, mcolor(gs1))
		   (rcap coef2 coef3 year, lcolor(gs1)),
		   xlabel(1860 1872 1890 1920 1940 1950, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
			lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
			xtitle("")									
			ytitle("DV: log of share of emp in mafg")	
			ylabel(, grid glpattern(solid))
			xsize(6) ysize(4) 
			legend(off)
			scheme(s1mono);		
	#delimit cr	
	graph export "../output/fig_reg_mfg_controls_`spec'_`dummy'_`drop_west'.eps", as(eps) replace

	#delimit;
	twoway (scatter coef4 year, mcolor(gs1))
		   (rcap coef5 coef6 year, lcolor(gs1)),
		   xlabel(1860 1872 1890 1920 1940 1950, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
			lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
			xtitle("")									
			ytitle("DV: log of share of immigrants")	
			ylabel(, grid glpattern(solid))			
			xsize(6) ysize(4) 
			legend(off)
			scheme(s1mono);		
	#delimit cr	
	graph export "../output/fig_reg_immigrants_controls_`spec'_`dummy'_`drop_west'.eps", as(eps) replace

	#delimit;
	twoway (scatter coef7 year, mcolor(gs1))
		   (rcap coef8 coef9 year, lcolor(gs1)),
		   xlabel(1860 1872 1890 1920 1940 1950, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
			lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
			xtitle("")									
			ytitle("DV: log of total population")	
			ylabel(, grid glpattern(solid))				
			xsize(6) ysize(4) 
			legend(off)
			scheme(s1mono);		
	#delimit cr	
	graph export "../output/fig_reg_population_controls_`spec'_`dummy'_`drop_west'.eps", as(eps) replace
	
	clear 
	svmat coef_rr
	rename (coef_rr1 coef_rr2 coef_rr3) (coef1 coef2 coef3)
	gen year = 1872
	local row = 2
	foreach year in 1860 1890 1898 1910 1920 1930 1940 1950 {
		replace year = `year' if _n == `row'
		local row = `row' + 1
	}
	drop if coef1 == 0 & year != 1872

	#delimit;
	twoway (scatter coef1 year, mcolor(gs1))
		   (rcap coef2 coef3 year, lcolor(gs1)),
		   xlabel(1860 1872 1890 1898 1910 1920 1930 1940 1950, angle(45))
			graphregion(fcolor(white) lstyle(none) ilstyle(none)											
			lpattern(blank) ilpattern(blank)) plotregion(style(none)) 
			xtitle("")									
			ytitle("DV: less than 10 km from a railroad")	
			ylabel(, grid glpattern(solid))
			xsize(6) ysize(4) 
			legend(off)
			scheme(s1mono);		
	#delimit cr	
	graph export "../output/fig_reg_rr_controls_`spec'_`dummy'_`drop_west'.eps", as(eps) replace
	restore
end

program get_coef
	local row = 2
	foreach year in 1890 1920 1940 1950 {
		mat coef[`row',`1'] = _b[X_DV_`year']
		mat coef[`row',`1'+1] = _b[X_DV_`year'] + 1.96*_se[X_DV_`year']
		mat coef[`row',`1'+2] = _b[X_DV_`year'] - 1.96*_se[X_DV_`year']
		local row = `row' + 1
	}
end

program get_coef_rr
	local row = 2
	foreach year in 1860 1890 1900 1910 1920 1930 1940 1950 {
		mat coef_rr[`row',`1'] = _b[Xrr_DV_`year']
		mat coef_rr[`row',`1'+1] = _b[Xrr_DV_`year'] + 1.96*_se[Xrr_DV_`year']
		mat coef_rr[`row',`1'+2] = _b[Xrr_DV_`year'] - 1.96*_se[Xrr_DV_`year']
		local row = `row' + 1
	}
end

reghdfe ltotal_pop X_DV_exp X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
reghdfe lmanufac_emp_share X_DV_exp X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
reghdfe lagri_emp_share X_DV_exp X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
reghdfe lservice_emp_share X_DV_exp X_CV_*, absorb(mun_code year) cluster(meso_code_1872)
reghdfe lforeign_pop_share X_DV_exp X_CV_*, absorb(mun_code year) cluster(meso_code_1872)


main

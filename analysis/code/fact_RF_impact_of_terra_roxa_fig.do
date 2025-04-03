clear all

program main
	prepare_data	
	make_figure_1872_1950 manufac_emp_share "share of emp. in mfg"
	make_figure_1872_1950 agri_emp_share "share of emp. in agr"
	make_figure_1872_1950 service_emp_share "share of emp. in ser"
	make_figure_1872_1950 ltotal_pop "log of total population"
	make_figure_1872_1950 lforeign_pop "log of foreign population"
	make_figure_1860_1950 drr "Distance to railroad (1000 km)"
end

program prepare_data
	* for continuous
	use "../../data/output/panel_mun_1872_1950.dta", clear	
	gen ltotal_pop = log(total_pop)
	gen lforeign_pop = log(total_foreign)
	replace drr = drr/1000
	
	* dummies for year
	tab year, gen(d_year_)	
	foreach var of varlist manufac_emp_share agri_emp_share service_emp_share ///
		lforeign_pop ltotal_pop drr {
			egen X_`var'_1872 = min(cond(year==1872,`var', ., .)), by(mun_code)
			foreach var2 of varlist d_year_* {
				gen X_`var'_`var2' = X_`var'_1872 * `var2'
			}
		}
	
	* explanatory variable
	gen tr = share_tr > 0
	egen state_access = min(dport_min), by(state_name)
	gen dp = state_access == 0	
	foreach year in 1890 1920 1940 1950 {
		gen X_treatment_`year' = tr*dp*(year == `year')
		gen X_tr_`year' = tr*(year == `year')
		gen X_dp_`year' = dp*(year == `year')
	}
	foreach year in 1860 1890 1900 1910 1920 1930 1940 1950 {
		gen Xrr_treatment_`year' = tr*dp*(year == `year')
		gen Xrr_tr_`year' = tr*(year == `year')
		gen Xrr_dp_`year' = dp*(year == `year')
	}
end

program make_figure_1872_1950	
	
	* run regressions based on specifications
	mat coef = J(5,9,0)		
	reghdfe `1' X_treatment_* X_tr_* X_dp_*, absorb(mun_code year) cluster(mun_code)
	local row = 2
	foreach year in 1890 1920 1940 1950 {
		mat coef[`row',1] = _b[X_treatment_`year']
		mat coef[`row',2] = _b[X_treatment_`year'] + 1.96*_se[X_treatment_`year']
		mat coef[`row',3] = _b[X_treatment_`year'] - 1.96*_se[X_treatment_`year']
		local row = `row' + 1
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
			ytitle("`2'")	
			ylabel(, grid glpattern(solid))
			xsize(6) ysize(4) 
			legend(off)
			scheme(s1mono);		
	#delimit cr	
	graph export "../output/fig_reg_`1'.eps", as(eps) replace
end

program make_figure_1860_1950	
	
	* run regressions based on specifications
	mat coef = J(9,3,0)
	reghdfe `1' Xrr_treatment_* Xrr_tr_* Xrr_dp_* Xrr_`1', absorb(mun_code year) cluster(mun_code)
	local row = 2
	foreach year in 1860 1890 1900 1910 1920 1930 1940 1950 {
		mat coef[`row',1] = _b[Xrr_treatment_`year']
		mat coef[`row',2] = _b[Xrr_treatment_`year'] + 1.96*_se[Xrr_treatment_`year']
		mat coef[`row',3] = _b[Xrr_treatment_`year'] - 1.96*_se[Xrr_treatment_`year']		
		local row = `row' + 1
	}

	* make figures
	preserve
	clear 
	svmat coef
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
			ytitle("`2'")	
			ylabel(, grid glpattern(solid))
			xsize(6) ysize(4) 
			legend(off)
			scheme(s1mono);		
	#delimit cr	
	graph export "../output/fig_reg_`1'.eps", as(eps) replace

end

main

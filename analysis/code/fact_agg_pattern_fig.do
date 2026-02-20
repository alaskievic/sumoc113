clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel_1940.dta", clear	

* Define some  variables
gen log_pop 		= log(poptot)
gen log_dens		= log(poptot/area_amc_1940)
gen log_urb			= log(popurb)
gen log_rur			= log(poprur)
gen urb_share		= popurb/poptot
gen rur_share		= poprur/poptot

gen gdpc = (gdp_tot * 1000)/poptot
gen lgdpc 			= log(gdpc)

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

#delimit;
twoway (scatter  agri_share lgdpc if lgdpc > 6 & lgdpc < 11, mcolor("black"))
(lowess  agri_share  lgdpc if lgdpc > 6 & lgdpc < 11, lwidth(thick) lcolor("orange")),
			xtitle("Log Real GDP Per Capita") 
			ytitle("Agriculture Employment Share")
			xsize(10) ysize(5)
			legend(off)
			ylabel(0(0.1)1)
			graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../output/agri_emp_sh_rgdpc_1940.png", as(png) replace



use "../../data/output/10sd_un_pwt.dta", replace
* keep if year <= 2000
keep if countrycode == "BRA"
gen gdpc  = (rgdpe/pop)
gen lgdpc = log(rgdpe/pop)
gen lgdpw = log(rgdpe/emp)
gen lpop  = log(pop)
by countrycode: gen lgdpc_growth = lgdpc-lgdpc[_n-1]
by countrycode: gen lpop_growth  = lpop-lpop[_n-1]
gen agri_emp_sh 	= agri_emp/tot_emp
gen manufac_emp_sh	= manufac_emp/tot_emp
gen serv_emp_sh		= serv_emp/tot_emp
gen agri_va_sh		= agri_va_real/tot_va_real
gen manufac_va_sh	= manufac_va_real/tot_va_real
gen serv_va_sh		= serv_va_real/tot_va_real



#delimit;
	twoway (line gdpc year, lpattern(solid) lwidth(0.5)),
			xlabel(1950(5)2014, angle(45))
			ytitle("Level")
			xtitle("")
			xsize(8) ysize(5)
			ylabel(, grid gmax glpattern(solid) glcolor(gs15))		
			graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr

#delimit;
	twoway (line lgdpc year, lpattern(solid) lwidth(0.5))	
	       (line lpop year, lpattern(solid) lwidth(0.5)),
		   legend(order(1 "Log GDPC PPP" 2 "Log POP") rows(3) position(11) ring(0) region(lstyle(black)))
			xlabel(1950(5)2014, angle(45))
			ytitle("Level")
			xtitle("")
			xsize(8) ysize(5)
			ylabel(, grid gmax glpattern(solid) glcolor(gs15))		
			graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../../analysis/output/10sd_lgdpc_growth.png", as(png) replace

#delimit;
	twoway (line agri_emp_sh year, lpattern(solid) lwidth(0.5))	
	       (line manufac_emp_sh year, lpattern(solid) lwidth(0.5))	
           (line serv_emp_sh year, lpattern(solid) lwidth(0.5)),	
			legend(order(1 "Agriculture" 2 "Manufacturing" 3 "Services") rows(3) position(1) ring(0) region(lstyle(black)))
			xlabel(1950(5)2000, angle(45))
			ytitle("Share of Total Employment")
			ylabel(0(0.1)0.8)
			xtitle("")
			xsize(8) ysize(5)
			ylabel(, grid gmax glpattern(solid) glcolor(gs15))		
			graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../../analysis/output/10sd_emp_sh.png", as(png) replace


#delimit;
	twoway (line agri_va_sh year, lpattern(solid) lwidth(0.5))	
	       (line manufac_va_sh year, lpattern(solid) lwidth(0.5))	
           (line serv_va_sh year, lpattern(solid) lwidth(0.5)),	
			legend(order(1 "Agriculture" 2 "Manufacturing" 3 "Services") rows(3) position(1) ring(0) region(lstyle(black)))
			xlabel(1950(5)2000, angle(45))
			ytitle("Share of Total Value Added")
			ylabel(0(0.1)0.8)
			xtitle("")
			xsize(8) ysize(5)
			ylabel(, grid gmax glpattern(solid) glcolor(gs15))		
			graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../../analysis/output/10sd_va_sh.png", as(png) replace






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
	replace log_pop_1950 		= log_pop_1950[_n-1] 	 if log_pop_1950 == .
}

foreach year in 1940 1950 1960 1970 1980 1990 2000 {
		gen X_CV_`year'_illit_share_1950 	= illit_share_1950*(year == `year')
		gen X_CV_`year'_urb_share_1950 		= urb_share_1950*(year == `year')
		gen X_CV_`year'_log_pop_1950 		= log_pop_1950*(year == `year')
}

* dummies for year
tab year, gen(d_year_)	
foreach var of varlist manufac_share agri_share serv_share log_pop log_urb ///
	log_rur urb_share rur_share log_va_agri log_va_manufac log_va_serv log_va_total ///
	va_agri_share va_manufac_share va_serv_share{
		egen X_`var'_1960 = min(cond(year==1960,`var', ., .)), by(amc)
		foreach var2 of varlist d_year_* {
			gen X_`var'_`var2' = X_`var'_1960 * `var2'
	}
}


* For DiD *
egen asinh_cap_med = median(asinh_cap)
egen asinh_alt_med = median(asinh_alt)

xtile asinh_cap_pc = asinh_cap, nquantiles(4)
xtile asinh_alt_pc = asinh_alt, nquantiles(4)

gen d_alt_med = 0
gen d_alt_75  = 0
replace d_alt_med 	= 1 if asinh_alt_pc 	>= 3
replace d_alt_75 	= 1 if asinh_alt_pc 	== 4

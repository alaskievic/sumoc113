clear all



use "../raw/nber/wtf00.dta", clear
forvalues i = 62/99{
	append using "../raw/nber/wtf`i'.dta"
}

keep if exporter == "Brazil"
keep if importer == "World"

preserve
collapse (sum) value, by(ecode year)
rename value total_exp
gsort year ecode
tempfile exp_total
save "`exp_total'"
restore

* Agriculture
preserve
	gen sitc2 = substr(sitc4, 1, 2)

	keep if sitc2 == "00" | sitc2 == "01"  | sitc2 == "02" | ///
	sitc2 == "03" | sitc2 == "04"  | sitc2 == "05" | ///
	sitc2 == "06" | sitc2 == "07"  | sitc2 == "08" | ///
	sitc2 == "09" | sitc2 == "12"  | sitc2 == "21" | ///
	sitc2 == "22" | sitc2 == "23"  | sitc2 == "24" | ///
	sitc2 == "25" | sitc2 == "26"  | sitc2 == "29" | ///
	sitc2 == "41" | sitc2 == "42"

	collapse (sum) value, by(ecode year)
	rename value exp_agri_v
	gsort year ecode
	tempfile exp_agri
	save "`exp_agri'"
	restore

	* Minerals *
	preserve
	gen sitc1 = substr(sitc4, 1, 1)
	gen sitc2 = substr(sitc4, 1, 2)

	keep if sitc2 == "27" | sitc2 == "28"  | sitc2 == "32" | ///
			sitc2 == "33" | sitc2 == "34"  | sitc2 == "35"

	collapse (sum) value, by(ecode year)
	rename value exp_mineral_v
	gsort year ecode
	tempfile exp_mineral
	save "`exp_mineral'"
	restore

	* Other *
	preserve
	gen sitc1 = substr(sitc4, 1, 1)
	keep if sitc1 == "9"
	collapse (sum) value, by(ecode year)
	rename value exp_other_v
	tempfile exp_other
	save "`exp_other'"
	restore
	
	* Manufactuirng by Sector
	preserve
	gen sitc1 = substr(sitc4, 1, 1)
	gen sitc2 = substr(sitc4, 1, 2)

	keep if sitc2 == "11" | sitc2 == "43"  | sitc1 == "5" | ///
	sitc1 == "6" | sitc1 == "7"  | sitc1 == "8"
	
	collapse (sum) value, by(ecode year sitc1)

	gen exp_beverage = .
	replace exp_beverage = value if sitc1 == "1"
	
	gen exp_other_1 = .
	replace exp_other_1 = value if sitc1 == "4"
	
	gen exp_chemical = .
	replace exp_chemical = value if sitc1 == "5"
	
	gen exp_mineral_vegetable_manufac = .
	replace exp_mineral_vegetable_manufac = value if sitc1 == "6"
	
	gen exp_heavy = .
	replace exp_heavy = value if sitc1 == "7"
	
	gen exp_other_2 = . 
	replace exp_other_2 = value if sitc1 == "8"
	
	gsort year sitc1
	
	foreach v of varlist exp_beverage-exp_other_2 {
		forvalues i = 1/100 {
			bysort year: replace `v' = `v'[_n-`i'] if `v' == .
			bysort year: replace `v' = `v'[_n+`i'] if `v' == .
		}
	}
	
	duplicates drop year, force
	drop sitc1 value
	
	gen exp_other_ind     = exp_other_1 + exp_other_2
	gen exp_light_ind 	  = exp_beverage + exp_mineral_vegetable_manufac
	gen exp_heavy_ind 	  = exp_chemical + exp_heavy
	
	keep year ecode exp_other_ind exp_light_ind exp_heavy_ind
	tempfile exp_manufac_sector
	save "`exp_manufac_sector'"
	restore
	
	* Manufacturing Total *
	gen sitc1 = substr(sitc4, 1, 1)
	gen sitc2 = substr(sitc4, 1, 2)

	keep if sitc2 == "11" | sitc2 == "43"  | sitc1 == "5" | ///
	sitc1 == "6" | sitc1 == "7"  | sitc1 == "8"

	collapse (sum) value, by(ecode year)
	rename value exp_manufac_v

	* Merge with sectoral exports
	merge 1:1 ecode year using "`exp_total'", nogen
	merge 1:1 ecode year using "`exp_manufac_sector'", nogen
	merge 1:1 ecode year using "`exp_agri'", nogen
	merge 1:1 ecode year using "`exp_mineral'", nogen
	merge 1:1 ecode year using "`exp_other'", nogen

	gsort year

	
gen trade_manufac_sh 	= 	exp_manufac_v/total_exp
gen trade_agri_sh 		=   exp_agri/total_exp
gen trade_mineral_sh 	=   exp_mineral/total_exp
gen trade_other_sh 		=   exp_other_v/total_exp

gen manufac_light_sh = exp_light_ind/exp_manufac_v
gen manufac_heavy_sh = exp_heavy_ind/exp_manufac_v
gen manufac_other_sh = exp_other_ind/exp_manufac_v
drop ecode



#delimit;
	twoway (line trade_agri_sh year, lpattern(solid) lwidth(0.5))	
	       (line trade_manufac_sh year, lpattern(solid) lwidth(0.5))	
           (line trade_mineral_sh year, lpattern(solid) lwidth(0.5)),	
			legend(order(1 "Agriculture" 2 "Manufacturing" 3 "Minerals") rows(3) position(1) ring(0) region(lstyle(black)))
			xlabel(1960(5)2000, angle(45))
			ytitle("Share of Total Export Value")
			ylabel(0(0.2)1)
			xtitle("")
			xsize(8) ysize(5)
			ylabel(, grid gmax glpattern(solid) glcolor(gs15))		
			graphregion(fcolor(white) lstyle(none) ilstyle(none) 											
			lpattern(blank) ilpattern(blank)) plotregion(style(none));
#delimit cr
graph export "../../analysis/output/nber_exp_sh.png", as(png) replace


save "../output/nber_rca.dta", replace
	  
	  
	  
	  
	  
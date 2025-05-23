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
gen foreign_share_1940 		= .
replace foreign_share 		= foreign_tot/poptot 		if year == 1950
replace foreign_share_1940 	= foreign_tot/poptot 		if year == 1940

* Define some controls
gen illit_share_1950 		= .
gen urb_share_1950   		= .
gen log_pop_1950			= .
replace illit_share_1950 	= total_illiterat/poptot 	if year == 1950
replace urb_share_1950 		= popurb/poptot 			if year == 1950
replace log_pop_1950 		= log(poptot) 				if year == 1950

gen log_rail_dist 		= log(rail_dist)
gen log_road_dist 		= log(road_dist)
gen log_port_dist 		= log(port_dist)
gen log_capital_dist 	= log(capital_dist) 

* Region fixed effects
gen d_region = .
replace d_region = 1 if uf_amc <= 2  | uf_amc == 21
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
foreach v of varlist foreign_share capital_app alt log_cap illit_share_1950 urb_share_1950 ///
					 asinh_cap asinh_alt asinh_alt_pp asinh_alt_pw log_pop_1950 foreign_share_1940 {
		foreach x in 1/20{
				replace `v' = `v'[_n-1]    if `v' == .
		}		 	
}






local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg agri_share_dshort asinh_alt, vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt `c1list', vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt `c2list', vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 agri_share_dshort (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) replace f noobs noabbrev varlabels(asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dshort asinh_alt, vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt `c1list', vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt `c2list', vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 manufac_share_dshort (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noobs noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1950-1970)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dshort asinh_alt, vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt `c1list', vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt `c2list', vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 serv_share_dshort (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noobs noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dshort asinh_alt, vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt `c1list', vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt `c2list', vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 log_pop_dshort (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noobs noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1950-1970)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dshort asinh_alt, vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt `c1list', vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt `c2list', vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 urb_share_dshort (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c3list' (asinh_alt = foreign_share_1940), cluster (amc)

esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel E.} & \multicolumn{8}{c}{$\Delta$ Urban Population Shares (1950-1970)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")






local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg agri_share_dlong asinh_alt, vce (cluster amc)
eststo: qui reg agri_share_dlong asinh_alt `c1list', vce (cluster amc)
eststo: qui reg agri_share_dlong asinh_alt `c2list', vce (cluster amc)
eststo: qui reg agri_share_dlong asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 agri_share_dlong (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlong `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlong `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlong `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) replace f noobs noabbrev varlabels(asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1970-2000)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dlong asinh_alt, vce (cluster amc)
eststo: qui reg manufac_share_dlong asinh_alt `c1list', vce (cluster amc)
eststo: qui reg manufac_share_dlong asinh_alt `c2list', vce (cluster amc)
eststo: qui reg manufac_share_dlong asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 manufac_share_dlong (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlong `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlong `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlong `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noobs noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1970-2000)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dlong  asinh_alt, vce (cluster amc)
eststo: qui reg serv_share_dlong  asinh_alt `c1list', vce (cluster amc)
eststo: qui reg serv_share_dlong  asinh_alt `c2list', vce (cluster amc)
eststo: qui reg serv_share_dlong  asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 serv_share_dlong  (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlong  `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlong  `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlong  `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noobs noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1970-2000)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dlong  asinh_alt, vce (cluster amc)
eststo: qui reg log_pop_dlong  asinh_alt `c1list', vce (cluster amc)
eststo: qui reg log_pop_dlong  asinh_alt `c2list', vce (cluster amc)
eststo: qui reg log_pop_dlong  asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 log_pop_dlong  (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlong  `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlong  `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlong  `c3list' (asinh_alt = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noobs noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1970-2000)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dlong  asinh_alt, vce (cluster amc)
eststo: qui reg urb_share_dlong  asinh_alt `c1list', vce (cluster amc)
eststo: qui reg urb_share_dlong  asinh_alt `c2list', vce (cluster amc)
eststo: qui reg urb_share_dlong  asinh_alt `c3list', vce (cluster amc)
eststo: qui ivreg2 urb_share_dlong  (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlong  `c1list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlong  `c2list' (asinh_alt = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlong  `c3list' (asinh_alt = foreign_share_1940), cluster (amc)

esttab * using "../output/dshort_baseline.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt) append f noabbrev varlabels (asinh_alt "$asinh(FDI)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel E.} & \multicolumn{8}{c}{$\Delta$ Urban Population Shares (1970-2000)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
* Per Worker Short *

local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg agri_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg agri_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 agri_share_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 manufac_share_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1950-1970)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg serv_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 serv_share_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_pop_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_pop_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1950-1970)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg urb_share_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 urb_share_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)

esttab * using "../output/dshort_baseline_pw.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel E.} & \multicolumn{8}{c}{$\Delta$ Urban Population Shares (1950-1970)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")





	
	
	
	
	
*** Per worker - Long ***
	
local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg agri_share_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg agri_share_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg agri_share_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg agri_share_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 agri_share_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1970-2000)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg manufac_share_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg manufac_share_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg manufac_share_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 manufac_share_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1970-2000)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg serv_share_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg serv_share_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg serv_share_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 serv_share_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1970-2000)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_pop_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_pop_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_pop_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_pop_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1970-2000)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg urb_share_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg urb_share_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg urb_share_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 urb_share_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)

esttab * using "../output/dlong_baseline_pw.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel E.} & \multicolumn{8}{c}{$\Delta$ Urban Population Shares (1970-2000)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
	
	
	
	
	
	
	
	
*** Per worker - Longest ***

	
local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg agri_share_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg agri_share_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg agri_share_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg agri_share_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 agri_share_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 agri_share_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1950-2000)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg manufac_share_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg manufac_share_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg manufac_share_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 manufac_share_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 manufac_share_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1950-2000)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg serv_share_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg serv_share_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg serv_share_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 serv_share_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 serv_share_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1950-2000)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_pop_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_pop_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_pop_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_pop_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_pop_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_baseline_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1950-2000)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg urb_share_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg urb_share_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg urb_share_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 urb_share_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 urb_share_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)

esttab * using "../output/dlongest_baseline_pw.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel E.} & \multicolumn{8}{c}{$\Delta$ Urban Population Shares (1950-2000)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")	
	
	
	
	
	

	
	

	
	
	
	
	
	
* Per Worker Short Log Employment *
local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg log_agri_emp_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_agri_emp_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_agri_emp_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_agri_emp_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_agri_emp_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Agriculture (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg log_manufac_emp_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_manufac_emp_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_manufac_emp_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_manufac_emp_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_manufac_emp_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Manufacturing (1950-1970)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg log_serv_emp_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_serv_emp_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_serv_emp_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_serv_emp_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_serv_emp_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dshort_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Services (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

	
	
eststo clear
eststo: qui reg log_tot_emp_dshort asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_tot_emp_dshort asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_tot_emp_dshort asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_tot_emp_dshort asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_tot_emp_dshort (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dshort `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dshort `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dshort `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)

esttab * using "../output/dshort_logemp_pw.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Employment (1950-1970)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
	
	
	
	
	
	
	
	
* Per Worker Long Log Employment *
local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg log_agri_emp_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_agri_emp_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_agri_emp_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_agri_emp_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_agri_emp_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Agriculture (1970-2000)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg log_manufac_emp_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_manufac_emp_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_manufac_emp_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_manufac_emp_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_manufac_emp_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Manufacturing (1970-2000)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg log_serv_emp_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_serv_emp_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_serv_emp_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_serv_emp_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_serv_emp_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlong_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Services (1970-2000)}\\" "\noalign{\vskip 0.1cm}")

	
	
eststo clear
eststo: qui reg log_tot_emp_dlong asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_tot_emp_dlong asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_tot_emp_dlong asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_tot_emp_dlong asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_tot_emp_dlong (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dlong `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dlong `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dlong `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)

esttab * using "../output/dlong_logemp_pw.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Employment (1970-2000)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
	
	
	

	
	
	
* Per Worker Longest Log Employment *
local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 log_rail_dist ///
						  log_road_dist log_port_dist log_capital_dist i.d_region

eststo clear
eststo: qui reg log_agri_emp_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_agri_emp_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_agri_emp_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_agri_emp_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_agri_emp_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_agri_emp_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Agriculture (1950-2000)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg log_manufac_emp_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_manufac_emp_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_manufac_emp_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_manufac_emp_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_manufac_emp_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_manufac_emp_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Manufacturing (1950-2000)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg log_serv_emp_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_serv_emp_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_serv_emp_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_serv_emp_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_serv_emp_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_serv_emp_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)


esttab * using "../output/dlongest_logemp_pw.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Log Employment in Services (1950-2000)}\\" "\noalign{\vskip 0.1cm}")

	
	
eststo clear
eststo: qui reg log_tot_emp_dlongest asinh_alt_pw, vce (cluster amc)
eststo: qui reg log_tot_emp_dlongest asinh_alt_pw `c1list', vce (cluster amc)
eststo: qui reg log_tot_emp_dlongest asinh_alt_pw `c2list', vce (cluster amc)
eststo: qui reg log_tot_emp_dlongest asinh_alt_pw `c3list', vce (cluster amc)
eststo: qui ivreg2 log_tot_emp_dlongest (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dlongest `c1list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dlongest `c2list' (asinh_alt_pw = foreign_share_1940), cluster (amc)
eststo: qui ivreg2 log_tot_emp_dlongest `c3list' (asinh_alt_pw = foreign_share_1940), cluster (amc)

esttab * using "../output/dlongest_logemp_pw.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI \,\, \text{per Worker})$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Employment (1950-2000)}\\" "\noalign{\vskip 0.1cm}") ///
	prefoot("\noalign{\vskip 0.3cm}" "\hline" "\noalign{\vskip 0.1cm}" ///
	"Baseline Controls & & \multicolumn{1}{c}{\checkmark}& \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Market Access Controls & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark} & & & \multicolumn{1}{c}{\checkmark} & \multicolumn{1}{c}{\checkmark}\\" ///
	"Region FE & & & & \multicolumn{1}{c}{\checkmark} & & & & \multicolumn{1}{c}{\checkmark}\\") ///
	postfoot("\hline" "\end{tabular}" "\end{table}")
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

	
	
	
	
	






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













*** Micro Region ***
clear all

* Load Panel Micro Region dataset
use "../../data/output/micro_panel_1950.dta", clear	

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
replace d_region = 1 if state_code <= 20
replace d_region = 2 if state_code >= 21 & state_code <= 30
replace d_region = 3 if state_code >= 31 & state_code <= 35
replace d_region = 4 if state_code >= 41 & state_code <= 43
replace d_region = 5 if state_code >= 50 & state_code <= 53

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
	gen `v'_dshort			= `v' - `v'[_n-2] if year == 1970 & codmicro == codmicro[_n-1]
}

* Change between 1970 and 2000
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share{
	gen `v'_dlong			= `v' - `v'[_n-6] if year == 2000 & codmicro == codmicro[_n-1]
}

* Change between 1950 and 2000
foreach v of varlist agri_share manufac_share serv_share va_agri_share va_manufac_share ///
					 va_serv_share log_va_agri log_va_manufac log_va_serv log_va_total ///
					 log_pop log_urb log_rur urb_share rur_share{
	gen `v'_dlongest			= `v' - `v'[_n-8] if year == 2000 & codmicro == codmicro[_n-1]
}

* Arrange variables of 1950
foreach v of varlist foreign_share capital_app alt log_cap illit_share_1950 urb_share_1950 ///
					 asinh_cap asinh_alt asinh_alt_pp asinh_alt_pw log_pop_1950 {
			replace `v' = 0 if `v' == .
			foreach x in 1/20{
				replace `v' = `v'[_n-1]    if `v' == 0
		}		 	
}




local c1list `c1list' urb_share_1950 illit_share_1950 log_pop_1950

local c2list `c2list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital

local c3list `c3list' urb_share_1950 illit_share_1950 log_pop_1950 rail_dist ///
						  road_dist port_dist d_capital i.d_region

eststo clear
eststo: qui reg agri_share_dshort asinh_alt_pw, vce (cluster codmicro)
eststo: qui reg agri_share_dshort asinh_alt_pw `c1list', vce (cluster codmicro)
eststo: qui reg agri_share_dshort asinh_alt_pw `c2list', vce (cluster codmicro)
eststo: qui reg agri_share_dshort asinh_alt_pw `c3list', vce (cluster codmicro)
eststo: qui ivreg2 agri_share_dshort (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 agri_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 agri_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 agri_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (codmicro)


esttab * using "../output/dshort_baseline_micro.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) replace f noobs noabbrev varlabels(asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel A.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Agriculture (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

eststo clear
eststo: qui reg manufac_share_dshort asinh_alt_pw, vce (cluster codmicro)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c1list', vce (cluster codmicro)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c2list', vce (cluster codmicro)
eststo: qui reg manufac_share_dshort asinh_alt_pw `c3list', vce (cluster codmicro)
eststo: qui ivreg2 manufac_share_dshort (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 manufac_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 manufac_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 manufac_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (codmicro)


esttab * using "../output/dshort_baseline_micro.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel B.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Manufacturing (1950-1970)}\\" "\noalign{\vskip 0.1cm}")


eststo clear
eststo: qui reg serv_share_dshort asinh_alt_pw, vce (cluster codmicro)
eststo: qui reg serv_share_dshort asinh_alt_pw `c1list', vce (cluster codmicro)
eststo: qui reg serv_share_dshort asinh_alt_pw `c2list', vce (cluster codmicro)
eststo: qui reg serv_share_dshort asinh_alt_pw `c3list', vce (cluster codmicro)
eststo: qui ivreg2 serv_share_dshort (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 serv_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 serv_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 serv_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (codmicro)


esttab * using "../output/dshort_baseline_micro.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel C.} & \multicolumn{8}{c}{$\Delta$ Employment Share in Services (1950-1970)}\\" "\noalign{\vskip 0.1cm}")

	
eststo clear
eststo: qui reg log_pop_dshort asinh_alt_pw, vce (cluster codmicro)
eststo: qui reg log_pop_dshort asinh_alt_pw `c1list', vce (cluster codmicro)
eststo: qui reg log_pop_dshort asinh_alt_pw `c2list', vce (cluster codmicro)
eststo: qui reg log_pop_dshort asinh_alt_pw `c3list', vce (cluster codmicro)
eststo: qui ivreg2 log_pop_dshort (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 log_pop_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 log_pop_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 log_pop_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (codmicro)


esttab * using "../output/dshort_baseline_micro.tex", style(tex) label stats(r2_a widstat, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noobs noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
	posthead("\noalign{\vskip 0.1cm}" "\textbf{Panel D.} & \multicolumn{8}{c}{$\Delta$ Log Total Population (1950-1970)}\\" "\noalign{\vskip 0.1cm}")
	
	
eststo clear
eststo: qui reg urb_share_dshort asinh_alt_pw, vce (cluster codmicro)
eststo: qui reg urb_share_dshort asinh_alt_pw `c1list', vce (cluster codmicro)
eststo: qui reg urb_share_dshort asinh_alt_pw `c2list', vce (cluster codmicro)
eststo: qui reg urb_share_dshort asinh_alt_pw `c3list', vce (cluster codmicro)
eststo: qui ivreg2 urb_share_dshort (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 urb_share_dshort `c1list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 urb_share_dshort `c2list' (asinh_alt_pw = foreign_share), cluster (codmicro)
eststo: qui ivreg2 urb_share_dshort `c3list' (asinh_alt_pw = foreign_share), cluster (codmicro)

esttab * using "../output/dshort_baseline_micro.tex", style(tex) label stats(r2_a widstat N, fmt(%9.3f %9.0g) labels("Adj. $ R^{2} $ or K-P F" "Adj. $ R^{2} $ or K-P F" "Observations")) notype cells((b(star fmt(%9.3f))) (se(fmt(%9.3f)par))) keep(asinh_alt_pw) append f noabbrev varlabels (asinh_alt_pw "$asinh(FDI per Worker)$") starlevels(* 0.10 ** 0.05 *** 0.01) collabels(none) eqlabels(none) mlabels(none) mgroups(none) nolines  ///
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
 


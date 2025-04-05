clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel.dta", clear	

* Define treatment variable
gen log_cap 	= log(capital_app + 1)
gen asinh_cap 	= asinh(capital_app)

* Alternative *
gen alt		  = capital_app
replace alt   = 0 if capital_app < 5000
gen asinh_alt = asinh(alt)


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
	replace log_pop_1950 		= log_pop_1950[_n-1] 	 if log_pop_1950 == .
}


gsort -va_manufac_share_dshort



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
foreach v in log_va_agri_dlong log_va_manufac_dlong log_va_serv_dlong log_va_total_dlong{
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






program mun_long_diff
	use "../../data/output/panel_mun_1872_1950.dta", clear	
	*egen share_tr_mean = mean(share_tr) 
	*egen share_tr_sd  = sd(share_tr)
	*gen  share_tr_std = (share_tr - share_tr_mean) / share_tr_sd
	
	gen log_fmm = log(fmm_hist_port_cost + 0.01)
	gen dp = 1/(fmm_hist_port_cost + 0.01)
	gen dp_coffee = 1/(fmm_coffee_port_cost + 0.01)
	
	
	gen dp_1950 = dp if year == 1950 & mun_cod == mun_cod[_n-1]
	
	gen dummy_tr = share_tr >= 0.25
	gen dummy_red = share_red >= 0.25

	
	gen tr_dp  = dp*share_tr
	gen red_dp = dp*share_red
	
	gen tr_dp_coffee  = dp_coffee*share_tr
	gen red_dp_coffee = dp_coffee*share_red
	
	gen dummy_tr_dp  = dummy_tr*dp
	gen dummy_red_dp = dummy_red*dp
	
	* controls
	gen pop_dens = total_pop/total_area
	foreach var of varlist manufac_emp_share total_pop total_emp total_foreign foreign_pop_share ///
						  agri_emp manufac_emp service_emp agri_emp_share service_emp_share ///
						  pop_dens coffee_world_exp coffee_br_exp coffee_row_exp ///
						  coffee_prod_br coffee_prod_row {
		gen  l`var' 		= log(`var')				
		egen l`var'_1872 	= max(cond(year == 1872, l`var', ., .)), by(mun_code)
	}
	
	gen larea_km2 = log(total_area)
	foreach v of varlist west larea_km2 capitals dport_min ltotal_emp_1872 ltotal_pop_1872 lagri_emp_1872 gaez_cocoa gaez_sugarcane gaez_rubber{
		egen X_CV_1872_`v' = max(cond(year == 1872, `v', ., .)), by(mun_code)
	}
	
	* Generate long differences
	gsort mun_code year
	
	gen tr_dp_d1920 		= tr_dp  - tr_dp[_n-7] 					if year == 1920 & mun_cod == mun_cod[_n-1]
	gen red_dp_d1920 		= red_dp - red_dp[_n-7] 				if year == 1920 & mun_cod == mun_cod[_n-1]
	gen tr_coffee_d1920 	= tr_dp_coffee  - tr_dp_coffee[_n-7] 	if year == 1920 & mun_cod == mun_cod[_n-1]
	gen red_coffee_d1920 	= red_dp_coffee - red_dp_coffee[_n-7] 	if year == 1920 & mun_cod == mun_cod[_n-1]
	
	
	
	gen tr_dp_d1950 		= tr_dp - tr_dp[_n-9] 					if year == 1950 & mun_cod == mun_cod[_n-1]
	gen red_dp_d1950 		= red_dp - red_dp[_n-9] 				if year == 1950 & mun_cod == mun_cod[_n-1]
	gen tr_coffee_d1950 	= tr_dp_coffee  - tr_dp_coffee[_n-9] 	if year == 1950 & mun_cod == mun_cod[_n-1]
	gen red_coffee_d1950 	= red_dp_coffee - red_dp_coffee[_n-9] 	if year == 1950 & mun_cod == mun_cod[_n-1]
	
	
	bysort mun_code (year): replace red_dp_d1950 = red_dp_d1950[_n+1] if missing(red_dp_d1950)

	
	
	
	
	gen dummy_tr_dp_d1920 	= dummy_tr_dp  - dummy_tr_dp[_n-7] 	if year == 1920 & mun_cod == mun_cod[_n-1]
	gen dummy_red_dp_d1920 	= dummy_red_dp - dummy_red_dp[_n-7] if year == 1920 & mun_cod == mun_cod[_n-1]

	gen dummy_tr_dp_d1950 	= dummy_tr_dp - dummy_tr_dp[_n-9] 	if year == 1950 & mun_cod == mun_cod[_n-1]
	gen dummy_red_dp_d1950 	= dummy_red_dp - dummy_red_dp[_n-9] if year == 1950 & mun_cod == mun_cod[_n-1]
	
	
	
	
	foreach v of varlist manufac_emp_share agri_emp_share service_emp_share ltotal_pop ///
						 ltotal_foreign foreign_pop_share pop_dens coffee_world_exp ///
						 coffee_br_exp coffee_row_exp coffee_prod_br coffee_prod_row{
		gen d`v'_1920 = `v' - `v'[_n-5] if year == 1920 & mun_cod == mun_cod[_n-1]
	}
	foreach v of varlist lmanufac_emp_share lagri_emp_share lservice_emp_share ///
						 lforeign_pop_share lpop_dens lcoffee_world_exp lcoffee_br_exp ///
						 lcoffee_row_exp lcoffee_prod_br lcoffee_prod_row log_fmm{
		gen d`v'_1920 = `v' - `v'[_n-5] if year == 1920 & mun_cod == mun_cod[_n-1]
	}
	
	foreach v of varlist manufac_emp_share agri_emp_share service_emp_share ltotal_pop ///
						 ltotal_foreign foreign_pop_share pop_dens coffee_world_exp ///
						 coffee_br_exp coffee_row_exp coffee_prod_br coffee_prod_row ///
						 lmanufac_emp lagri_emp lservice_emp{
		gen d`v'_1950 = `v' - `v'[_n-8] if year == 1950 & mun_cod == mun_cod[_n-1]
	}
	foreach v of varlist lmanufac_emp_share lagri_emp_share lservice_emp_share ///
						 lforeign_pop_share lpop_dens lcoffee_world_exp lcoffee_br_exp ///
						 lcoffee_row_exp lcoffee_prod_br lcoffee_prod_row log_fmm{
		gen d`v'_1950 = `v' - `v'[_n-8] if year == 1950 & mun_cod == mun_cod[_n-1]
	}
	
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
	

************************************	
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dltotal_foreign_1950{
eststo: qui reg `v' tr_dp_d1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress
	

	
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dltotal_foreign_1950{
eststo: qui reg `v' tr_dp_d1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress	

	
	
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dltotal_foreign_1950{
eststo: qui reg `v' red_dp_d1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dltotal_foreign_1950{
eststo: qui reg `v' red_coffee_d1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_coffee_d1950) star(* 0.10 ** 0.05 *** 0.01) compress

	
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' red_dp_d1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress
	

	
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' red_dp_d1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress	

	

eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa  ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress



eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' tr_dp_d1950 i.state_code, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress

eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' tr_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress
	

	
	
	
*** Pure OLS ****
eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' share_red if year == 1872, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_red) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp if year == 1872, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp_coffee if year == 1872, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_coffee) star(* 0.10 ** 0.05 *** 0.01) compress





eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' share_red if year == 1920, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_red) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp if year == 1920, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp_coffee if year == 1920, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_coffee) star(* 0.10 ** 0.05 *** 0.01) compress





eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' share_red if year == 1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_red) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp if year == 1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp_coffee if year == 1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_coffee) star(* 0.10 ** 0.05 *** 0.01) compress



****** Level - Diff **********
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' share_red if year == 1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_red) star(* 0.10 ** 0.05 *** 0.01) compress

eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' red_dp if year == 1950, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp) star(* 0.10 ** 0.05 *** 0.01) compress


eststo clear
foreach v in manufac_emp_share agri_emp_share service_emp_share ltotal_pop ltotal_foreign{
eststo: qui reg `v' red_dp_d1950 if year == 1872, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress

	
	
	
*****************
	
	
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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
*** Controlling
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' dummy_tr_dp_d1950 dummy_tr dp, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dummy_tr_dp_d1950 dummy_tr dp) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' dummy_tr_dp_d1950 dummy_tr dp X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dummy_tr_dp_d1950 dummy_tr dp) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
eststo clear
foreach v in dmanufac_emp_share_1920 dagri_emp_share_1920 dservice_emp_share_1920 dltotal_pop_1920 dlforeign_pop_share_1920{
eststo: qui reg `v' tr_dp_d1920 , vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1920) star(* 0.10 ** 0.05 *** 0.01) compress
	

eststo clear
foreach v in dmanufac_emp_share_1920 dagri_emp_share_1920 dservice_emp_share_1920 dltotal_pop_1920 dlforeign_pop_share_1920{
eststo: qui reg `v' tr_dp_d1920 i.state_code, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1920) star(* 0.10 ** 0.05 *** 0.01) compress
	

eststo clear
foreach v in dltotal_pop_1920 dmanufac_emp_share_1920 dagri_emp_share_1920 dservice_emp_share_1920 dlforeign_pop_share_1920{
eststo: qui reg `v' tr_dp_d1920 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(tr_dp_d1920) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
	
	
	
	

	
	
	
	
	


eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' red_dp_d1950 , vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress
	

eststo clear
foreach v in dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dltotal_pop_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' red_dp_d1950 i.state_code, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress
	

eststo clear
foreach v in dltotal_pop_1950 dmanufac_emp_share_1950 dagri_emp_share_1950 dservice_emp_share_1950 dlforeign_pop_share_1950{
eststo: qui reg `v' red_dp_d1950 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
}
esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(red_dp_d1950) star(* 0.10 ** 0.05 *** 0.01) compress
	

	






program median_dummy
	egen med_share_tr 		= median(share_tr)
	gen dmed_share_tr 		= 0
	replace dmed_share_tr 	= 1 if share_tr > med_share_tr

	gen dshare_tr_10 = 0
	replace dshare_tr_10 = 1 if share_tr >= 0.1
	
	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' dmed_share_tr, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dmed_share_tr) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' dmed_share_tr i.state_code, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dmed_share_tr) star(* 0.10 ** 0.05 *** 0.01) compress
	

	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' dmed_share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dmed_share_tr) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
	
	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' dshare_tr_10, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dshare_tr_10) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' dshare_tr_10 i.state_code, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dshare_tr_10) star(* 0.10 ** 0.05 *** 0.01) compress
	

	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' dshare_tr_10 X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(dshare_tr_10) star(* 0.10 ** 0.05 *** 0.01) compress
end


program exclude_zero_terra_roxa
	drop if share_tr == 0
	
	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' share_tr, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_tr) star(* 0.10 ** 0.05 *** 0.01) compress
	
	
	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' share_tr i.state_code, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_tr) star(* 0.10 ** 0.05 *** 0.01) compress
	

	eststo clear
	foreach v in dltotal_pop_1950 dlmanufac_emp_share_1950 dlagri_emp_share_1950 dlservice_emp_share_1950 dlforeign_pop_share_1950{
	eststo: qui reg `v' share_tr X_CV_1872_west X_CV_1872_larea_km2 X_CV_1872_capitals ///
						X_CV_1872_dport_min X_CV_1872_ltotal_pop_1872 X_CV_1872_gaez_cocoa ///
						X_CV_1872_gaez_sugarcane X_CV_1872_gaez_rubber i.state_code, vce (cluster mun_code)
	}
	esttab, se(3) ar2 stat (r2_a N, fmt(%9.3f)) keep(share_tr) star(* 0.10 ** 0.05 *** 0.01) compress



end









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


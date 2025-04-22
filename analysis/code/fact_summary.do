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
foreach v of varlist foreign_share capital_app alt log_cap illit_share_1950 urb_share_1950 ///
					 asinh_cap asinh_alt asinh_alt_pp asinh_alt_pw log_pop_1950 {
		foreach x in 1/20{
				replace `v' = `v'[_n-1]    if `v' == .
		}		 	
}



*** Summary ***
keep if year == 1950 | year == 1970 | year == 2000


sort  year
by year: summarize agri_share manufac_share serv_share



keep if year == 1970
tabstat agri_share_dshort manufac_share_dshort serv_share_dshort log_pop_dshort ///
		urb_share_dshort log_va_total_dshort va_agri_share_dshort va_manufac_share_dshort va_serv_share_dshort, s(mean sd min max) format(%10.3fc)

keep if year == 2000
tabstat agri_share_dlong manufac_share_dlong serv_share_dlong log_pop_dlong ///
		urb_share_dlong log_va_total_dlong va_agri_share_dlong va_manufac_share_dlong va_serv_share_dlong, s(mean sd min max) format(%10.3fc)
		

tabstat agri_share_dlongest manufac_share_dlongest serv_share_dlongest log_pop_dlongest ///
		urb_share_dlongest log_va_total_dlongest va_agri_share_dlongest va_manufac_share_dlongest ///
		va_serv_share_dlongest, s(mean sd min max) format(%10.3fc)


 
keep if year == 1950
tabstat asinh_alt asinh_alt_pw urb_share illit_share_1950 foreign_share rail_dist ///
		road_dist port_dist capital_dist, s(mean sd min max) format(%10.3fc)
 
 
 
keep if year == 2000
tabstat agri_share manufac_share serv_share log_pop urb_share log_va_total va_agri_share ///
 va_manufac_share va_serv_share, s(mean sd min max) format(%10.3fc)

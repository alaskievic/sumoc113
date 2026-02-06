clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel_1950.dta", clear	

keep if year == 1950

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

replace asinh_alt    = 0 if asinh_alt == .
replace asinh_alt_pp = 0 if asinh_alt_pp == .
replace asinh_alt_pw = 0 if asinh_alt_pw == .


* Binary Treatment *
egen asing_alt_pp_med = median(asinh_alt_pp)
egen asing_alt_pw_med = median(asinh_alt_pw)

xtile asing_alt_pp_pc = asinh_alt_pp, nquantiles(4)
xtile asing_alt_pw_pc = asinh_alt_pw, nquantiles(4)

gen d_plus = 	0
replace d_plus = 1 if asinh_alt > 0

gen d_alt_med = 0
gen d_alt_75  = 0
replace d_alt_med 	= 1 if asing_alt_pp_pc 	>= 3
replace d_alt_75 	= 1 if asing_alt_pp_pc 	== 4



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

* Create covariates
gen log_pop_dens 		= log(poptot/area_amc_1950)
gen output_p_firm 		= log(value_prod/num_firm)
gen output_p_work		= log(value_prod/num_work)
gen foreign_share 		= foreign_tot/poptot
gen urban_share			= popurb/poptot
gen illit_share			= total_illiterat/poptot
gen log_horsepower		= log(horsepower)
gen va_agri_share		= gdp_agri/gdp_tot
gen va_manufac_share	= gdp_manufac/gdp_tot
gen va_serv_share		= gdp_serv/gdp_tot

gen log_rail_dist 		= log(rail_dist)
gen log_road_dist 		= log(road_dist)
gen log_port_dist 		= log(port_dist)
gen log_capital_dist 	= log(capital_dist)


foreach v of varlist log_pop_dens-log_capital_dist{
	egen `v'_std = std(`v')
}

foreach v of varlist log_pop_dens-log_capital_dist{
	su `v', meanonly 
	gen `v'_norm = (`v' - r(min)) / (r(max) - r(min))
}


local i = 0 
foreach v of varlist log_pop_dens_std-log_capital_dist_std{
	local i = `i'+1		
	reg  `v' asinh_alt_pp
	est store Loop1`i'
}



capture label var log_pop_dens_norm 	"Log Population Density"
capture label var output_p_firm_norm 	"Log Output per Firm"
capture label var output_p_work_norm 	"Log Output per Worker"
capture label var log_horsepower_norm 	"Log Horsepower"
capture label var foreign_share_norm 	"Foreign Population Share"
capture label var urban_share_norm 		"Urban Population Share"
capture label var illit_share_norm 		"Illiterate Population Share"
capture label var va_agri_share_norm 	"Agriculture VA Share"
capture label var va_manufac_share_norm "Manufacturing VA Share"
capture label var va_serv_share_norm 	"Services VA Share"

capture label var log_rail_dist_norm	"Distance to Railroad"
capture label var log_port_dist_norm	"Distance to Port"
capture label var log_capital_dist_norm	"Distance to State Capital"

gsort amc
gen id = _n

drop if amc == 7051
teffects nnmatch (agri_share log_pop_dens_norm urban_share_norm foreign_share_norm illit_share_norm  log_rail_dist_norm log_port_dist_norm log_capital_dist_norm output_p_work_norm ) ///
		 (d_plus), biasadj(log_pop_dens_norm urban_share_norm foreign_share_norm illit_share_norm log_rail_dist_norm log_port_dist_norm log_capital_dist_norm output_p_work_norm) generate(matchid)

		 
drop if amc == 7051
teffects psmatch (agri_share) (d_plus log_pop_dens_norm urban_share_norm foreign_share_norm illit_share_norm  log_rail_dist_norm log_port_dist_norm log_capital_dist_norm output_p_work_norm), generate(matchid)
		 

tebalance summarize
mat	balance = r(table)

coefplot (matrix(balance[,1])) (matrix(balance[,2])), xline(0)  xtitle("Standardized Difference") legend(order(2 "Raw Data (Unbalanced)" 4 "Matched (Propensity Score)") rows(7) position(11) ring(0) region(lstyle(black))) ///
			xlabel(-1 -0.75 -0.5 -0.25 0 0.25 0.5 0.75 1)

graph export "../output/std_diff_matchps_75.png", as(png) replace

			



gsort amc
replace matchid = matchid[_n+1] if matchid ==. & d_plus == 1




gsort id
keep id amc matchid1 d_plus final_name
keep if d_plus == 1
drop d_plus

merge m:1 matchid1 using "../output/1950_id.dta"
keep if _merge == 3
drop _merge

gsort amc amc_match

rename (amc amc_match) (amc_match amc)

save"../output/matched_id.dta", replace


gsort amc
gen dup = 0
replace dup = 1 if amc[_n] == amc[_n-1]

drop if dup == 1
drop dup

save"../output/matched_control.dta", replace



ttest log_pop_dens_norm, by(d_alt_75)


ttest log_pop_dens_norm, by(d_plus)           





* PS Matching  75 *
psmatch2 d_alt_75 log_pop_dens_norm urban_share_norm foreign_share_norm illit_share_norm  log_rail_dist_norm log_port_dist_norm log_capital_dist_norm output_p_work_norm

gen treat   = 1 if _treated == 1
keep amc final_name _id _pscore treat _id _n1

save "../output/to_match_ps_75.dta", replace


* Control *
keep if _n1 !=.
keep _n1
rename _n1 _id

gsort _id
gen dup = 0
replace dup = 1 if _id[_n] == _id[_n-1]

drop if dup == 1
drop dup

merge 1:1 _id using "../output/to_match_ps_75.dta"
keep if _merge == 3
keep amc _pscore
gen control = 1
save "../output/matched_control_ps_75.dta", replace



use "../output/to_match_ps_75.dta", clear
merge 1:1 amc using "../output/matched_control_ps_75.dta"

keep if treat != . | control != .
keep amc _pscore treat control

drop control
replace treat = 0 if treat == .
save"../output/matched_ps_75.dta", replace





* PS Matching  Plus *
psmatch2 d_plus log_pop_dens_norm urban_share_norm foreign_share_norm illit_share_norm  log_rail_dist_norm log_port_dist_norm log_capital_dist_norm output_p_work_norm

gen treat   = 1 if _treated == 1
keep amc final_name _id _pscore treat _id _n1

save "../output/to_match_ps_plus.dta", replace


* Control *
keep if _n1 !=.
keep _n1
rename _n1 _id

gsort _id
gen dup = 0
replace dup = 1 if _id[_n] == _id[_n-1]

drop if dup == 1
drop dup

merge 1:1 _id using "../output/to_match_ps_plus.dta"
keep if _merge == 3
keep amc _pscore
gen control = 1
save "../output/matched_control_ps_plus.dta", replace



use "../output/to_match_ps_plus.dta", clear
merge 1:1 amc using "../output/matched_control_ps_plus.dta"

keep if treat !=. | control != .
keep amc _pscore treat control

drop control
replace treat = 0 if treat == .
save"../output/matched_ps_plus.dta", replace

























* Load Panel AMC dataset
use "../../data/output/amc_panel_1940.dta", clear	

keep if year == 1950
gsort amc
gen matchid1 = _n

keep amc matchid1 final_name
rename (final_name amc) (final_name_match amc_match)

save "../output/1940_id.dta", replace




use "../../data/output/amc_panel_1950.dta", clear	

keep if year == 1950
gsort amc
gen matchid1 = _n

keep amc matchid1 final_name
rename (final_name amc) (final_name_match amc_match)

save "../output/1950_id.dta", replace

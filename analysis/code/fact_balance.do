clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel_1940.dta", clear	

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
gen log_pop_dens 		= log(poptot/area_amc_1940)
gen output_p_firm 		= log(value_prod/num_firm)
gen output_p_work		= log(value_prod/num_work)
gen foreign_share 		= foreign_tot/poptot
gen urban_share			= popurb/poptot
gen illit_share			= total_illiterat/poptot
gen log_horsepower		= log(horsepower)
gen va_agri_share		= gdp_agri/gdp_tot
gen va_manufac_share	= gdp_manufac/gdp_tot
gen va_serv_share		= gdp_serv/gdp_tot


foreach v of varlist log_pop_dens-va_serv_share{
	egen `v'_std = std(`v')
}

foreach v of varlist log_pop_dens-va_serv_share{
	su `v', meanonly 
	gen `v'_norm = (`v' - r(min)) / (r(max) - r(min))
}


local i = 0 
foreach v of varlist log_pop_dens_std-va_serv_share_std{
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

gsort amc
gen id = _n

teffects nnmatch (manufac_share log_pop_dens_norm urban_share_norm illit_share_norm va_agri_share_norm va_serv_share_norm) (d_plus), biasadj(log_pop_dens_norm urban_share_norm illit_share_norm va_agri_share_norm va_serv_share_norm) generate(matchid)

tebalance summarize	
mat	balance = r(table)
coefplot (matrix(balance[,1])) (matrix(balance[,2])), xline(0)  xtitle("Standardized Difference") legend(order(2 "Raw (unweighted)" 4 "NNM")) sort graphregion(margin(l+5))


gsort id
keep id amc matchid1 d_plus final_name
keep if d_plus == 1
drop d_plus

merge m:1 matchid1 using "../output/1940_id.dta"
keep if _merge == 3
drop _merge

gsort amc amc_match

rename (amc amc_match) (amc_match amc)


gsort amc
gen dup = 0
replace dup = 1 if amc[_n] == amc[_n-1]

drop if dup == 1
drop dup

save"../output/matched_id.dta", replace



clear all

* Load Panel AMC dataset
use "../../data/output/amc_panel_1940.dta", clear	

keep if year == 1950
gsort amc
gen matchid1 = _n

keep amc matchid1 final_name
rename (final_name amc) (final_name_match amc_match)

save "../output/1940_id.dta", replace


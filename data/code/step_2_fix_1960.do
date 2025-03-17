*************************************************************************************************************
*** Reading and Cleaning Manufacturing Variables at the Municipality Level in the 1960 Census ***************
*************************************************************************************************************

clear all

program clean_step_1

	* Renaming each variable
	rename (v1-v10) (mun_name emp_tot noemp_tot agri_emp noagri_emp manufac_emp ///
					 nomanufac_emp service_emp noservice_emp inactive)

	* Drop unecessary rows and columns
	keep mun_name-inactive

	* Remvoing all blank spaces
	foreach v of varlist mun_name-inactive{
		local type = substr("`: type `v''", 1, 3)
			if "`type'" == "str"{
				replace `v' = subinstr(`v', " ", "", .)
				replace `v' = subinstr(`v', "'", "", .)
				replace `v' = ustrto(ustrnormalize(`v', "nfd"), "ascii", 2)
		}
	}
	
	
	foreach v of varlist emp_tot-inactive{
			replace `v' = subinstr(`v', "I", "1", .)
			replace `v' = subinstr(`v', "S", "5", .)
			replace `v' = subinstr(`v', "R", "5", .)

	}
	
	* Destring
	destring emp_tot-inactive, replace force
	
	* Dropping unecessary rows
	drop if missing(mun_name)
	
	/*
	* Replace missing values with zero
	foreach v of varlist num_firm-transf_value{
		replace `v' = 0 if `v'==.
	}
	
	* Change formats for better visualization
	foreach v of varlist mun_name{
		format `v' %12s
	}
	*/
end

program  ibge_crosswalk_1960
	replace code2010 = 2605459 if code2010 == 2000107 /* Fernando de Noronha */
	replace code2010 = 5000203 if code2010 == 5100202 /* Agua Clara */
	replace code2010 = 5000609 if code2010 == 5100606 /* Amambai */
	replace code2010 = 5001003 if code2010 == 5101008 /* Aparecida do Taboado */
	replace code2010 = 5001102 if code2010 == 5101101 /* Aquidauana */
	replace code2010 = 5001904 if code2010 == 5101901 /* Bataguassu */
	replace code2010 = 5002100 if code2010 == 5102103 /* Bela Vista */
	replace code2010 = 5002209 if code2010 == 5102202 /* Bonito */
	replace code2010 = 5002407 if code2010 == 5102404 /* Caarapó */
	replace code2010 = 5002605 if code2010 == 5102602 /* Camapuã */
	replace code2010 = 5002704 if code2010 == 5102705 /* Campo Grande */
	replace code2010 = 5002902 if code2010 == 5102907 /* Cassilândia */
	replace code2010 = 5003108 if code2010 == 5103109 /* Corguinho */
	replace code2010 = 5003207 if code2010 == 5103206 /* Corumbá */
	replace code2010 = 5003306 if code2010 == 5103303 /* Coxim */
	replace code2010 = 5003702 if code2010 == 5103709 /* Dourados */
	replace code2010 = 5004106 if code2010 == 5104109 /* Guia Lopes da Laguna */
	replace code2010 = 5004403 if code2010 == 5104408 /* Inocência */
	replace code2010 = 5004502 if code2010 == 5104509  /* Itaporã */
	replace code2010 = 5004908 if code2010 == 5104909 /* Jaraguari */
	replace code2010 = 5005004 if code2010 == 5105007 /* Jardim */
	replace code2010 = 5005202 if code2010 == 5105201 /* Ladário */
	replace code2010 = 5005400 if code2010 == 5105401 /* Maracaju */
	replace code2010 = 5005608 if code2010 == 5105607 /* Miranda */
	replace code2010 = 5005806 if code2010 == 5105809 /* Nioaque */
	replace code2010 = 5006200 if code2010 == 5106207 /* Nova Andradina */
	replace code2010 = 5006309 if code2010 == 5106304 /* Paranaíba */
	replace code2010 = 5006606 if code2010 == 5106603 /* Ponta Porã */
	replace code2010 = 5006903 if code2010 == 5106902 /* Porto Murtinho */
	replace code2010 = 5007109 if code2010 == 5107100 /* Ribas do Rio Pardo */
	replace code2010 = 5007208 if code2010 == 5107209 /* Rio Brilhante */
	replace code2010 = 5007406 if code2010 == 5107403 /* Rio Verde de Mato Grosso */
	replace code2010 = 5007505 if code2010 == 5107506 /* Rochedo */
	replace code2010 = 5007901 if code2010 == 5107902 /* Sidrolândia */
	replace code2010 = 5008008 if code2010 == 5108009 /* Terenos */
	replace code2010 = 5008305 if code2010 == 5108304 /* Três Lagoas */
	* replace code2010 = 5100409 if code2010 == 5100202 /* Alto Garças */
	
	replace code2010 = 1700400 if code2010 == 5200407 /* Almas */
	replace code2010 = 1701903 if code2010 == 5201900 /* Araguacema */
	replace code2010 = 1702000 if code2010 == 5202007 /* Araguaçu */
	replace code2010 = 1702109 if code2010 == 5202106 /* Araguaína */
	replace code2010 = 1702208 if code2010 == 5202205 /* Araguatins */
	replace code2010 = 1702406 if code2010 == 5202403 /* Arraias */
	replace code2010 = 1703008 if code2010 == 5203005 /* Babaçulândia */
	replace code2010 = 1703701 if code2010 == 5203708 /* Brejinho de Nazaré */
	replace code2010 = 1706100 if code2010 == 5206107 /* Cristalândia */
	replace code2010 = 1707009 if code2010 == 5207006 /* Dianópolis */
	replace code2010 = 1707306 if code2010 == 5207303 /* Dueré */
	replace code2010 = 1707702 if code2010 == 5207709 /* Filadélfia */
	replace code2010 = 1709005 if code2010 == 5209002 /* Piacá */
	replace code2010 = 1709500 if code2010 == 5209507 /* Gurupi */
	replace code2010 = 1710508 if code2010 == 5210505 /* Itacajá */
	replace code2010 = 1710706 if code2010 == 5210703 /* Itaguatins */
	replace code2010 = 1712405 if code2010 == 5212402 /* Lizarda */
	replace code2010 = 1713205 if code2010 == 5213202 /* Miracema do Norte */
	replace code2010 = 1714203 if code2010 == 5214200 /* Natividade */
	replace code2010 = 1714302 if code2010 == 5214309 /* Nazaré */
	replace code2010 = 1715101 if code2010 == 5215108 /* Novo Acordo */
	replace code2010 = 1716208 if code2010 == 5216205 /* Paranã */
	replace code2010 = 1716505 if code2010 == 5216502 /* Pedro Afonso */
	replace code2010 = 1716604 if code2010 == 5216601 /* Peixe */
	replace code2010 = 1717503 if code2010 == 5217500 /* Pium */
	replace code2010 = 1717800 if code2010 == 5217807 /* Ponte Alta do Bom Jesus */
	replace code2010 = 1717909 if code2010 == 5217906 /* Ponte Alta do Norte */
	replace code2010 = 1718204 if code2010 == 5218201 /* Porto Nacional */
	replace code2010 = 1720903 if code2010 == 5220900 /* Taguatinga */
	replace code2010 = 1721109 if code2010 == 5221106 /* Tocantínia */
	replace code2010 = 1721208 if code2010 == 5221205 /* Tocantinópolis */
	replace code2010 = 1721257 if code2010 == 5209309 /* Tupirama */
	replace code2010 = 1721307 if code2010 == 5218409 /* Tupiratins */
	replace code2010 = 1722107 if code2010 == 5222104 /* Xambioá */
end




***************************
*** Rondônia  *************
***************************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/ro_1960_mun.csv", clear

keep in 4/5

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_ro_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_ro.dta", replace


*************
*** Acre  ***
*************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/ac_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_ac_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_ac.dta", replace


*****************
*** Amazonas  ***
*****************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/am_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_am_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_am.dta", replace


*****************************
*********** Roraima   *******
*****************************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/rr_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_rr_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_rr.dta", replace



*************
*** Pará  ***
*************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/pa_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_pa_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_pa.dta", replace



**************
*** Amapá  ***
**************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/ap_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_ap_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_ap.dta", replace


*****************
*** Maranhão  ***
*****************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/ma_1960_mun.csv", clear

drop in 1/4

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_ma_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_ma.dta", replace



**************
*** Piaui  ***
**************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/pi_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_pi_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_pi.dta", replace




******************
*** Guanabara  ***
******************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/gb_1960_mun.csv", clear

keep in 4

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_gb_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_gb.dta", replace


***********************
*** Espirito Santo  ***
***********************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/es_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_es_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_es.dta", replace


***********************
*** Santa Catarina  ***
***********************
*** Reading main data file ***
import delimited using ".././raw/census_demog_1960_2010/digitized_missing_1960/sc_1960_mun.csv", clear

drop in 1/3

* Apply cleaning code
clean_step_1

gen id_mun = _n

* Matching by order
merge 1:1 id_mun using ".././raw/census_demog_1960_2010/aux/mun_sc_order.dta", nogenerate

* Drop unnecessary
keep mun_name-aux_mun1 state_name mun1960 mun2010 codstate2010

drop noemp_tot noagri_emp nomanufac_emp noservice_emp inactive aux_mun aux_mun1

order code2010 mun1960 mun2010 state_name codstate2010

* Saving
save ".././output/aux/mun_1960_sc.dta", replace





*************************
*** Append all states ***
*************************
clear
foreach state in  "ac" "am" "ap" "ma" "pa" "pi" "ro" "rr" "sc" "gb" "es"{
	append using ".././output/aux/mun_1960_`state'.dta"
}

rename emp_tot emp_total

* Append rest
append using ".././output/censo_emp_shares_1960_part1.dta"

replace codstate2010 = state_code if codstate2010 == .
drop id_mun state_code

* Name replacement *
ibge_crosswalk_1960

drop *_share year

tempfile censo_1960
save "`censo_1960'"

* Merge Names
import excel ".././raw/amc_name_1872_2010.xls", clear first
keep code2010 mun1960 mun2010

* fix some names
replace mun1960 = "Salmourão" if code2010 == 3545100

drop if missing(mun1960)
drop if substr(mun1960, 1, 11) == "desmembrado"	
drop if substr(mun1960, 1, 7)  == "anexado"
drop if substr(mun1960, 1, 4)  == "sede"

merge 1:1 code2010 using `censo_1960', nogen

* drop ligitigo and alto alto garças
drop if mun1960 == "litígio MG/ES"
drop if mun1960 == "Alto Garças"

gsort codstate2010 mun1960
gen year = 1960

* Saving
save ".././output/empshares_mun_1960.dta", replace

/*
*********************************
*** Append at the state level ***
*********************************
clear
foreach state in  "ac" "al" "am" "ap" "ba" "ce" "df" "es" "go" "ma" "mg" "mt" ///
				  "pa" "pb" "pe" "pi" "pr" "rj" "rn" "ro" "rr" "rs" "sc" "se" "sp" {
	append using "../.././output/census_1960/manufac_tmp/state_`state'.dta"
}
	
order state_name
drop aux_mun mun_name

gen codstate2010 = .
replace codstate2010 = 12 if state_name == "Acre"
replace codstate2010 = 27 if state_name == "Alagoas"
replace codstate2010 = 13 if state_name == "Amazonas"
replace codstate2010 = 16 if state_name == "Amapa"
replace codstate2010 = 29 if state_name == "Bahia"
replace codstate2010 = 23 if state_name == "Ceara"
replace codstate2010 = 33 if state_name == "Distrito Federal"
replace codstate2010 = 32 if state_name == "Espirito Santo"
replace codstate2010 = 52 if state_name == "Goias"
replace codstate2010 = 21 if state_name == "Maranhao"
replace codstate2010 = 51 if state_name == "Mato Grosso"
replace codstate2010 = 31 if state_name == "Minas Gerais"
replace codstate2010 = 41 if state_name == "Parana"
replace codstate2010 = 25 if state_name == "Paraiba"
replace codstate2010 = 15 if state_name == "Para"
replace codstate2010 = 26 if state_name == "Pernambuco"
replace codstate2010 = 22 if state_name == "Piaui"
replace codstate2010 = 24 if state_name == "Rio Grande do Norte"
replace codstate2010 = 43 if state_name == "Rio Grande do Sul"
replace codstate2010 = 33 if state_name == "Rio de Janeiro"
replace codstate2010 = 11 if state_name == "Rondonia"
replace codstate2010 = 14 if state_name == "Roraima"
replace codstate2010 = 42 if state_name == "Santa Catarina"
replace codstate2010 = 28 if state_name == "Sergipe"
replace codstate2010 = 35 if state_name == "Sao Paulo"


* Assign 1960 state codes
gen codstate1960 = codstate2010

replace codstate1960 = 30 if state_name == "Distrito Federal"

* Label variables
rename state_name state1960

label variable state1960  				"State name in 1960"
label variable codstate2010 			"2010 IBGE state code"

* Saving
save "../.././output/census_1960/ind_state_1960.dta", replace
*/

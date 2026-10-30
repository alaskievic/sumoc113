clear

* Part 1 - Codex
import excel "../raw/sumoc113/I113 Parte 1_enriquecida.xlsx", first clear

keep(NNASUMOC INTERESSADO PAISDEORIGEN MESDALICENÇA EQUIVALENCIAEmUS1 MUNICÍPIOFÁBRICAHISTÓRICO ///
	 UFHISTÓRICA CONFIANÇAMUNICÍPIO SIC2DÍGITOS SETORSIC TIPODELOCAL )

rename(NNASUMOC-TIPODELOCAL) (n_sumoc company country_origin country_origin_2 value_usd mun_name ///
							  state_name match_score sic_code sic_name type_place)

* Remvoing all blank spaces
foreach v of varlist n_sumoc-type_place{
	replace `v' = ustrto(ustrnormalize(`v', "nfd"), "ascii", 2)
	replace `v' = strltrim(`v')
	format `v' %12s
}

* Clean values
replace value_usd     = subinstr(value_usd, ".", "", .)
replace value_usd 	  = subinstr(value_usd, ",", ".", .)
replace value_usd 	  = subinstr(value_usd, "US$", "", .)
replace value_usd 	  = subinstr(value_usd, " ", "", .)

destring value_usd, force replace

* Clean foreign and local firm name
forvalues i = 1/10 {
	replace n_sumoc = n_sumoc[_n-1] if missing(n_sumoc)
}
replace n_sumoc = subinstr(n_sumoc, "*", "", .)
destring n_sumoc, force replace
drop if n_sumoc == .

replace company = subinstr(company, " ", "", .)
gen company_for = company if substr(company, 1, 2) == "a)"
gen company_br  = company if substr(company, 1, 2) == "b)" | substr(company, 1, 4) == "Idem"

forvalues i = 1/10 {
	replace company_for = company_for[_n-1] if missing(company_for) & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_br[_n+1]  if missing(company_br)  & n_sumoc == n_sumoc[_n+1]
	replace company_br  = company_br[_n-1]  if company_br == "Idem" & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_for 		if company_br == "b)Idem"
}

drop if substr(company, 1, 4) == "TOTA"
order company_for company_br  
format company_for company_br %12s

preserve
* Prepare for matching
keep if mun_name != ""
gsort n_sumoc

destring match_score sic_code, force replace
replace country_origin = country_origin_2 if n_sumoc >= 226
drop country_origin_2

keep if mun_name != ""
tempfile to_match_codex_1
save "`to_match_codex_1'"
restore

* Collapse licenses
collapse (sum) value_usd, by(n_sumoc)
replace value_usd = value_usd/1000000

merge 1:1 n_sumoc using "`to_match_codex_1'", nogen

* Final clean
drop company
gsort n_sumoc

save "../output/sumoc113_codex_part1.dta", replace




* Part 2 - Codex
import excel "../raw/sumoc113/I113 Parte 2_enriquecida.xlsx", first clear

keep(NNASUMOC aInvestidorbBenficiado RamoDeAplicaçã PaísdeOrigem ///
	 EquivalenciaEmUs MUNICÍPIOFÁBRICAHISTÓRICO UFHISTÓRICA CONFIANÇAMUNICÍPIO SIC2DÍGITOS ///
	 SETORSIC TIPODELOCAL)

rename(NNASUMOC-TIPODELOCAL) (n_sumoc company sector country_origin value_usd mun_name ///
							  state_name match_score sic_code sic_name type_place)

* Remvoing all blank spaces
foreach v of varlist n_sumoc-type_place{
	replace `v' = ustrto(ustrnormalize(`v', "nfd"), "ascii", 2)
	replace `v' = strltrim(`v')
	format `v' %12s
}

* Clean values
replace value_usd     = subinstr(value_usd, ".", "", .)
replace value_usd 	  = subinstr(value_usd, ",", ".", .)
replace value_usd 	  = subinstr(value_usd, "US$", "", .)
replace value_usd 	  = subinstr(value_usd, " ", "", .)

destring value_usd, force replace

* Clean foreign and local firm name
forvalues i = 1/10 {
	replace n_sumoc = n_sumoc[_n-1] if missing(n_sumoc)
}
replace n_sumoc = subinstr(n_sumoc, "*", "", .)
destring n_sumoc, force replace
drop if n_sumoc == .

replace company = subinstr(company, " ", "", .)
gen company_for = company if substr(company, 1, 2) == "a)"
gen company_br  = company if substr(company, 1, 2) == "b)" | substr(company, 1, 4) == "Idem"

replace company_for = company if mun_name != ""
replace company_br	= company if mun_name == ""


forvalues i = 1/10 {
	replace company_for = company_for[_n-1] if missing(company_for) & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_br[_n+1]  if missing(company_br)  & n_sumoc == n_sumoc[_n+1]
	replace company_br  = company_br[_n-1]  if missing(company_br)  & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_br[_n-1]  if company_br == "Idem" & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_for 		if company_br == "b)Idem"
}


drop if substr(company, 1, 4) == "TOTA"
order company_for company_br  
format company_for company_br %12s

preserve
* Prepare for matching
keep if mun_name != ""
gsort n_sumoc

destring match_score sic_code, force replace
keep if mun_name != ""
tempfile to_match_codex_2
save "`to_match_codex_2'"
restore

* Collapse licenses
collapse (sum) value_usd, by(n_sumoc)
replace value_usd = value_usd/1000000

merge 1:1 n_sumoc using "`to_match_codex_2'", nogen

* Final clean
drop company
gsort n_sumoc

save "../output/sumoc113_codex_part2.dta", replace





* Part 3 - Codex
import excel "../raw/sumoc113/I113 Parte 3_enriquecida.xlsx", first clear

keep(INVESTIMENTOSESTRANGEIROS B-K MUNICÍPIOFÁBRICAHISTÓRICO UFHISTÓRICA CONFIANÇAMUNICÍPIO ///
	 SIC2DÍGITOS SEDEHISTÓRICAQUANDOCONHECIDA TIPODELOCAL)

rename(INVESTIMENTOSESTRANGEIROS-TIPODELOCAL) (n_sumoc n_sumoc2 company sector ///
							  country_origin value_for value_usd value_2 value_3 ///
							  value_4 value_5 mun_name ///
							  state_name match_score sic_code sic_name type_place)

* Remvoing all blank spaces
foreach v of varlist n_sumoc-type_place{
	replace `v' = ustrto(ustrnormalize(`v', "nfd"), "ascii", 2)
	replace `v' = strltrim(`v')
	format `v' %12s
}

*** Many months out of order, so we'll arrange the columns ***
* Fix license numbers *
replace n_sumoc = n_sumoc2 if _n <= 218 | (_n >= 269 & _n <= 302)
destring n_sumoc, force replace

* Fix names, sectors, and values *
drop if substr(value_for, 1, 4) == "TOTA"
drop if substr(company, 1, 4) == "TOTA"


gen company_for = company if n_sumoc !=.
gen company_br  = company if n_sumoc == .

forvalues i = 1/10 {
	replace company_for = company_for[_n-1] if missing(company_for) & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_br[_n+1]  if missing(company_br)  & n_sumoc == n_sumoc[_n+1]
	replace company_br  = company_br[_n-1]  if missing(company_br)  & n_sumoc == n_sumoc[_n-1]
	replace company_br  = company_br[_n-1]  if company_br == "Idem" & n_sumoc == n_sumoc[_n-1]
}

order company_for company_br  
format company_for company_br %12s

replace company_br = sector          if inrange(_n, 218, 261)
replace sector = country_origin      if inrange(_n, 218, 261)
replace value_usd = value_2 		 if inrange(_n, 218, 261)
replace country_origin = value_for   if inrange(_n, 218, 261)

replace company_br = sector          if inrange(_n, 262, 297)
replace sector = country_origin      if inrange(_n, 262, 297)
replace country_origin = value_usd   if inrange(_n, 262, 297)
replace value_usd = value_3 		 if inrange(_n, 262, 297)

replace company_for = sector         if inrange(_n, 305, 386)
replace company_br = country_origin  if inrange(_n, 305, 386)
replace sector = value_for      	 if inrange(_n, 305, 386)
replace country_origin = value_3     if inrange(_n, 305, 386)
replace value_usd = value_5 		 if inrange(_n, 305, 386)

replace company_for = n_sumoc2       if inrange(_n, 399, 518)
replace company_br = company  		 if inrange(_n, 399, 518)



replace company_br = company if missing(company_br)
format company_for company_br %12s

* Clean values
replace value_usd     = subinstr(value_usd, ".", "", .)
replace value_usd 	  = subinstr(value_usd, ",", ".", .)
replace value_usd 	  = subinstr(value_usd, "US$", "", .)
replace value_usd 	  = subinstr(value_usd, " ", "", .)
destring value_usd, force replace

* Clean foreign and local firm name
forvalues i = 1/10 {
	replace n_sumoc = n_sumoc[_n-1] if missing(n_sumoc)
}
drop if n_sumoc == .
drop if value_usd == . & missing(company_for)
drop value_2-value_5 value_for

* Clean firm names and sectors *
replace company_br = company_br[_n + 1] if company_for == company_br

preserve
* Prepare for matching
keep if mun_name != ""
gsort n_sumoc

destring match_score sic_code, force replace
keep if mun_name != ""
drop if value_usd == .
tempfile to_match_codex_3
save "`to_match_codex_3'"
restore

* Collapse licenses
collapse (sum) value_usd, by(n_sumoc)
replace value_usd = value_usd/1000000

merge 1:1 n_sumoc using "`to_match_codex_3'", nogen

* Final clean
drop company n_sumoc2
gsort n_sumoc

replace company_br  = company_for 		if company_br == "b)Idem"

save "../output/sumoc113_codex_part3.dta", replace


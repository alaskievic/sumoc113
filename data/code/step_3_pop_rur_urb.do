clear

import excel "../raw/ipeadata/pop_mun_TUR_1872_a_2010.xls", first clear

keep código Município *1950 *1960 *1970 *1980 *1991 *2000 *2010

rename (código Município) (code2010 mun_name)

keep code2010 mun_name poptot1950 popurb1950 poprur1950 poptot1960 poprur1960 ///
	   popurb1960 poptot1970 poprur1970 popurb1970 poptot1980 poprur1980 popurb1980 ///
	   poptot1991 poprur1991 popurb1991 poptot2000 poprur2000 popurb2000 poptot2010 ///
	   popurb2010 poprur2010

foreach v of varlist poptot2010 popurb2010 poprur2010{
	replace `v' = subinstr(`v', ".", "",.)
}	   

destring code2010 poptot1950-poprur2010, force replace

gsort code2010 poptot2010
gen flag = 0
replace flag = 1 if code2010 == code2010[_n-1]
gsort flag

gsort code2010 poptot2010

foreach v of varlist poptot1950-poprur2010{
	replace `v' = `v'[_n-1] if code2010 == code2010[_n-1] & `v' == .
}

drop if code2010 == code2010[_n+1]

reshape long poptot popurb poprur, i(code2010) j(year)

drop flag

replace year = 1990 if year == 1991

save "../output/pop_mun.dta", replace

local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
local dir1 "`dir0'/data/"
local dir2 "`dir0'/analysis/"
cd "`dir2'"

qui log using "08-reportTables", name(log1) smcl replace

qui use "`dir2'05-BCfem_psa_results.dta", clear
label define ctrlbl 1 "Brunei Darussalam" 2 "Cambodia" 3 "Indonesia" 4 "Lao PDR" 5 "Malaysia" 6 "Myanmar" 7 "Philippines" 8 "Singapore" 9 "Thailand" 10 "Timor-Leste" 11 "Viet Nam"
label val country ctrlbl
format %5.0f p* cum*
qui keep if inlist(year,2030,2050)
sort scn year country
list, sepby(year scn) noobs clean

qui use "`dir2'10-BCfem_psa_results.dta", clear
label define ctrlbl 1 "Brunei Darussalam" 2 "Cambodia" 3 "Indonesia" 4 "Lao PDR" 5 "Malaysia" 6 "Myanmar" 7 "Philippines" 8 "Singapore" 9 "Thailand" 10 "Timor-Leste" 11 "Viet Nam"
label val country ctrlbl
format %5.2f p* cum*
qui keep if inlist(year,2030,2050)
sort scn year country
list, sepby(year scn) noobs clean

//close log
qui log close log1
qui log2html "08-reportTables", replace ti("Tables")

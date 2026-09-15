local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
local dir1 "`dir0'/data/"
local dir2 "`dir0'/analysis/"
cd "`dir2'"
//log output
capture log close _all
qui log using "01-getdata", name(log1) smcl replace

//import data/
import delimited "`dir1'\Forecast_Breast Ca_Female only_addedTL.csv", clear
drop if location==""
replace location="Lao PDR" if location=="Lao People's Democratic Republic"
sort location
sencode location, generate(country)
rename causeofdeathorinjury dcause
rename value bcdthpe
label var bcdthpe "Breast cancer deaths (numbers), point estimate"
rename lowerbound bcdthlb
label var bcdthlb "Breast cancer deaths (numbers), lower bound"
rename upperbound bcdthub
label var bcdthub "Breast cancer deaths (numbers), upper bound"
drop measure dcause scenario
label var screen "Screening programme active"
rename screenage scrnage
label var scrnage "Screening age"
rename attributeddeath scrnatd
label var scrnatd "Outcome % attributed to screening population"
rename invite scrninv 
label var scrninv "Invite coverage %" 
rename attendance scrnatt
label var scrnatt "Attendance coverage %" 
order population location country
compress
tab country
save "BCfem_cnts.dta", replace
descr

//import data/
import delimited "`dir1'\GBD1990-2050_BC deathper100k_20+_addedTL.csv", clear
drop if location==""
replace location="Lao PDR" if location=="Lao People's Democratic Republic"
sort location
sencode location, generate(country)
rename causeofdeathorinjury dcause
rename value bcdthpe
label var bcdthpe "Breast cancer deaths (per 100k), point estimate"
rename lowerbound bcdthlb
label var bcdthlb "Breast cancer deaths (per 100k), lower bound"
rename upperbound bcdthub
label var bcdthub "Breast cancer deaths (per 100k), upper bound"
drop measure dcause scenario
label var screen "Screening programme active"
rename screenage scrnage
label var scrnage "Screening age"
rename attributeddeath scrnatd
label var scrnatd "Outcome % attributed to screening population"
rename invite scrninv 
label var scrninv "Invite coverage %" 
rename attendance scrnatt
label var scrnatt "Attendance coverage %" 
order population location country
compress
tab country
save "BCfem_rats.dta", replace
descr


//close log
qui log close _all
qui log2html "01-getdata", replace ti("Get datasets")

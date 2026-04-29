local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast Cancer/"
local dir1 "`dir0'/data/"
local dir2 "`dir0'/analysis/"
cd "`dir2'"
//log output
capture log close _all
qui log using "02-getestimates", name(log1) smcl replace

qui use "BCfem_cnts.dta", clear

//Assumptions
//all eligible women are invited i.e. scrninv=100%
//just using 2025 data on the screening programme (not trends)
//using a conservative RR of attendance (RRatt) of 0.78 (22% reduction) - this is the ITT invitation reduction in the Dibden et al. 2020 meta-analysis
//RRatt is static over time, when it could increase as harder to reach populations attend who may benefit more
//and different scenarios of increase in attendance: absolute 5% and 10%. relative 10%
//we assume  the changes are immediate from 2026 onwards, but we can instead aim for a gradual increase over time until the desired level is obtained.

//attendance RR
local RRatt=0.78
//scenario loop, 1=abs 5%, 2=abs 10%, 3=rel 10%  
forvalues j=1(1)3 {
	gen bcdthpe`j'=bcdthpe
	gen bcdthlb`j'=bcdthlb
	gen bcdthub`j'=bcdthub
	//country loop
	forvalues i=1(1)10 {
		//f = fraction of national BC deaths occurring in invited age range
		qui sum scrnatd if country==`i' & year==2025
		local f  = r(mean)
		//population level ITT effect at 2025 attendance level
		qui sum scrnatt if country==`i' & year==2025
		local p0 = r(mean)
		local RRinvA = 1 - `p0'*(1-`RRatt')
		//population level ITT effect at hypothesised level
		if `j'==1 {
			local p1=`p0'+0.05
		}
		else if `j'==2 {
			local p1=`p0'+0.10			
		}
		else if `j'==3 {
			local p1=`p0'+0.10*`p0'						
		}
		local RRinvB = 1 - `p1'*(1-`RRatt')
		//deaths averted multiplier (to multiply with estimates from 2026 onwards)
		local mplier = `f'*(`RRinvB'-`RRinvA')
		*di `mplier'
		//country edits
		foreach x in pe lb ub {
			qui replace bcdth`x'`j' = bcdth`x'`j' + bcdthpe`j'*`mplier' if country==`i' & year>=2026
			label var bcdth`x'`j' "BCD scenario `j', `x'"
		}
	}
}
notes: Scenario 1: absolute increase of attendance by 5%
notes: Scenario 2: absolute increase of attendance by 10%
notes: Scenario 3: Relative increase of attendance by 10%	

compress
descr
notes
qui save "02-BCfem_scenarios.dta", replace
export excel using "02-BCfen_scenarios.xlsx", replace firstrow(variables)  

//close log
qui log close _all
qui log2html "02-getestimates", replace ti("Get estimates")

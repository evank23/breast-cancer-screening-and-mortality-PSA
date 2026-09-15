//as in 4 but adding 5 years at the end of each screening programme
capture program drop simattr
clear matrix
clear mata
program simattr
	//use 2023 GBD data on populations and BC deaths to estimate attribution to be used with PSA
	//using monotonic cubic interpolation
	local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
	local dir1 "`dir0'/analysis/sens3/outdata/"
	local dir2 "`dir0'/analysis/sens3/"
	cd "`dir2'"
	clear
	set more off
	
	//log output
	capture log close _all
	qui log using "12-D_attribution_diff", name(log1) smcl replace	
	
	set maxvar 50000
	set seed 7
	local numcnt=11
	local S 10000
	
	qui use "`dir1'\09-tempfile.dta", clear
	rename AttrVal AttrVal2
	rename screenhi scrnhi2
	drop screenlo
	qui merge 1:1 simnum country using "`dir1'\04-tempfile.dta", nogen
	rename AttrVal AttrVal1 
	rename screenhi scrnhi1
	rename screenlo scrnlo
	gen AttrDiff=AttrVal2-AttrVal1
	drop AttrVal2 AttrVal1
	order simnum country AttrDiff scrnlo scrnhi1 scrnhi2
	qui fastreshape wide AttrDiff, i(country) j(simnum)

	egen attr_mn = rowmean(AttrDiff1 - AttrDiff`S')
	egen attr_lo = rowpctile(AttrDiff1 - AttrDiff`S'), p(2.5)
	egen attr_hi = rowpctile(AttrDiff1 - AttrDiff`S'), p(97.5)
	qui drop AttrDiff*

	sort country
	label val country country
	format attr* %8.3f
	list, clean
	qui compress
	qui save "`dir1'\12-D_attribution_diff.dta", replace

	//close log
	qui log close _all
	qui log2html "12-D_attribution_diff", replace ti("Attribution estimates by country (difference between current and +5 thresholds)")
end

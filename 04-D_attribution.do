capture program drop simattr
clear matrix
clear mata
program simattr
	//use 2023 GBD data on populations and BC deaths to estimate attribution to be used with PSA
	//using monotonic cubic interpolation
	local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
	local dir1 "`dir0'/data/"
	local dir2 "`dir0'/analysis/"
	cd "`dir2'"
	clear
	set more off

	//log output
	capture log close log1
	qui log using "04-D_attribution", name(log1) smcl replace
	
	set maxvar 50000
	set seed 7
	local numcnt=11
	local mcmc=10000
	local delay_mult=1.00

	//get denominators
	qui {
	import delimited "`dir1'\IHME-GBD_2023_DATA_POP2023.csv", clear
	keep age val location
	sort location age
	rename val denom
	replace age="1" if age=="<1 year"
	replace age="95" if age=="95+ years"
	drop if age=="All ages"
	destring age, replace
	qui replace location="Lao PDR" if location=="Lao People's Democratic Republic"
	sencode location, gen(country)
	tempfile tempden
	save `tempden', replace
	}

	//get numerators
	qui {
	import delimited "`dir1'\IHME-GBD_2023_DATA_BCDeath2023.csv", clear
	keep age val location lower upper
	sort location age
	rename (val lower upper) (num numlo numup) 
	qui replace location="Lao PDR" if location=="Lao People's Democratic Republic"
	sencode location, gen(country)
	sencode age, gen(agegrp)
	gen agelo=(agegrp+2)*5
	gen agehi=(agegrp+2)*5+4
	tempfile tempnum
	sort location agegrp
	save `tempnum', replace
	}

	qui {
	//loop for countries
	forvalues i=1(1)`numcnt' {
		//cumulative monotonic spline to obtain estimates annualy rather than as aggregates
		//preserves totals and produces smooth within band variation
		*dataset keep upper age limit
		qui use `tempnum', clear
		qui keep if country==`i'
		qui drop if agegrp==17 //leave out age 95+
		sort agelo
		preserve
		keep agehi num
		rename num cum5
		rename agehi age
		tempfile tnum
		save `tnum'
		restore
		preserve
		*Make a full integer-age frame
		sum agelo
		local minage=r(min)
		sum agehi
		local maxage=r(max)
		clear
		set obs `=`maxage'-`minage'+1'
		gen age = (_n - 1)+`minage'
		*Merge the cumulative end-point values
		merge 1:1 age using `tnum', nogen
		save `tnum', replace
		*add age 14 which is needed for the interpolation
		clear
		set obs 1
		gen age = 14
		gen cum5 = 0
		append using `tnum'
		*Interpolate the cumulative at each integer age using a monotone method
		*monotone cubic (pchip) – requires SSC pchipolate
		*ssc install pchipolate, replace
		pchipolate cum5 age, gen(cum_interp_pchip)
		keep if inrange(age, 15, 94)
		tempfile annual
		save `annual', replace
		restore
		*Rake within each band to restore exact totals
		*ssc install rangejoin
		*ssc install rangestat
		drop age
		rangejoin age agelo agehi using `annual'
		*use the same trend but adjust to cumulative within each age band
		qui save `annual', replace
		qui collapse (sum) tempsum=cum_interp_pchip (max) cum5, by(agegrp)
		merge 1:m agegrp using `annual', nogen
		sort agegrp age
		replace cum_interp_pchip=(cum_interp_pchip/tempsum)*cum5
		*work out distributed SE
		gen wSE=cum_interp_pchip/cum5
		gen sigma=(ln(numup)-ln(numlo))/(2*invnormal(0.975))
		gen SE5y=num*sqrt(exp(sigma^2)-1)
		gen SE1y=SE5y*wSE
		drop tempsum cum5
		rename cum_interp_pchip numX
		qui save `annual', replace
		*append 95+
		qui use `tempnum', clear
		qui keep if country==`i'
		qui keep if agegrp==17
		qui drop age
		qui append using `annual'
		sort agegrp age
		replace agehi=. if agelo==95
		replace age=95 if agelo==95
		replace numX=num if agelo==95
		replace sigma=(ln(numup)-ln(numlo))/(2*invnormal(0.975)) if agelo==95
		replace SE5y=num*sqrt(exp(sigma^2)-1) if agelo==95
		replace wSE=1 if agelo==95
		replace SE1y=SE5y if agelo==95
		label var numX "Interpolated (monotonic cubic) BC deaths by integer age"
		*now merge with denominators
		qui merge 1:1 age country using `tempden', nogen
		sort country age
		drop agelo agehi
		save `tempden', replace
	}
	}
	qui drop num numup numlo wSE sigma SE5y

	forvalues i=1(1)`numcnt' {
		list if country==`i', sepby(agegrp)
	}
	qui compress
	save "`dir1'\04-D_attributionA.dta", replace

	//MC simulation
	* Per-cell lognormal parameters from (mean, SD) = (numX, SE1y)
	qui {
		gen double var1y   = SE1y^2
		gen double ratio   = var1y/(numX^2)
		gen double sigmaD  = sqrt(ln(1 + ratio))                // log-SD
		gen double muD     = ln(numX) - 0.5*sigmaD^2            // log-mean
	}
	qui drop if age<=14
	
	//gen age limits
	matrix define scrage = (40, 15, 30, 40, 50, 40, 40, 50, 40, 40, 40 \ 69, 49, 50, 69, 74, 69, 69, 69, 69, 69, 70)
	qui gen agelo=.
	qui gen agehi=.
	forvalues i=1(1)`numcnt' {
		qui replace agelo=scrage[1,`i'] if country==`i'
		qui replace agehi=scrage[2,`i'] if country==`i'
	}
	//lags in deaths. using this and making a bit higher since paper is old
	//https://www.nature.com/articles/s41598-020-58007-5#:~:text=A%20total%20of%2019%2C241%20female,at%20age%2070%20and%20above.	
	* 1. Log-normal parameters for the diagnosis-to-death delay bu country
	* 1 Brunei Darussalam 2 Cambodia 3 Indonesia 4 Lao PDR 5 Malaysia 6 Myanmar 7 Philippines 8 Singapore 9 Thailand 10 Timor-Leste 11 Viet Nam
	foreach x in 1 8 {
		local mu`x' = ln(6)
		local sigma`x' = (ln(9) - ln(4)) / (2*0.67448975)
	}
	foreach x in 3 5 9 11 {
		local mu`x' = ln(5)
		local sigma`x' = (ln(7) - ln(3)) / (2*0.67448975)
	}
	foreach x in 2 4 7 10 {
		local mu`x' = ln(4)
		local sigma`x' = (ln(6) - ln(2.5)) / (2*0.67448975)
	}
	foreach x in 6 {
		local mu`x' = ln(3)
		local sigma`x' = (ln(4.5) - ln(2)) / (2*0.67448975)
	}
	local Lmax = 20
	//draws
	local S `mcmc'
	di _newline(2) as text "drawing deaths (1000s): `S' draws"	
	forvalues i=1(1)`S' {
		qui gen double Ndeath_s`i' = exp(rnormal(muD, sigmaD))	
		/** Draw a delay for this country / simulation
		qui gen double delay_s`i' = .
		forvalues j=1/`numcnt' {
			scalar delay_draw = `delay_mult'*exp(rnormal(`mu`j'', `sigma`j''))
			qui replace delay_s`i' = scalar(delay_draw) if country == `j'
		}*/		
		*Apply the country-specific median diagnosis-to-death delay
		qui gen double delay_s`i' = .
		forvalues j=1/`numcnt' {
			scalar delay_draw = `delay_mult' * exp(`mu`j'')
			qui replace delay_s`i' = scalar(delay_draw) if country == `j'
		}
		* Apply delay
		qui gen double diagage_s`i' = age - delay_s`i'
		* Reassign extreme ages (preserve totals)
		qui replace diagage_s`i' = 15 if diagage_s`i' < 15
		qui replace diagage_s`i' = 95 if diagage_s`i' > 95
		* Compute invited deaths
		gen double in_scr_s`i' = diagage_s`i' >= agelo & diagage_s`i' <= agehi
		gen double Ninv_s`i'    = Ndeath_s`i' * in_scr_s`i'
		qui drop delay_s* diagage_s* in_scr_s*
		if mod(`i',1000)==0 {
			di as res "." _continue
		}
	}
	di

	tempfile attrsim
	qui save `attrsim'

	tempfile fattr
	//estimate attribution by country
	di _newline(2) as text "processing countries:"
	forvalues i=1(1)`numcnt' {	
		qui use `attrsim', clear	
		qui keep if country==`i'
		//collapse and merge to stay within memory constraints and do it fast
		qui keep country Ninv_s* Ndeath_s* age
		qui egen id=seq()
		qui fastreshape long Ninv_s Ndeath_s, i(id) j(simnum)
		sort country simnum age
		gcollapse (sum) Ninv_s* Ndeath_s* (first) country, by(simnum) fast
		qui gen AttrVal=100*(Ninv_s/Ndeath_s)
		qui drop Ninv_s Ndeath_s				
		qui gen screenlo=scrage[1,`i']
		qui gen screenhi=scrage[2,`i']
		capture save `fattr'
		if _rc!=0 {
			qui append using `fattr'
			qui save `fattr', replace
		}
		di as res "." _continue
	}
	//save file to use to obtain difference
	compress
	qui save "`dir1'\04-tempfile.dta", replace
	
	qui fastreshape wide AttrVal, i(country) j(simnum)

	egen attr_mn = rowmean(AttrVal1 - AttrVal`S')
	egen attr_lo = rowpctile(AttrVal1 - AttrVal`S'), p(2.5)
	egen attr_hi = rowpctile(AttrVal1 - AttrVal`S'), p(97.5)
	qui drop AttrVal*

	sort country
	label val country country
	format attr* %8.3f
	list, clean
	qui compress
	qui save "`dir1'\04-D_attributionB.dta", replace

	//close log
	qui log close log1
	qui log2html "04-D_attribution", replace ti("Attribution estimates by country")
end

local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
local dir1 "`dir0'/analysis/sens2/outdata/"
local dir2 "`dir0'/analysis/sens2/"
local dir3 "`dir0'/analysis/sens2/graphs/"
capture mkdir "`dir3'"
cd "`dir3'"

local numcnt=11

//2025 screening info
qui use "`dir1'04-D_attributionB.dta", clear
label define country 4 "Lao PDR", modify
sort attr_mn
egen country2=seq()
forvalues i=1(1)`numcnt' {
	label define ctrlbl `i' "`:label country `=country[`i']''", add
}
label val country2 ctrlbl
colorpalette RdBu, n(`numcnt') nograph
twoway rcap attr_hi attr_lo country2, color(gs5) ///
	|| scatter attr_mn country2, colorvar(country2) colordiscrete colorlist(`r(p)') coloruseplegend ///
    zlabel(, valuelabel) ///
	xtitle("Country", size(medsmall)) ///
	ytitle("Percentage", size(medsmall)) ///
	xlabel(, nolabels) ///
	yscale(range(0 100)) ///
	ylabel(0(20)100, format(%9.0f)) ///
	legend(off) ///	
	title("", size(medlarge)) 
graph export "06-AttrPlot.eps", replace
graph export "06-AttrPlot.png", replace width(1200)

//2025 screening info +5y on upper threshold
qui use "`dir1'09-D_attributionB.dta", clear
label define country 4 "Lao PDR", modify
sort attr_mn
egen country2=seq()
forvalues i=1(1)`numcnt' {
	label define ctrlbl `i' "`:label country `=country[`i']''", add
}
label val country2 ctrlbl
colorpalette RdBu, n(`numcnt') nograph
twoway rcap attr_hi attr_lo country2, color(gs5) ///
	|| scatter attr_mn country2, colorvar(country2) colordiscrete colorlist(`r(p)') coloruseplegend ///
    zlabel(, valuelabel) ///
	xtitle("Country", size(medsmall)) ///
	ytitle("Percentage", size(medsmall)) ///
	xlabel(, nolabels) ///
	yscale(range(0 100)) ///
	ylabel(0(20)100, format(%9.0f)) ///
	legend(off) ///	
	title("", size(medlarge)) 
graph export "06-AttrPlot_alt.eps", replace
graph export "06-AttrPlot_alt.png", replace width(1200)
graph close _all
/*note("no national screening programme for Lao PDR, Myanmar & Timor-Leste in 2025, assuming Indonesia screening ages" "no national screening programme for Viet Nam in 2025, assuming 2026 screening ages", size(vsmall)) */
/*note("no national screening programme for Lao PDR, Myanmar & Timor-Leste in 2025, assuming Indonesia screening ages" "assuming upper screening threshold extended by 5 years", size(vsmall)) */
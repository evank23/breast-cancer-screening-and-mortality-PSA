local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast Cancer/"
local dir1 "`dir0'/data/"
local dir2 "`dir0'/analysis/"
local dir3 "`dir0'/graphs/"
capture mkdir "`dir3'"
cd "`dir3'"

//2025 screening info
qui use "`dir1'04-D_attributionB.dta", clear
label define country 4 "Lao PDR", modify
sort attr_mn
egen country2=seq()
forvalues i=1(1)10 {
	label define ctrlbl `i' "`:label country `=country[`i']''", add
}
label val country2 ctrlbl
colorpalette RdBu, n(10) nograph
twoway rcap attr_hi attr_lo country2, color(gs5) ///
	|| scatter attr_mn country2, colorvar(country2) colordiscrete colorlist(`r(p)') coloruseplegend ///
    zlabel(, valuelabel) ///
	xtitle("Country", size(medsmall)) ///
	xlabel(, nolabels) ///
	yscale(range(0 100)) ///
	ylabel(0(20)100, format(%9.0f)) ///
	legend(off) ///	
	note("no national screening programme for Lao PDR and Myanmar in 2025, assuming Indonesia screening ages", size(vsmall)) ///
	title("", size(medlarge)) 
graph export "06-AttrPlot.eps", replace
graph export "06-AttrPlot.png", replace width(1200)

//2025 screening info +5y on upper threshold
qui use "`dir1'09-D_attributionB.dta", clear
label define country 4 "Lao PDR", modify
sort attr_mn
egen country2=seq()
forvalues i=1(1)10 {
	label define ctrlbl `i' "`:label country `=country[`i']''", add
}
label val country2 ctrlbl
colorpalette RdBu, n(10) nograph
twoway rcap attr_hi attr_lo country2, color(gs5) ///
	|| scatter attr_mn country2, colorvar(country2) colordiscrete colorlist(`r(p)') coloruseplegend ///
    zlabel(, valuelabel) ///
	xtitle("Country", size(medsmall)) ///
	xlabel(, nolabels) ///
	yscale(range(0 100)) ///
	ylabel(0(20)100, format(%9.0f)) ///
	legend(off) ///	
	note("no national screening programme for Lao PDR and Myanmar in 2025, assuming Indonesia screening ages" "assuming upper screening threshold extended by 5 years", size(vsmall)) ///
	title("", size(medlarge)) 
graph export "06-AttrPlot_alt.eps", replace
graph export "06-AttrPlot_alt.png", replace width(1200)

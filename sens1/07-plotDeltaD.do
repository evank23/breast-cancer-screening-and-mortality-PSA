local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
local dir1 "`dir0'/analysis/sens1/outdata/"
local dir2 "`dir0'/analysis/sens1/"
local dir3 "`dir0'/analysis/sens1/graphs/"
capture mkdir "`dir3'"
cd "`dir3'"

qui use "`dir2'05-BCfem_psa_results.dta", clear
label define ctrlbl 1 "Brunei Darussalam" 2 "Cambodia" 3 "Indonesia" 4 "Lao PDR" 5 "Malaysia" 6 "Myanmar" 7 "Philippines" 8 "Singapore" 9 "Thailand" 10 "Timor-Leste" 11 "Viet Nam"
label val country ctrlbl
local numcnt=11

//scenarios 1&2 non-cummulative 
//country loop
forvalues i=1(1)`numcnt' {
	preserve
	//select country
	qui keep if country ==`i' & year>2025
	local label : label (country) `i'
	colorpalette hcl greens, n(4) nograph
	twoway rarea p2_5 p97_5 year if scn==1, color(gs14%50) sort ///
	|| rarea p2_5 p97_5 year if scn==2, color(gs14%50) ///
	|| line p50 year if scn==1, color("`r(p2)'") ///
	|| line p50 year if scn==2, color("`r(p1)'") ///
	plotregion(margin(zero)) ///
	xlabel(2026 2030(5)2050, angle(45)) ///
	legend(order(3 4 1)) ///
	legend(pos(6)) ///
	legend(rows(1) label(3 "Absolute 5% attendance increase") label(4 "Absolute 10% attendance increase")) ///
	legend(rows(2) label(1 "95% Confidence Intervals")) ///
	title("`label'", size(medlarge)) 
	graph save "07-DeltaD_ncum`i'.gph", replace
	restore
}
//graph combine
grc1leg2 "07-DeltaD_ncum1.gph" "07-DeltaD_ncum2.gph" "07-DeltaD_ncum3.gph" "07-DeltaD_ncum4.gph" "07-DeltaD_ncum5.gph" ///
"07-DeltaD_ncum6.gph" "07-DeltaD_ncum7.gph" "07-DeltaD_ncum8.gph" "07-DeltaD_ncum9.gph" "07-DeltaD_ncum10.gph" "07-DeltaD_ncum11.gph", /*
*/ cols(2) imargin(small) legendfrom("07-DeltaD_ncum1.gph") lsize(1.7) ysize(8) xsize(5.5)
graph display, ysize(8) xsize(5.5)
graph export "Fig2noncumDeltaD.eps", replace
graph export "Fig2noncumDeltaD.png", replace width(1200)

//scenarios 1&2 cummulative 
//country loop
forvalues i=1(1)`numcnt' {
	preserve
	//select country
	qui keep if country ==`i' & year>2025
	local label : label (country) `i'
	colorpalette hcl greens, n(3) nograph
	twoway rarea cump2_5 cump97_5 year if scn==1, color(gs14%50) sort ///
	|| rarea cump2_5 cump97_5 year if scn==2, color(gs14%50) ///
	|| line cump50 year if scn==1, color("`r(p2)'") ///
	|| line cump50 year if scn==2, color("`r(p1)'") ///
	plotregion(margin(zero)) ///
	xlabel(2026 2030(5)2050, angle(45)) ///
	legend(order(3 4 1)) ///
	legend(pos(6)) ///
	legend(rows(1) label(3 "Absolute 5% attendance increase") label(4 "Absolute 10% attendance increase")) ///
	legend(rows(2) label(1 "95% Confidence Intervals")) ///
	title("`label'", size(medlarge)) 
	graph save "07-DeltaD_cumm`i'.gph", replace
	restore
}
//graph combine
grc1leg2 "07-DeltaD_cumm1.gph" "07-DeltaD_cumm2.gph" "07-DeltaD_cumm3.gph" "07-DeltaD_cumm4.gph" "07-DeltaD_cumm5.gph" ///
"07-DeltaD_cumm6.gph" "07-DeltaD_cumm7.gph" "07-DeltaD_cumm8.gph" "07-DeltaD_cumm9.gph" "07-DeltaD_cumm10.gph" "07-DeltaD_cumm11.gph", /*
*/ cols(2) imargin(small) legendfrom("07-DeltaD_cumm1.gph") lsize(1.7) ysize(8) xsize(5.5)
graph display, ysize(8) xsize(5.5)
graph export "Fig3cummulativeDeltaD.eps", replace
graph export "Fig3cummulativeDeltaD.png", replace width(1200)

//scenario 3 non-cummulative 
//country loop
forvalues i=1(1)`numcnt' {
	preserve
	//select country
	qui keep if country ==`i' & year>2025
	local label : label (country) `i'
	colorpalette hcl greens, n(4) nograph
	twoway rarea p2_5 p97_5 year if scn==3, color(gs14%50) sort ///
	|| line p50 year if scn==3, color("`r(p2)'") ///
	plotregion(margin(zero)) ///
	xlabel(2026 2030(5)2050, angle(45)) ///
	legend(order(2 1)) ///
	legend(pos(6)) ///
	legend(rows(1) label(2 "Fixed 40% attendance") label(1 "95% Confidence Intervals")) ///
	title("`label'", size(medlarge)) 
	graph save "07-DeltaDx_ncum`i'.gph", replace
	restore
}
//graph combine
grc1leg2 "07-DeltaDx_ncum1.gph" "07-DeltaDx_ncum2.gph" "07-DeltaDx_ncum3.gph" "07-DeltaDx_ncum4.gph" "07-DeltaDx_ncum5.gph" ///
"07-DeltaDx_ncum6.gph" "07-DeltaDx_ncum7.gph" "07-DeltaDx_ncum8.gph" "07-DeltaDx_ncum9.gph" "07-DeltaDx_ncum10.gph" "07-DeltaDx_ncum11.gph", /*
*/ cols(2) imargin(small) legendfrom("07-DeltaDx_ncum1.gph") lsize(1.7) ysize(8) xsize(5.5)
graph display, ysize(8) xsize(5.5)
graph export "Fig2xnoncumDeltaD.eps", replace
graph export "Fig2xnoncumDeltaD.png", replace width(1200)

//scenarios 1&2 cummulative 
//country loop
forvalues i=1(1)`numcnt' {
	preserve
	//select country
	qui keep if country ==`i' & year>2025
	local label : label (country) `i'
	colorpalette hcl greens, n(3) nograph
	twoway rarea cump2_5 cump97_5 year if scn==3, color(gs14%50) sort ///
	|| line cump50 year if scn==3, color("`r(p2)'") ///
	plotregion(margin(zero)) ///
	xlabel(2026 2030(5)2050, angle(45)) ///
	legend(order(2 1)) ///
	legend(pos(6)) ///
	legend(rows(1) label(2 "Fixed 40% attendance") label(1 "95% Confidence Intervals")) ///
	title("`label'", size(medlarge)) 
	graph save "07-DeltaDx_cumm`i'.gph", replace
	restore
}
//graph combine
grc1leg2 "07-DeltaDx_cumm1.gph" "07-DeltaDx_cumm2.gph" "07-DeltaDx_cumm3.gph" "07-DeltaDx_cumm4.gph" "07-DeltaDx_cumm5.gph" ///
"07-DeltaDx_cumm6.gph" "07-DeltaDx_cumm7.gph" "07-DeltaDx_cumm8.gph" "07-DeltaDx_cumm9.gph" "07-DeltaDx_cumm10.gph" "07-DeltaDx_cumm11.gph", /*
*/ cols(2) imargin(small) legendfrom("07-DeltaDx_cumm1.gph") lsize(1.7) ysize(8) xsize(5.5)
graph display, ysize(8) xsize(5.5)
graph export "Fig3xcummulativeDeltaD.eps", replace
graph export "Fig3xcummulativeDeltaD.png", replace width(1200)
graph close _all

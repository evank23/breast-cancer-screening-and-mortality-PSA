local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast Cancer/"
local dir1 "`dir0'/data/"
local dir2 "`dir0'/analysis/"
local dir3 "`dir0'/graphs/"
capture mkdir "`dir3'"
cd "`dir3'"

qui use "`dir2'02-BCfem_scenarios.dta", clear

//country loop
forvalues i=1(1)10 {
	preserve
	//select country
	qui keep if country ==`i' & year>=2025
	local label : label (country) `i'
	colorpalette hcl heat, n(5) nograph
	twoway rarea bcdthlb bcdthub year, color(gs14) sort ///
	|| rarea bcdthlb1 bcdthub1 year, color(gs14) ///
	|| rarea bcdthlb2 bcdthub2 year, color(gs14) ///	
	|| rarea bcdthlb3 bcdthub3 year, color(gs14) ///	
	|| line bcdthpe year, color("`r(p1)'") ///
	|| line bcdthpe1 year, color("`r(p2)'") ///
	|| line bcdthpe2 year, color("`r(p3)'") ///
	|| line bcdthpe3 year, color("`r(p4)'") ///
	legend(order(5 6 7 8 1)) ///
	legend(pos(6)) ///
	legend(rows(1) label(5 "Breast Cancer Deaths GBD prediction") label(6 "Absolute 5% attendance increase")) ///
	legend(rows(2) label(7 "Absolute 10% attendance increase") label(8 "Relative 10% attendance increase")) ///
	legend(rows(3) label(1 "95% Confidence Intervals")) ///
	title("`label'", size(medlarge)) 
	graph save "03-country`i'.gph", replace
	restore
}

//graph combine
grc1leg2 "03-country1.gph" "03-country2.gph" "03-country3.gph" "03-country4.gph" "03-country5.gph" ///
"03-country6.gph" "03-country7.gph" "03-country8.gph" "03-country9.gph" "03-country10.gph", /*
*/ cols(2) imargin(small) legendfrom("03-country1.gph") lsize(1.7) ysize(8) xsize(5.5)
graph display, ysize(8) xsize(5.5)
graph export "Fig1.eps", replace
graph export "Fig1.png", replace width(1200)

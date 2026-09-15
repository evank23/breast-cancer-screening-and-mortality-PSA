*******************************************************
* MASTER CALLER: run all analysis and sensitivity files
*******************************************************

version 19.5
clear all
set more off

*==========================
* DIRECTORIES
*==========================
local dir1 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/analysis/"
local dir2 "`dir1'sens1/"
local dir3 "`dir1'sens2/"
local dir4 "`dir1'sens3/"

capture log close _all
log using "`dir1'00-master_run", name(master) smcl replace

*==========================
* MAIN ANALYSIS
*==========================
di as text _newline "Running main analysis"
do "`dir1'04-D_attribution.do"
simattr
do "`dir1'05-PSA_MonteCarlo.do"
do "`dir1'09-D_attribution_alternative.do"
simattr
do "`dir1'10-PSA_MC_rates.do"
do "`dir1'12-D_attribution_diff.do"
simattr
do "`dir1'06-AttrPlot.do"
do "`dir1'07-plotDeltaD.do"
do "`dir1'08-reportTables.do"
do "`dir1'11-plotDeltaDrate.do"
*==========================
* SENSITIVITY 1
* Half the number of Monte Carlo draws
*==========================
di as text _newline "Running sensitivity analysis 1"
do "`dir2'04-D_attribution.do"
simattr
do "`dir2'05-PSA_MonteCarlo.do"
do "`dir2'09-D_attribution_alternative.do"
simattr
do "`dir2'10-PSA_MC_rates.do"
do "`dir2'12-D_attribution_diff.do"
simattr
do "`dir2'06-AttrPlot.do"
do "`dir2'07-plotDeltaD.do"
do "`dir2'08-reportTables.do"
do "`dir2'11-plotDeltaDrate.do"
*==========================
* SENSITIVITY 2
* 20% shorter diagnosis-to-death intervals
*==========================
di as text _newline "Running sensitivity analysis 2"
do "`dir3'04-D_attribution.do"
simattr
do "`dir3'09-D_attribution_alternative.do"
simattr
do "`dir3'12-D_attribution_diff.do"
simattr
do "`dir3'06-AttrPlot.do"
*==========================
* SENSITIVITY 3
* 20% longer diagnosis-to-death intervals
*==========================
di as text _newline "Running sensitivity analysis 3"
do "`dir4'04-D_attribution.do"
simattr
do "`dir4'09-D_attribution_alternative.do"
simattr
do "`dir4'12-D_attribution_diff.do"
simattr
do "`dir4'06-AttrPlot.do"
*==========================
* FINISH
*==========================
di as result _newline "All analyses completed successfully."

capture log close master
capture log2html "`dir1'00-master_run", replace ///
    ti("Master analysis run")

*******************************************************
* END
*******************************************************

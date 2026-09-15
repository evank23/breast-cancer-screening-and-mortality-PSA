*******************************************************
* Probabilistic PSA of prevented BC deaths with uncertainty
* Country-level deaths + programme attendance; all eligible invited
* ITT mapping: RR_invite(p) = 1 - p*(1 - RR_attend)
*******************************************************
version 19.5
clear all
set more off
set seed 11

*==========================
* DIRECTORIES & LOG 
*==========================
local dir0 "C:/Users/`c(username)'/OneDrive - National University of Singapore/GBD Cancer/Breast/"
local dir1 "`dir0'/analysis/"
local dir2 "`dir0'/analysis/sens1/"
local dir3 "`dir0'/analysis/sens1/outdata/"
cd "`dir2'"
local mcmc=10000

capture log close log1
qui log using "05-PSA_MonteCarlo", name(log1) smcl replace

*==========================
* INPUT DATA
*==========================
* Expecting a country-year panel like BCfem.dta with variables:
* country (numeric or string id), year (numeric),
* bcdthpe bcdthlb bcdthub  = point / 95% lower / 95% upper annual deaths,
* scrnatd (fraction of national BC deaths in invited ages) – may be a mean by country (e.g., 2025),
* scrnatt (programme attendance rate; all eligible invited).
use "`dir1'BCfem_cnts.dta", clear

*==========================
* USER OPTIONS (easy to tweak)
*==========================
* Years for evaluation (annual + cumulative)
local startyear 2025
local endyear   2050

* Scenarios: 1=abs +5pp, 2=abs +10pp, 3=fixed 40%
local scenarios "1 2 3"

* Monte Carlo draws
local S `mcmc'

* ---- Priors / Hyperparameters ----
* ATTENDANCE-LEVEL causal RR prior (kept constant within a sim draw, country-wide)
* Set center to 0.78 (conservative), 0.74 (central), or 0.67 (optimistic)
local RR_center 0.74
local sd_logRR  0.06   // prior SD on log(RR_attend) (~±25% 95% width)

* Invited-age share f prior: Beta around each country's mean scrnatd (at a reference year)
* If scrnatd is recorded only in 2025, we pull that to parameterize the Beta.
*use estimates from the porevious MC simulation, by country
preserve
qui use "`dir3'/04-D_attributionB.dta", clear
foreach x of varlist attr_mn attr_lo attr_hi {
	qui replace `x'=`x'/100
}
gen double attr_se = (attr_hi - attr_lo) / (2*1.96)
gen double f_ESS = (attr_mn*(1 - attr_mn)) / (attr_se^2) - 1
gen double alpha_f = attr_mn * f_ESS
gen double beta_f  = (1 - attr_mn) * f_ESS
keep alpha_f beta_f country
tempfile attrESS
save `attrESS', replace
restore

* Programme attendance p0 (baseline) & p1 (scenario):
* We take scrnatt in the year (or in 2025 as baseline) and apply scenario changes.
* Beta dispersion (ESS) controls the breadth around the mean attendance in each draw.
local p_ESS  400

* From which year the attendance change takes effect?
local policy_start 2026

*==========================
* FILTER YEARS
*==========================
keep if inrange(year, `startyear', `endyear')
tempvar z975 lnlow lnhigh sigma mu
gen double `z975'  = invnormal(.975)
gen double `lnlow' = ln(bcdthlb)
gen double `lnhigh'= ln(bcdthub)
gen double `sigma' = (`lnhigh' - `lnlow')/(2*`z975')
gen double `mu'    = ln(bcdthpe) - 0.5*`sigma'^2

*==========================
* NOTES (like your script)
*==========================
**# Bookmark #1
notes: All eligible women are invited (invitation coverage 100%).
notes: Mapping attendance to ITT: RR_invite(p) = 1 - p*(1 - RR_attend).
notes: ATTENDANCE-LEVEL causal effect prior centered at `RR_center' (log-normal on log RR), sd_logRR=`sd_logRR'.
notes: Eligible-age fraction f ~ Beta(mean from scrnatd, ESS=country variable from previous MC).
notes: Annual deaths D ~ LogNormal(mu(year,country), sigma(year,country)) from bcdthpe/lb/ub.
notes: Baseline attendance p0 is drawn from a Beta distribution with ESS=`p_ESS'.
notes: Scenario attendance is paired with p0: scenario 1 adds 5 percentage points, scenario 2 adds 10 percentage points, and scenario 3 sets attendance to 40%.
notes: Attendance is capped at 80%. Policy changes start in `policy_start'.
notes: Outputs are annual and cumulative deaths averted, reported as medians and 95% uncertainty intervals, by country, year, and scenario.

*==========================
* PREP CROSSWALKS
*==========================
preserve
keep country year bcdthpe bcdthlb bcdthub `mu' `sigma' scrnatd scrnatt
tempfile base
save `base', replace
restore

* Identify unique countries present in the retained period
preserve
keep country
duplicates drop
tempfile countries
save `countries', replace
restore

*==========================
* MONTE CARLO PANEL: sim × country × year
*==========================
* 1) Make a sim index (1..S)
clear
set obs `S'
gen long sim = _n
tempfile simix
save `simix', replace

* 3) Bring in year rows
use `base', clear
cross using `simix'   	// (sim, country, year, bcdth*, mu, sigma, scrnatd, scrnatt)
order sim country year


*==========================
* DRAW STRUCTURAL PARAMETERS (shared within a sim × country across years)
*==========================
tempfile tempf
qui save `tempf', replace

qui keep if year==2025
qui keep sim country scrnatd scrnatt
* (a) RR_attend ~ LogNormal on log scale
gen logRR_attend = rnormal(ln(`RR_center'), `sd_logRR')
gen double RR_attend = exp(logRR_attend)
* (b) f ~ Beta around scrnatd(country, ref year)
* Use scrnatd for `startyear' (or whichever year you trust) to center the Beta.
gen f_centre=scrnatd
qui sum f_centre
local grmn=r(mean)
replace f_centre=`grmn' if f_centre==.
*this is for the next section but this is the baseline
gen p0_mean=scrnatt
**# Bookmark #2
*alpha_f, beta_f per sim×country
qui merge m:1 country using `attrESS', nogen
gen double f = .
replace f = invibeta(alpha_f, beta_f,runiform())
qui drop scrnatd scrnatt
merge 1:m sim country using `tempf', nogen
sort sim country year
*list sim-scrnatt if year==2026 & country==1 & sim<=50, clean noobs
*list sim-scrnatt in 1/50


*==========================
* DRAW YEAR-SPECIFIC RANDOMS
*==========================
* (c) Deaths: D ~ LogNormal(mu, sigma) per year×country
gen double D = exp(rnormal(`mu', `sigma'))

* (d) Attendance: p0 from scrnatt(year,country); p1 from scenario mean
* Use Beta around scrnatt with ESS=`p_ESS'
* --- baseline p0: from the year value ---
//p0_mean already there
gen double alpha_p0 = max(p0_mean*`p_ESS', 1e-6)
gen double beta_p0  = max((1 - p0_mean) * `p_ESS', 1e-6)
gen double p0 = invibeta(alpha_p0, beta_p0, runiform())
replace p0 = min(p0, 0.80)
drop f_centre alpha_f beta_f alpha_p0 beta_p0


*==========================
* LOOP OVER SCENARIOS, BUILD RESULTS
*==========================
tempfile all_annual all_cum
capture postclose postA
capture postclose postC

* define postfiles for annual and cumulative outputs
tempname postA postC
postfile `postA' int(country) int(year) byte(scn) double(p50 p2_5 p97_5) using `all_annual', replace
postfile `postC' int(country) int(year) byte(scn) double(cump50 cump2_5 cump97_5) using `all_cum', replace

foreach j of local scenarios {
	* Intervention attendance is paired with the corresponding baseline draw
	gen double p1_`j' = p0
	if `j'==1 {
		replace p1_`j' = min(p0 + 0.05, 0.80) if year >= `policy_start'
	}
	else if `j'==2 {
		replace p1_`j' = min(p0 + 0.10, 0.80) if year >= `policy_start'
	}
	else if `j'==3 {
		replace p1_`j' = 0.40 if year >= `policy_start'
	}

    * ITT mapping
    gen double RRi_p0_`j' = 1 - p0     * (1 - RR_attend)
    gen double RRi_p1_`j' = 1 - p1_`j' * (1 - RR_attend)

    * Annual prevented deaths
    gen double dAvert_`j' = D * f * (RRi_p0_`j' - RRi_p1_`j')

    * Cumulative prevented deaths within each sim × country
    bys sim country (year): gen double dAvertCum_`j' = sum(dAvert_`j')
	
    * Summaries by country × year
	preserve
        keep sim country year dAvert_`j' dAvertCum_`j'    
        /* Compute 2.5th, 50th, 97.5th percentiles by (country year)
           using centile (supports fractional percentiles) */
        statsby p2_5=r(c_1) p50=r(c_2) p97_5=r(c_3), by(country year) clear: ///
            centile dAvert_`j', centile(2.5 50 97.5)
        gen scn = `j'
        sort country year
        quietly {
            /* post annual */
            levelsof country, local(cl)
            foreach c of local cl {
                levelsof year if country==`c', local(yl)
                foreach y of local yl {
                    su p50   if country==`c' & year==`y', meanonly
                    local P50 = r(mean)
                    su p2_5  if country==`c' & year==`y', meanonly
                    local L95 = r(mean)
                    su p97_5 if country==`c' & year==`y', meanonly
                    local U95 = r(mean)
                    post `postA' (`c') (`y') (`j') (`P50') (`L95') (`U95')
                }
            }
        }
    restore		

	preserve
        keep sim country year dAvertCum_`j'
        /* Compute 2.5th, 50th, 97.5th percentiles by (country year)
           using centile (supports fractional percentiles). This
           reproduces the same variable names you used with collapse. */
        statsby cump2_5=r(c_1) cump50=r(c_2) cump97_5=r(c_3), by(country year) clear: ///
            centile dAvertCum_`j', centile(2.5 50 97.5)
        gen scn = `j'
        sort country year
        quietly {
            levelsof country, local(cl2)
            foreach c of local cl2 {
                levelsof year if country==`c', local(yl2)
                foreach y of local yl2 {
                    su cump50   if country==`c' & year==`y', meanonly
                    local CP50 = r(mean)
                    su cump2_5  if country==`c' & year==`y', meanonly
                    local CL95 = r(mean)
                    su cump97_5 if country==`c' & year==`y', meanonly
                    local CU95 = r(mean)
                    post `postC' (`c') (`y') (`j') (`CP50') (`CL95') (`CU95')
                }
            }
        }
    restore

    * Clean up scenario-specific temps to avoid clutter if you loop many countries/years
    drop p1_`j' RRi_p0_`j' RRi_p1_`j' dAvert_`j' dAvertCum_`j'
}

postclose `postA'
postclose `postC'

*==========================
* COLLECT & LABEL OUTPUTS
*==========================
use `all_annual', clear
label var p50   "Annual prevented deaths (median)"
label var p2_5  "Annual prevented deaths (Lo95)"
label var p97_5 "Annual prevented deaths (Hi95)"
tempfile A
save `A', replace

use `all_cum', clear
label var cump50   "Cumulative prevented deaths (median)"
label var cump2_5  "Cumulative prevented deaths (Lo95)"
label var cump97_5 "Cumulative prevented deaths (Hi95)"
tempfile C
save `C', replace

merge 1:1 country year scn using `A', nogen
order country year scn p50 p2_5 p97_5 cump50 cump2_5 cump97_5
sort country year scn

* Scenario labels (like your notes)
lab def scn 1 "abs +5pp" 2 "abs +10pp" 3 "fixed 40%"
lab val scn scn

notes: Baseline attendance p0 is drawn from a Beta distribution with ESS=`p_ESS'.
notes: Scenario attendance is paired with p0: scenario 1 adds 5 percentage points, scenario 2 adds 10 percentage points, and scenario 3 sets attendance to 40%.
notes: Attendance is capped at 80%. Policy changes start in `policy_start'.

compress
describe
notes

* Save outputs
qui save "05-BCfem_psa_results.dta", replace
export excel using "05-BCfem_psa_results.xlsx", firstrow(variables) replace

* LOG → HTML (your style)
qui log close log1
capture qui log2html "05-PSA_MonteCarlo", replace ti("PSA prevented deaths")

*******************************************************
* END
*******************************************************

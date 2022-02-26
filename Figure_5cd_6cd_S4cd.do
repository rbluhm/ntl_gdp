clear *
set more off

** path
global mainpath "/bigstore/Dropbox/Nighttime_lights_and_DIDs/Draft/Replication/"
cd $mainpath

** DO NOT RUN THIS WHOLE FILE IF YOU DO NOT HAVE R AND INTEND 
** TO CREATE ALL SIMULATED PARTITIONS FIRST, INSTEAD RUN ONLY
** LINES 1 TO 40 AND 116 TO 182 TO USED PREVIOUSLY COMPUTED
** RESULTS AND CREATE THE PLOTS

** some options only work with Stata >= 15
** create a modified scheme using:
* ssc install grstyle, replace
* ssc install palettes, replace
* ssc install colrspace, replace
		
* new scheme
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle gsize axis_title_gap small
grstyle gsize axis_label_gap small
grstyle gsize axis_title small
grstyle clockdir legend_position 10
grstyle numstyle legend_rows 2
grstyle linestyle legend none
grstyle gridringstyle legend_ring 0
grstyle gsize text small
grstyle gsize body small
grstyle gsize label small    
grstyle gsize key_label small
grstyle gsize tick_label small
grstyle symbol p2 triangle
grstyle color p1markline navy
grstyle color p1markfill navy%50
grstyle color p2markline maroon
grstyle color p2markfill maroon%50
grstyle color legend none

*** create matrix of results
postfile buffer bhat1 ci_b1_lb ci_b1_ub r2w ///
	bhat1_inter ci_b1_inter_lb ci_b1_inter_ub ///
	bhat2_inter ci_b2_inter_lb ci_b2_inter_ub ///
	r2w_inter plan using ./data/brazil/mcs_1000_gdp_200steps, replace

forvalues i=0(200)5550 {

if `i' == 0 local i = 50
dis `i'
import delimited ./data/brazil/test_plans_`i'.csv, clear 
ren cd_geocmu  CD_GEOCMU
save ./data/brazil/current_stub.dta, replace

use ./data/brazil/fullpanel.dta, clear


duplicates report CD_GEOCMU year

merge m:1 CD_GEOCMU  using ./data/brazil/current_stub.dta

drop if _merge==2
drop _merge

forvalues j=1(1)1000 {
	
quietly {

preserve
gcollapse (sum) gdp_real pop=population area_dmsp sumlight_sl, by(v`j' year)

ren v`j' plan

replace sumlight_sl = . if sumlight_sl == 0 
gen ln_gdp_area_real = ln(gdp_real/area_dmsp)
gen ln_sl_area = ln(sumlight_sl/area_dmsp)
gen ln_pop_dens_dmsp = ln(pop/area_dmsp)
drop if missing(sumlight_sl)
by plan (year): gen ln_pop_dens_dmsp_first = ln_pop_dens_dmsp[1]

** run on the full county data 
local yvar "ln_sl_area"
local xvar "ln_gdp_area_real"
local basevar "ln_pop_dens_dmsp_first"

* sample fits already
sum  `basevar', meanonly
replace `basevar' =  `basevar' - `r(mean)'
cap reghdfe `yvar' `xvar', a(plan year) cluster(plan) keepsingletons 
local bhat1 = _b[`xvar']
local ci_b1_lb = _b[`xvar'] -  invttail(e(df_r), 0.025) * _se[`xvar']
local ci_b1_ub = _b[`xvar'] +  invttail(e(df_r), 0.025) * _se[`xvar']

local r2w = e(r2_within)

cap reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(plan year) cluster(plan) keepsingletons 

post buffer (`bhat1') (`ci_b1_lb') (`ci_b1_ub') (`r2w') ///
	(_b[c.`xvar']) ///
	(_b[c.`xvar'] -  invttail(e(df_r), 0.025) * _se[c.`xvar']) ///
	(_b[c.`xvar'] +  invttail(e(df_r), 0.025) * _se[c.`xvar']) ///
	(_b[c.`xvar'#c.`basevar']) ///
	(_b[c.`xvar'#c.`basevar'] -  invttail(e(df_r), 0.025) * _se[c.`xvar'#c.`basevar']) ///
	(_b[c.`xvar'#c.`basevar'] +  invttail(e(df_r), 0.025) * _se[c.`xvar'#c.`basevar']) ///
	(e(r2_within)) (`i')
restore

}

}
}

postclose buffer

*** plot results

use ./data/brazil/mcs_1000_gdp_200steps, clear
summarize
cd ./figures/

** Figure 5 panels cd

cap drop h x
twoway__histogram_gen bhat1_inter, percent gen(h x)
su h, meanonly
loc max = 40 //1.1*r(max) 
qui su bhat1_inter, d
loc mean = r(mean)
tw (hist bhat1_inter,  color(navy%50)) ///
   (kdensity bhat1_inter, color(maroon)) ///
   (function y=`mean', hor ra(0 `max') color(forest_green)), ///
   xtitle("") ytitle("Density") ///
   legend(order(1 "Histogram" 2 "Density" 3 "Average") rows(3) ring(0) pos(11))
graph export figure_5c_density.pdf, replace

cap drop h x
sum bhat2_inter
twoway__histogram_gen bhat1_inter, percent gen(h x)
su h
loc max = 80 // 1.1*r(max)
qui su bhat2_inter, d
loc mean = r(mean)
tw (hist bhat2_inter,  color(navy%50)) ///
   (kdensity bhat2_inter, color(maroon)) ///
   (function y=`mean', hor ra(0 `max') color(forest_green)), ///
   xtitle("") ytitle("Density") ///
   legend(order(1 "Histogram" 2 "Density" 3 "Average") rows(3) ring(0) pos(11))
graph export figure_5d_density.pdf, replace

** Figure 6 panels cd

graph box bhat1_inter, over(plan, label(alt ticks) )  ///
	ytitle("Elasticity at average population density")  note("") ///
	marker(1, msymbol(o) mcolor(maroon%50) mfcolor(maroon%50) mlcolor(maroon%50) msize(vsmall))
graph export figure_6c_cond_density.pdf, replace

graph box bhat2_inter, over(plan, label(alt ticks) )  ///
 	marker(1, msymbol(o) mcolor(maroon%50) ///
	mfcolor(maroon%50) mlcolor(maroon%50) msize(vsmall)) ///
	note("") ytitle("Interaction effect with population density") 
graph export figure_6d_cond_density.pdf, replace

** Figure S4 panels cd

cap drop h x
twoway__histogram_gen bhat1, percent gen(h x)
su h, meanonly
loc max =  40 // 1.1*r(max) 
qui su bhat1, d
loc mean = r(mean)
tw (hist bhat1,  color(navy%50)) ///
   (kdensity bhat1, color(maroon)) ///
   (function y=`mean', hor ra(0 `max') color(forest_green)), ///
   xtitle("") ytitle("Density") ///
   legend(order(1 "Histogram" 2 "Density" 3 "Average") rows(3) ring(0) pos(1))
graph export figure_s4c_density.pdf, replace

graph box bhat1, over(plan, label(alt ticks) )  ///
	ytitle("Elasticity")  note("") ///
	marker(1, msymbol(o) mcolor(maroon%50) mfcolor(maroon%50) mlcolor(maroon%50) msize(vsmall))
graph export figure_s4d_cond_density.pdf, replace

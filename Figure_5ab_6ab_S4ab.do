clear *
set more off

** path
global mainpath "~/Dropbox/Nighttime_lights_and_DIDs/Draft/Replication/"
cd $mainpath

** DO NOT RUN THIS WHOLE FILE IF YOU DO NOT HAVE R AND INTEND 
** TO CREATE ALL SIMULATED PARTITIONS FIRST, INSTEAD RUN ONLY
** LINES 1 TO 40 AND 118 TO 183 TO LOAD PREVIOUSLY COMPUTED
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
	r2w_inter plan using ./data/usa/mcs_1000_gdp_200steps, replace

forvalues i=0(200)3000 {

if `i' == 0 local i = 50
dis `i'
import delimited ./data/usa/test_plans_`i'.csv", clear 
gen id = _n
save ./data/current_stub.dta, replace

use ./data/usa/fullpanel.dta, clear

egen id = group(idn)
merge m:1 id  using ./data/usa/current_stub.dta


forvalues j=1(1)1000 {
	
quietly {

preserve
gcollapse (sum) gdp_real pop=population area_dmsp area_viirs sumlight_sl, by(v`j' year)

ren v`j' plan

gen gdppc_real = gdp_real / pop
gen ln_gdp_pc_real = ln(gdppc_real)

gen gdp_area_real = gdp_real / area_dmsp
gen ln_gdp_area_real = ln(gdp_area_real)

replace sumlight_sl = . if sumlight_sl == 0 
gen ln_sl_pc = ln(sumlight_sl/pop)
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

use ./data/usa/mcs_1000_200steps_gdp, clear
summarize
cd ./figures/

** Figure 5 panels ab

cap drop h x
twoway__histogram_gen bhat1_inter, percent gen(h x)
su h, meanonly
loc max = 20 // 1.1*r(max) 
qui su bhat1_inter, d
loc mean = r(mean)
tw (hist bhat1_inter,  color(navy%50)) ///
   (kdensity bhat1_inter, color(maroon)) ///
   (function y=`mean', hor ra(0 `max') color(forest_green)), ///
   xtitle("") ytitle("Density") ///
   legend(order(1 "Histogram" 2 "Density" 3 "Average") rows(3) ring(0) pos(1))
graph export figure_5a_density.pdf, replace

cap drop h x
twoway__histogram_gen bhat2_inter, percent gen(h x)
su h, meanonly
loc max = 30 //1.1*r(max)
qui su bhat2_inter, d
loc mean = r(mean)
tw (hist bhat2_inter,  color(navy%50)) ///
   (kdensity bhat2_inter, color(maroon)) ///
   (function y=`mean', hor ra(0 `max') color(forest_green)), ///
   xtitle("") ytitle("Density") ///
   legend(order(1 "Histogram" 2 "Density" 3 "Average") rows(3) ring(0) pos(1))
graph export figure_5b_density.pdf, replace

** Figure 6 panels ab

graph box bhat1_inter, over(plan, label(alt ticks) )  ///
	ytitle("Elasticity at average population density")  note("") ///
	marker(1, msymbol(o) mcolor(maroon%50) mfcolor(maroon%50) mlcolor(maroon%50) msize(vsmall))
graph export figure_6a_cond_density.pdf, replace
graph export ga_3.png, replace

graph box bhat2_inter, over(plan, label(alt ticks) )  ///
 	marker(1, msymbol(o) mcolor(maroon%50) mfcolor(maroon%50) mlcolor(maroon%50) msize(vsmall)) ///
	note("") ytitle("Interaction effect with population density") 
graph export figure_6b_cond_density.pdf, replace

** Figure S4 panels ab

cap drop h x
twoway__histogram_gen bhat1, percent gen(h x)
su h, meanonly
loc max =  15 // 1.1*r(max) 
qui su bhat1, d
loc mean = r(mean)
tw (hist bhat1,  color(navy%50)) ///
   (kdensity bhat1, color(maroon)) ///
   (function y=`mean', hor ra(0 `max') color(forest_green)), ///
   xtitle("") ytitle("Density") ///
   legend(order(1 "Histogram" 2 "Density" 3 "Average") rows(3) ring(0) pos(1))
graph export figure_s4a_density.pdf, replace


graph box bhat1, over(plan, label(alt ticks) )  ///
	ytitle("Elasticity")  note("") ///
	marker(1, msymbol(o) mcolor(maroon%50) mfcolor(maroon%50) mlcolor(maroon%50) msize(vsmall))
graph export figure_s4b_cond_density.pdf, replace

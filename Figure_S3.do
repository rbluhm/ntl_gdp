clear *
set more off 

** path
global mainpath "~/Dropbox/Nighttime_lights_and_DIDs/Draft/Replication/"
cd $mainpath
		
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

use ./data/allcountries.dta, clear
rename idn idn_country
egen idn = group(country idn_country)

replace ln_viirs_area = . if year<=2013
replace ln_viirs_pc = . if year<=2013

* Run for year<2014 for DMSP with extension, redoing the initial year variables:
keep if year<=2013
sort idn year
gen ln_gdp_area_real_dmsp_first = .
by idn (year): replace ln_gdp_area_real_dmsp_first = ln_gdp_area_real[1]
by idn (year): replace ln_gdp_pc_real_dmsp_first = ln_gdp_pc_real[1]
by idn (year): replace ln_gdp_pc_current_dmsp_first = ln_gdp_pc_current[1]
by idn (year): replace ln_gdp_agri_real_dmsp_first = ln_gdp_agri_real[1]
by idn (year): replace ln_gdp_ind_real_dmsp_first = ln_gdp_ind_real[1]
by idn (year): replace ln_gdp_serv_real_dmsp_first = ln_gdp_serv_real[1]
by idn (year): replace ln_gdp_agri_current_dmsp_first = ln_gdp_agri_current[1]
by idn (year): replace ln_gdp_ind_current_dmsp_first = ln_gdp_ind_current[1]
by idn (year): replace ln_gdp_serv_current_dmsp_first = ln_gdp_serv_current[1]
by idn (year): replace ln_pop_dens_dmsp_first = ln_pop_dens_dmsp[1]


replace country = "USA" if country=="USA_gdp"

label var ln_gdp_pc_real "ln(GDP pc in Const Prices)"
label var ln_gdp_pc_current "Current GDP pc"
label var ln_gdp_real "ln(GDP in Const Prices)"
label var ln_gdp_area_real "ln(GDP dens in Const Prices)"
label var ln_gdp_current "Current GDP"
label var ln_sl_area "ln(Sum of DMSP Rad per sq. km)"
label var ln_sl_pc "ln(Sum of DMSP Rad per capita)"
label var ln_cl_area "ln(Sum of Corrected DMSP Rad per sq. km)"
label var ln_cl_pc "ln(Sum of Corrected DMSP Rad per capita)"
label var ln_gdp_agri_real "ln(Agri GDP dens, Const Prices)"
label var ln_gdp_ind_real "ln(Ind GDP dens, Const Prices)"
label var ln_gdp_serv_real "ln(Serv GDP dens, Const Prices)"
label var ln_gdp_pc_agri_real "ln(Agri GDP pc, Const Prices)"
label var ln_gdp_pc_ind_real "ln(Ind GDP pc, Const Prices)"
label var ln_gdp_pc_serv_real "ln(Serv GDP pc, Const Prices)"
label var ln_pop_dens_dmsp "ln(Pop Density)"
label var sumlight_sl "Sum of DMSP Radiance"


cd "figures"

** Figure S3: Marginal Effects 
estimates clear
local yvar "ln_sl_area"
local xvar "ln_gdp_area_real"
local basevar "ln_pop_dens_dmsp_first"

local analysiscountries "USA Germany Italy Spain Brazil China" 

foreach countryname of local analysiscountries {
	preserve 
		keep if country=="`countryname'"
		qui reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		sum  `basevar' if e(sample), detail
		replace `basevar' =  `basevar' - `r(mean)'
		reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		quietly summarize `basevar' if e(sample), detail
		local temp =  r(p5)
		local z_p5: display %6.1f `temp'
		local temp = r(p95)
		local z_p95: display %6.1f `temp'
		local step = (`z_p95'-`z_p5')/10
		disp `step'
		quietly margins, dydx(`xvar') at(`basevar'=(-4(0.5)4))
		marginsplot, title("") name(margins`countryname', replace)
		marginsplot, title("") name(margins`countryname', replace) ylabel(, angle(vertical)) xtitle("") xlabel(#9)  xtick(#18) addplot(hist `basevar' if `basevar'>=-4 & `basevar'<=4 , yaxis(2) yscale(alt axis(2)) below width(0.5) fcolor(gs12%30) lcolor(gs12%0) legend(off))
		graph export "figure_s3_`countryname'.png", as(png) replace
	restore
}

clear *
set more off 

** path
global mainpath "/bigstore/Dropbox/Nighttime_lights_and_DIDs/Draft/Replication/"
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

* create initial year variables:
sort idn year
drop *_first
by idn (year): gen ln_gdp_area_real_dmsp_first = ln_gdp_area_real[1]
by idn (year): gen ln_gdp_pc_real_dmsp_first = ln_gdp_pc_real[1]
by idn (year): gen ln_gdp_pc_current_dmsp_first = ln_gdp_pc_current[1]
by idn (year): gen ln_gdp_agri_real_dmsp_first = ln_gdp_agri_real[1]
by idn (year): gen ln_gdp_ind_real_dmsp_first = ln_gdp_ind_real[1]
by idn (year): gen ln_gdp_serv_real_dmsp_first = ln_gdp_serv_real[1]
by idn (year): gen ln_gdp_agri_current_dmsp_first = ln_gdp_agri_current[1]
by idn (year): gen ln_gdp_ind_current_dmsp_first = ln_gdp_ind_current[1]
by idn (year): gen ln_gdp_serv_current_dmsp_first = ln_gdp_serv_current[1]
by idn (year): gen ln_pop_dens_dmsp_first = ln_pop_dens_dmsp[1]


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

** Figure 1: Bivariate scatter plots

foreach cname in "USA" "Italy" "Germany" "Italy" "Spain" "Brazil" "China" {
	preserve
	keep if country=="`cname'"
		tw (scatter ln_sl_area ln_gdp_area_real) ///
			(lfit ln_sl_area ln_gdp_area_real, lp(shortdash) lc(maroon)) ///
			(qfit ln_sl_area ln_gdp_area_real, lp(longdash) lc(forest_green)), /// 
			legend(rows(3) order(2 "Linear Fit" 3 "Quadratic Fit") pos(5) ring(0)) ///
			ytitle("Log lights per area") xtitle("Log GDP per area") 
			
		graph export "figure_1_`cname'.png", replace	
	restore
}

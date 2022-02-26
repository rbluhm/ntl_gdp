clear *
set more off 

** path
global mainpath "/home/richard/Dropbox/Nighttime_lights_and_DIDs/Draft/Replication/"
cd $mainpath

** options
local regtype = "acreg"
local yvar "ln_sl_area" 
local xvar "ln_gdp_area_real" 
		
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

local analysiscountries "USA Germany Italy Spain Brazil China" 

foreach countryname of local analysiscountries   {
	preserve 
		keep if country=="`countryname'"

		bysort idn: egen avg_x = mean(`xvar') 
		xtile inc_groups = avg_x, nq(4)

		xtset idn year


		if ("`regtype'" == "acreg") {			
			gen inc_groups_1 = (inc_groups==1)*`xvar'
			gen inc_groups_2 = (inc_groups==2)*`xvar'	
			gen inc_groups_3 = (inc_groups==3)*`xvar'	
			gen inc_groups_4 = (inc_groups==4)*`xvar'	
			
			acreg `yvar'  inc_groups_*, id(idn) time(year) spatial ///
				latitude(lat) longitude(lon) pfe1(idn) pfe2(year) ///
				dist(500) lag(1000)  hac  
		} 
		else {
			*unconstrained
			*reghdfe `yvar' i.inc_groups#c.`xvar', absorb(i.inc_groups#i.idn i.inc_groups#i.year) vce(cluster idn)
			*constrained so that year FE are same in each income group
			reghdfe `yvar' i.inc_groups#c.`xvar', absorb(idn  year) vce(cluster idn)
		}

		if ("`regtype'" == "acreg") {	
		nlcom   (theta1: _b[inc_groups_1] /_b[inc_groups_1]) ///
			(theta2: _b[inc_groups_2] /_b[inc_groups_1]) ///
			(theta3: _b[inc_groups_3] /_b[inc_groups_1]) ///
			(theta4: _b[inc_groups_4] /_b[inc_groups_1]), post
		} 
		else {				
		nlcom   (theta1: _b[1.inc_groups#c.`xvar'] /_b[1b.inc_groups#c.`xvar']) ///
			(theta2: _b[2.inc_groups#c.`xvar'] /_b[1b.inc_groups#c.`xvar']) ///
			(theta3: _b[3.inc_groups#c.`xvar'] /_b[1b.inc_groups#c.`xvar']) ///
			(theta4: _b[4.inc_groups#c.`xvar'] /_b[1b.inc_groups#c.`xvar']), post
		}
		est store thetas

		coefplot thetas, yline(1) vertical  legend(off) plotregion(margin(none)) ///
			title("`countryname'") ///
			xlabel(1 "{&theta}{sup:1}" 2 "{&theta}{sup:2}" ///
			       3 "{&theta}{sup:3}" 4 "{&theta}{sup:4}")  ylabel(, angle(vertical)) ///
       			saving(gdp_thetas_`countryname'.gph, replace)

	restore
 
}


graph combine gdp_thetas_USA.gph gdp_thetas_Germany.gph gdp_thetas_Italy.gph ///
	gdp_thetas_Spain.gph gdp_thetas_Brazil.gph gdp_thetas_China.gph, ///
	xcommon
graph export figure_s2_thetas.pdf, replace 

!rm *.gph

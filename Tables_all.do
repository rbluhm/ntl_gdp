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

replace ln_viirs_area = . if year<=2013
replace ln_viirs_pc = . if year<=2013

* Run for year<2014 for DMSP, redoing the initial year variables:
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
drop if country=="UK" | country=="USA_inc"

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

local analysiscountries "USA Germany Italy Spain Brazil China" 

cd "tables"

* Table 2 Summary Statistics similar to HSW 2012 Table 1:
preserve
gen zerosumlight = (sumlight_sl==0)
label var zerosumlight "% regions with zero nightlights"
keep country zerosumlight sumlight_sl ln_gdp_area_real ln_gdp_pc_real ln_pop_dens_dmsp ///
	ln_gdp_agri_real ln_gdp_ind_real ln_gdp_serv_real  ln_gdp_pc_agri_real ln_gdp_pc_ind_real ///
	ln_gdp_pc_serv_real
order zerosumlight sumlight_sl ln_gdp_area_real ln_gdp_pc_real ln_pop_dens_dmsp ///
	ln_gdp_agri_real ln_gdp_ind_real ln_gdp_serv_real  ln_gdp_pc_agri_real ln_gdp_pc_ind_real ///
	ln_gdp_pc_serv_real
local tablename "table_2_sumstats"
local replace "replace"
foreach countryname in "USA" "Germany" "Italy" "Spain" "Brazil" "China"  {
	outreg2 using "`tablename'" if country=="`countryname'", `replace' sum(log) tex(frag) eqkeep(N mean ) label cttop("`countryname'") 
	local replace "append"
}
restore
**/

** Table 3a: comparing uninteracted and interacted with GDP in constant prices and base levels of population density
** No interaction:
estimates clear
local yvar "ln_sl_area"
local xvar "ln_gdp_area_real"
local outtable "table_3a_short"
foreach countryname of local analysiscountries {
	preserve 
		keep if country=="`countryname'"
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar', a(idn year) cluster(idn) keepsingletons

	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP")
		
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP") ///
		addnotes(Dependent variable: `yvar') ///
		mtitles
**/
** Table 3b: GDP in constant prices and base levels of population density
estimates clear
local yvar "ln_sl_area"
local xvar "ln_gdp_area_real"
local basevar "ln_pop_dens_dmsp_first"
local outtable "table_3a_long"
foreach countryname of local analysiscountries {
	preserve 
		keep if country=="`countryname'"
		qui reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		sum  `basevar' if e(sample), detail
		replace `basevar' =  `basevar' - `r(mean)'
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons

	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP" c.`xvar'#c.`basevar' "Real GDP * Z")
		
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP" c.`xvar'#c.`basevar' "Real GDP * Z") ///
		addnotes(Dependent variable: `yvar') ///
		mtitles
**/


** Table 4: DMSP GDP with no interaction in constant prices - by Sector
estimates clear
local analysiscountries "USA Germany Italy Spain Brazil" 
local yvar "ln_sl_area"
local xvar "ln_gdp_agri_real"
local outtable "table_4_agr"
foreach countryname of local analysiscountries  {
	preserve 
		keep if country=="`countryname'"
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar', a(idn year) cluster(idn) keepsingletons 
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Agri")
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Agri") ///
		mtitles
** DMSP: GDP with no interactions in constant prices - Industry
estimates clear
local yvar "ln_sl_area"
local xvar "ln_gdp_ind_real"
local outtable "table_4_ind"
foreach countryname of local analysiscountries  {
	preserve 
		keep if country=="`countryname'"
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar', a(idn year) cluster(idn) keepsingletons 
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Industry")
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Industry") ///
		mtitles
** DMSP: GDP and base levels of population density in constant prices - Services
estimates clear
local yvar "ln_sl_area"
local xvar "ln_gdp_serv_real"
local outtable "table_4_srv"
foreach countryname of local analysiscountries  {
	preserve 
		keep if country=="`countryname'"
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar', a(idn year) cluster(idn) keepsingletons 
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Services")	
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Services") ///
		addnotes(Dependent variable: `yvar') ///
		mtitles
**/

** Table 5: DMSP GDP and base levels of population density in constant prices - Agriculture, Industry and Services
estimates clear
local yvar "ln_sl_area"
local xvar "ln_gdp_agri_real"
local basevar "ln_pop_dens_dmsp_first"
local outtable "table_5_agr"
foreach countryname of local analysiscountries  {
	preserve 
		keep if country=="`countryname'"
		qui reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		sum  `basevar' if e(sample), detail
		replace `basevar' =  `basevar' - `r(mean)'
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons 
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Agri" c.`xvar'#c.`basevar' "Real GDP in Agri * Z")
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Agri" c.`xvar'#c.`basevar' "Real GDP in Agri * Z") ///
		mtitles
** Industry
estimates clear
local xvar "ln_gdp_ind_real"
local outtable "table_5_ind"
foreach countryname of local analysiscountries  {
	preserve 
		keep if country=="`countryname'"
		qui reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		sum  `basevar' if e(sample), detail
		replace `basevar' =  `basevar' - `r(mean)'
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons 
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Industry" c.`xvar'#c.`basevar' "Real GDP in Industry * Z")
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Industry" c.`xvar'#c.`basevar' "Real GDP in Industry * Z") ///
		mtitles
** Services
estimates clear
local xvar "ln_gdp_serv_real"
local outtable "table_5_srv"
foreach countryname of local analysiscountries  {
	preserve 
		keep if country=="`countryname'"
		qui reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		sum  `basevar' if e(sample), detail
		replace `basevar' =  `basevar' - `r(mean)'
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons 
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Services" c.`xvar'#c.`basevar' "Real GDP in Services * Z")
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP in Services" c.`xvar'#c.`basevar' "Real GDP in Services * Z") ///
		addnotes(Dependent variable: `yvar') ///
		mtitles
**/

*************** SUPPLEMENTARY MATERIAL

** Appendix Table S1a: Corrected Lights: comparing uninteracted and interacted with GDP in constant prices and base levels of population density
** No interaction:
estimates clear
local yvar "ln_cl_area"
local xvar "ln_gdp_area_real"
local outtable "table_s1a"
foreach countryname of local analysiscountries {
	preserve 
		keep if country=="`countryname'"
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar', a(idn year) cluster(idn) keepsingletons

	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP")
		
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP") ///
		addnotes(Dependent variable: `yvar') ///
		mtitles
**/
** Appendix Table S1b: Corrected Lights: GDP in constant prices and base levels of population density
estimates clear
local yvar "ln_cl_area"
local xvar "ln_gdp_area_real"
local basevar "ln_pop_dens_dmsp_first"
local outtable "table_s1b"
foreach countryname of local analysiscountries {
	preserve 
		keep if country=="`countryname'"
		qui reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
		sum  `basevar' if e(sample), detail
		replace `basevar' =  `basevar' - `r(mean)'
		eststo, title("`countryname'"): reghdfe `yvar' c.`xvar' c.`xvar'#c.`basevar', a(idn year) cluster(idn) keepsingletons
	
	restore
}
esttab, b(3) se(3) sfmt(a3) /// 
		scalars(N_clust N) ///
		noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP" c.`xvar'#c.`basevar' "Real GDP * Z")
		
esttab using "`outtable'.tex", replace tex ///
		b(3) se(3) sfmt(a3) scalars(N_clust N) noobs nocons /// 
		star(* 0.10 ** 0.05 *** 0.01) ///
		coeflabels(`xvar' "Real GDP" c.`xvar'#c.`basevar' "Real GDP * Z") ///
		addnotes(Dependent variable: `yvar') ///
		mtitles
**/


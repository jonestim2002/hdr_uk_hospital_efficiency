*** Hip/Knee electives - a few new checks suggested by Andy J. ***
cd "\\ads.bris.ac.uk\filestore\HealthSci SafeHaven\HDRUK\Hip Knee 1320\Hip Knee Joinpoint"
set more off

local newey_west_lag 2

* Create a useful hip/knee elective dataset
*use "\\ads.bris.ac.uk\filestore\HealthSci SafeHaven\HDRUK\Hip Knee 1320\Hip Knee_electives 1320\data\HipKnee_1321.dta", clear

* Possibly update to newer dataset
use "\\ads.bris.ac.uk\filestore\HealthSci SafeHaven\HDRUK\Hip Knee 1320\Hip Knee_electives 1320\data\HipKnee_1321_2021-11-24.dta", clear


* Create seasons
gen season = 0
replace season = 1 if inlist(admission_month, 3, 4, 5)
replace season = 2 if inlist(admission_month, 6, 7, 8)
replace season = 3 if inlist(admission_month, 9, 10, 11)

* Dummy variables just for summer and winter
gen summer = cond(season == 2, 1, 0)
gen winter = cond(season == 0, 1, 0)


* Check hip vs knee electives
gen surgery_site_num = .
replace surgery_site_num = 0 if surgery_site == "Site: hip"
replace surgery_site_num = 1 if surgery_site == "Site: knee"
drop if surgery_site_num == . // Here I drop any we're uncertain about the site of surgery

* Primary
gen primary = .
replace primary = 1 if confirmed_proc == "Confirmed primary"
replace primary = 0 if confirmed_proc == "Confirmed revision"

* Sex
gen sex_num = 0
replace sex_num = 1 if sex == "Female"

* Most deprived flag
gen most_deprived_flag = .
replace most_deprived_flag = 0 if imd <= 3
replace most_deprived_flag = 1 if imd >= 4 & imd ~= .

* Any comorbidities
gen comorbidities = 0
replace comorbidities = 1 if index_cci > 1

* High comorbidities
gen high_comorb = cond(score_cci >= 2, 1, 0)

* Andy J suggests to only look at confirmed primaries and no revisions
keep if primary == 1

keep if admission_yr >= 2016 & admission_yr <= 2019

* Limit to just the time period we're most interested in 2016-2019

save "hip_knee_data", replace

************************

* Do some trend analysis by admission date
use "hip_knee_data", clear

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (count) freq=id (mean) age=age_on_admission dep=imd prop_comorb=comorbidities prop_high_comorb=high_comorb prop_prim=primary prop_women=sex_num prop_dep=most_deprived_flag spell_los (sum) num_women=sex_num high_comorb most_deprived_flag, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 26 if month_index >= 26

save "hip_knee_admissions", replace

**************************

* Store the model results into a postfile
postfile model_results str30 model_name trend_rr trend_lci trend_uci trend_p levelchange_rr levelchange_lci levelchange_uci levelchange_p slopechange_rr slopechange_lci slopechange_uci slopechange_p spring_rr spring_lci spring_uci spring_p summer_rr summer_lci summer_uci summer_p autumn_rr autumn_lci autumn_uci autumn_p using "model_results.dta", replace

use "hip_knee_admissions", clear

* Lowess curves and best fit line
lowess freq month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess freq month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm freq month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), family(poisson) link(log) vce(hac nwest `newey_west_lag') eform  // recommendation to use integer part of n^0.25 as maximum lag (see Bottomley, Christian, Scott, J. Anthony G. and Isham, Valerie. "Analysing Interrupted Time Series with a Control" Epidemiologic Methods, vol. 8, no. 1, 2019, pp. 20180010. https://doi.org/10.1515/em-2018-0010)
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Admissions") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

glm freq month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), family(poisson) link(log) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Admissions") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num freq hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\admissions.dta", replace

******

* Look at pattern by age_on_admission
use "hip_knee_admissions", clear

lowess age month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess age month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm age month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Age") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm age month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Age") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num age hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\age_admissions.dta", replace

******

* Look at pattern by proportion women
use "hip_knee_admissions", clear

lowess prop_women month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess prop_women month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm num_women month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), family(poisson) link(log) exposure(freq) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Prop Women") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

glm num_women month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), family(poisson) link(log) exposure(freq) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Prop Women") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num prop_women hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\women_admissions.dta", replace


******

* Look at pattern by proportion with 2+ Charlson comorbidities
use "hip_knee_admissions", clear

lowess prop_high_comorb month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess prop_high_comorb month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm high_comorb month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), family(poisson) link(log) exposure(freq) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Charlson") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

glm high_comorb month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), family(poisson) link(log) exposure(freq) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Charlson") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num prop_high_comorb hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\charlson_admissions.dta", replace


*****

* Look at pattern by proportion higher deprivation (quintiles 4/5)
use "hip_knee_admissions", clear

lowess prop_dep month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess prop_dep month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm most_deprived_flag month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), family(poisson) link(log) exposure(freq) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Deprivation") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

glm most_deprived_flag month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), family(poisson) link(log) exposure(freq) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Deprivation") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num prop_dep hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\deprivation_admissions.dta", replace

*****

***** LENGTH OF STAY ********

* Pattern of average length of stay (LoS is not normally distributed so mean may be incorrect)
use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30  // 32 extreme values dropped (none missing)

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here


glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\length_of_stay.dta", replace

******************

* Length of stay by age group: 16-59

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if age_on_admission <= 59

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Age 16-59") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here


glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Age 16-59") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_age16_59.dta", replace

****


* Length of stay by age group: 60-69

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if age_on_admission >= 60 & age_on_admission <= 69

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Age 60-69") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Age 16-59") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_age60_69.dta", replace

****

* Length of stay by age group: 70-79

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if age_on_admission >= 70 & age_on_admission <= 79

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Age 70-79") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Age 70-79") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_age70_79.dta", replace

****

* Length of stay by age group: 80+

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if age_on_admission >= 80

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Age 80+") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Age 80+") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_age80.dta", replace

***************

* Length of stay by sex: men

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if sex_num == 0

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Men") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Men") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_men.dta", replace

****


* Length of stay by sex: women

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if sex_num == 1

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Women") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Women") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_women.dta", replace

****************************

* Length of stay by comorbidites: 0

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if score_cci == 0

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Charlson 0") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Charlson 0") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_ch0.dta", replace


****


* Length of stay by comorbidities: 1

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if score_cci == 1

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Charlson 1") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Charlson 1") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_ch1.dta", replace

****


* Length of stay by comorbidities: 2+

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if score_cci >= 2

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Charlson 2+") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag') 
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Charlson 2+") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_ch2.dta", replace

**************************************


* Length of stay by deprivation: 1

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if imd == 1

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag') 
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Dep 1") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag') 
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Dep 1") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_dep1.dta", replace

****


* Length of stay by deprivation: 2

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if imd == 2

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Dep 2") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Dep 2") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_dep2.dta", replace

****

* Length of stay by deprivation: 3

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if imd == 3

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Dep 3") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag') 
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Dep 3") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_dep3.dta", replace

****

* Length of stay by deprivation: 4

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if imd == 4

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Dep 4") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Dep 4") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_dep4.dta", replace

****

* Length of stay by deprivation: 5

use "hip_knee_data", clear

* I'm going to use trimmed length of stay at the moment (so only those <= 30 days)
drop if spell_los > 30

keep if imd == 5

gen month_index = ((admission_yr - 2016) * 12) + admission_month
collapse (mean) spell_los, by(month_index admission_month admission_yr surgery_site_num season summer winter)
sort surgery_site_num month_index

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26

lowess spell_los month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess spell_los month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip LoS Dep 5") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm spell_los month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag')
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee LoS Dep 5") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num spell_los hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\los_dep5.dta", replace

***************************************

*** BED OCCUPANCY ***

* Do some trend analysis by bed occupancy - based on Emily's algorithm for bed occupancy BUT I am doing a check for a bed being occupied overnight (i.e. I'm not counting the day of discharge)
use "\\ads.bris.ac.uk\filestore\HealthSci SafeHaven\HDRUK\Hip Knee 1320\Hip Knee_electives 1320\data\HipKnee_1321.dta", clear

* Check hip vs knee electives
gen surgery_site_num = .
replace surgery_site_num = 0 if surgery_site == "Site: hip"
replace surgery_site_num = 1 if surgery_site == "Site: knee"
drop if surgery_site_num == . // Here I drop any we're uncertain about the site of surgery

* Primary
gen primary = .
replace primary = 1 if confirmed_proc == "Confirmed primary"
replace primary = 0 if confirmed_proc == "Confirmed revision"

* Andy J suggests to only look at confirmed primaries and no revisions
keep if primary == 1

drop if spell_los == 0  // Get rid of zero LoS because they don't occupy a bed overnight

sort id admission_date
gen epid = _n // generate an episode id 
expand spell_los // expand by the spell length of stay
sort epid  // sort by episode

gen dateindex = admission_date // generate an index variable
replace dateindex = dateindex[_n-1]+1 if id[_n] == id[_n-1] & epid[_n] == epid[_n-1]
format dateindex %d // format it as a date 

drop admission_month admission_yr

gen admission_month = month(dateindex)
gen admission_yr = year(dateindex)

gen month_index = ((admission_yr - 2016) * 12) + admission_month
keep if admission_yr >= 2016 & admission_yr <= 2019
sort surgery_site_num month_index


collapse (count) bedocc=id, by(surgery_site_num month_index admission_month admission_yr)

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 25 if month_index >= 26


* Create seasons
gen season = 0
replace season = 1 if inlist(admission_month, 3, 4, 5)
replace season = 2 if inlist(admission_month, 6, 7, 8)
replace season = 3 if inlist(admission_month, 9, 10, 11)

gen winter = cond(season == 0, 1, 0)
gen summer = cond(season == 2, 1, 0)

lowess bedocc month_index if surgery_site_num == 0, bwidth(0.3) gen(hip_lowess)
lowess bedocc month_index if surgery_site_num == 1, bwidth(0.3) gen(knee_lowess)

tsset surgery_site_num month_index
glm bedocc month_index stepchange slopechange i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), family(poisson) link(log) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Bed Occ") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

glm bedocc month_index stepchange slopechange i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), family(poisson) link(log) vce(hac nwest `newey_west_lag') eform
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Bed Occ") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = exp(_b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg')  // excluding seasonality here

replace hip_glm_prediction = . if surgery_site_num == 1 | inlist(month_index, 24, 25)
replace knee_glm_prediction = . if surgery_site_num == 0 | inlist(month_index, 24, 25)

keep admission_month admission_yr surgery_site_num bedocc hip_lowess knee_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\bed_occ.dta", replace

***************************

*** public / private ratio
import excel "\\ads.bris.ac.uk\filestore\HealthSci SafeHaven\HDRUK\Hip Knee 1320\Hip Knee Joinpoint\SQL_Script\public_private.xlsx", sheet("Sheet1") firstrow clear
replace provider_type = "Non_NHS" if provider_type == "Non-NHS"
drop if provider_type == "Other"
reshape wide freq, i(operation_site admi_year admi_month) j(provider_type) string
keep if admi_year >= 2016 & admi_year <= 2019 // Keep the same month/year combinations as for the other data
gen pub_priv_ratio = freqNHS / freqNon_NHS

gen month_index = ((admi_year - 2016) * 12) + admi_month

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 26 if month_index >= 26

* Create seasons
gen season = 0
replace season = 1 if inlist(admi_month, 3, 4, 5)
replace season = 2 if inlist(admi_month, 6, 7, 8)
replace season = 3 if inlist(admi_month, 9, 10, 11)

gen winter = cond(season == 0, 1, 0)
gen summer = cond(season == 2, 1, 0)

lowess pub_priv_ratio month_index if operation_site == "hip", bwidth(0.3) gen(hip_ratio_lowess)
lowess pub_priv_ratio month_index if operation_site == "knee", bwidth(0.3) gen(knee_ratio_lowess)

gen operation_num = 0
replace operation_num = 1 if operation_site == "knee"

tsset operation_num month_index
glm pub_priv_ratio month_index stepchange slopechange i.season if operation_num == 0 & ~inlist(month_index, 24, 25), vce(hac nwest 2) eform 
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Hip Public Private") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen hip_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

glm pub_priv_ratio month_index stepchange slopechange i.season if operation_num == 1 & ~inlist(month_index, 24, 25), vce(hac nwest 2) eform 
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Knee Public Private") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen knee_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace hip_glm_prediction = . if inlist(month_index, 24, 25)
replace knee_glm_prediction = . if inlist(month_index, 24, 25)

keep admi_month admi_year operation_num pub_priv_ratio hip_ratio_lowess knee_ratio_lowess hip_glm_prediction knee_glm_prediction
save "Excel_Graph_Data\public_private.dta", replace

******************************


*** elective / emergency ratio
import excel "\\ads.bris.ac.uk\filestore\HealthSci SafeHaven\HDRUK\Hip Knee 1320\Hip Knee Joinpoint\SQL_Script\elective_emergency_data.xlsx", sheet("Sheet1") firstrow clear
reshape wide freq, i(admi_year admi_month) j(admission_type) string
gen elec_emerg_ratio = freqElective / freqEmergency
drop if admi_year == 1900
keep if admi_year >= 2016 & admi_year <= 2019 // Keep the same month/year combinations as for the other data

* Create seasons
gen season = 0
replace season = 1 if inlist(admi_month, 3, 4, 5)
replace season = 2 if inlist(admi_month, 6, 7, 8)
replace season = 3 if inlist(admi_month, 9, 10, 11)

gen winter = cond(season == 0, 1, 0)
gen summer = cond(season == 2, 1, 0)

gen month_index = ((admi_year - 2016) * 12) + admi_month

gen stepchange = 0
replace stepchange = . if inlist(month_index, 24, 25)
replace stepchange = 1 if month_index >= 26

gen slopechange = 0
replace slopechange = month_index - 26 if month_index >= 26

lowess elec_emerg_ratio month_index, bwidth(0.3) gen(ratio_lowess)

tsset month_index
glm elec_emerg_ratio month_index stepchange slopechange i.season if ~inlist(month_index, 24, 25), vce(hac nwest `newey_west_lag') eform  // recommendation to use integer part of n^0.25 as maximum lag (see Bottomley, Christian, Scott, J. Anthony G. and Isham, Valerie. "Analysing Interrupted Time Series with a Control" Epidemiologic Methods, vol. 8, no. 1, 2019, pp. 20180010. https://doi.org/10.1515/em-2018-0010)
local trend_rr = el(r(table), 1, colnumb(r(table), "month_index"))
local trend_lci = el(r(table), 5, colnumb(r(table), "month_index"))
local trend_uci = el(r(table), 6, colnumb(r(table), "month_index"))
local trend_p = el(r(table), 4, colnumb(r(table), "month_index"))
local levelchange_rr = el(r(table), 1, colnumb(r(table), "stepchange"))
local levelchange_lci = el(r(table), 5, colnumb(r(table), "stepchange"))
local levelchange_uci = el(r(table), 6, colnumb(r(table), "stepchange"))
local levelchange_p = el(r(table), 4, colnumb(r(table), "stepchange"))
local slopechange_rr = el(r(table), 1, colnumb(r(table), "slopechange"))
local slopechange_lci = el(r(table), 5, colnumb(r(table), "slopechange"))
local slopechange_uci = el(r(table), 6, colnumb(r(table), "slopechange"))
local slopechange_p = el(r(table), 4, colnumb(r(table), "slopechange"))
local spring_rr = el(r(table), 1, colnumb(r(table), "1.season"))
local spring_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local spring_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local spring_p = el(r(table), 4, colnumb(r(table), "1.season"))
local summer_rr = el(r(table), 1, colnumb(r(table), "2.season"))
local summer_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local summer_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local summer_p = el(r(table), 4, colnumb(r(table), "2.season"))
local autumn_rr = el(r(table), 1, colnumb(r(table), "3.season"))
local autumn_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local autumn_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local autumn_p = el(r(table), 4, colnumb(r(table), "3.season"))
post model_results ("Elec Emerg Ratio") (`trend_rr') (`trend_lci') (`trend_uci') (`trend_p') (`levelchange_rr') (`levelchange_lci') (`levelchange_uci') (`levelchange_p') (`slopechange_rr') (`slopechange_lci') (`slopechange_uci') (`slopechange_p') (`spring_rr') (`spring_lci') (`spring_uci') (`spring_p') (`summer_rr') (`summer_lci') (`summer_uci') (`summer_p') (`autumn_rr') (`autumn_lci') (`autumn_uci') (`autumn_p')
local season_avg = (_b[1.season] + _b[2.season] + _b[3.season]) / 3
gen ratio_glm_prediction = _b[_cons] + (_b[month_index] * month_index) + (_b[stepchange] * stepchange) + (_b[slopechange] * slopechange) + `season_avg' // excluding seasonality here

replace ratio_glm_prediction = . if inlist(month_index, 24, 25)

keep admi_month admi_year elec_emerg_ratio ratio_lowess ratio_glm_prediction
save "Excel_Graph_Data\elec_emerg.dta", replace

postclose model_results

***

use "model_results", clear
gen surgery_type = cond(strpos(model_name, "Hip"), 0, 1)
egen myseq = seq(), by(surgery_type)
sort surgery_type myseq
drop surgery_type myseq


************************

*** Check the overall impact of various variables on Length of Stay
use "hip_knee_data", clear
gen month_index = ((admission_yr - 2016) * 12) + admission_month
drop if spell_los > 30 // A small number of extreme values
egen age_grp = cut(age_on_admission), at(0 60 70 80 160)
egen charlson_grp = cut(score_cci), at(0 1 2 10)

postfile poisson_models str30 varname hip_or hip_lci hip_uci hip_p knee_or knee_lci knee_uci knee_p using "poisson_results", replace
poisson spell_los sex_num i.age_grp i.charlson_grp i.imd i.season if surgery_site_num == 0 & ~inlist(month_index, 24, 25), irr
local women_or = el(r(table), 1, colnumb(r(table), "sex_num"))
local women_lci = el(r(table), 5, colnumb(r(table), "sex_num"))
local women_uci = el(r(table), 6, colnumb(r(table), "sex_num"))
local women_p = el(r(table), 4, colnumb(r(table), "sex_num"))
local age60_or = el(r(table), 1, colnumb(r(table), "60.age_grp"))
local age60_lci = el(r(table), 5, colnumb(r(table), "60.age_grp"))
local age60_uci = el(r(table), 6, colnumb(r(table), "60.age_grp"))
local age60_p = el(r(table), 4, colnumb(r(table), "60.age_grp"))
local age70_or = el(r(table), 1, colnumb(r(table), "70.age_grp"))
local age70_lci = el(r(table), 5, colnumb(r(table), "70.age_grp"))
local age70_uci = el(r(table), 6, colnumb(r(table), "70.age_grp"))
local age70_p = el(r(table), 4, colnumb(r(table), "70.age_grp"))
local age80_or = el(r(table), 1, colnumb(r(table), "80.age_grp"))
local age80_lci = el(r(table), 5, colnumb(r(table), "80.age_grp"))
local age80_uci = el(r(table), 6, colnumb(r(table), "80.age_grp"))
local age80_p = el(r(table), 4, colnumb(r(table), "80.age_grp"))
local ch1_or = el(r(table), 1, colnumb(r(table), "1.charlson_grp"))
local ch1_lci = el(r(table), 5, colnumb(r(table), "1.charlson_grp"))
local ch1_uci = el(r(table), 6, colnumb(r(table), "1.charlson_grp"))
local ch1_p = el(r(table), 4, colnumb(r(table), "1.charlson_grp"))
local ch2_or = el(r(table), 1, colnumb(r(table), "2.charlson_grp"))
local ch2_lci = el(r(table), 5, colnumb(r(table), "2.charlson_grp"))
local ch2_uci = el(r(table), 6, colnumb(r(table), "2.charlson_grp"))
local ch2_p = el(r(table), 4, colnumb(r(table), "2.charlson_grp"))
local imd2_or = el(r(table), 1, colnumb(r(table), "2.imd"))
local imd2_lci = el(r(table), 5, colnumb(r(table), "2.imd"))
local imd2_uci = el(r(table), 6, colnumb(r(table), "2.imd"))
local imd2_p = el(r(table), 4, colnumb(r(table), "2.imd"))
local imd3_or = el(r(table), 1, colnumb(r(table), "3.imd"))
local imd3_lci = el(r(table), 5, colnumb(r(table), "3.imd"))
local imd3_uci = el(r(table), 6, colnumb(r(table), "3.imd"))
local imd3_p = el(r(table), 4, colnumb(r(table), "3.imd"))
local imd4_or = el(r(table), 1, colnumb(r(table), "4.imd"))
local imd4_lci = el(r(table), 5, colnumb(r(table), "4.imd"))
local imd4_uci = el(r(table), 6, colnumb(r(table), "4.imd"))
local imd4_p = el(r(table), 4, colnumb(r(table), "4.imd"))
local imd5_or = el(r(table), 1, colnumb(r(table), "5.imd"))
local imd5_lci = el(r(table), 5, colnumb(r(table), "5.imd"))
local imd5_uci = el(r(table), 6, colnumb(r(table), "5.imd"))
local imd5_p = el(r(table), 4, colnumb(r(table), "5.imd"))
local season1_or = el(r(table), 1, colnumb(r(table), "1.season"))
local season1_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local season1_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local season1_p = el(r(table), 4, colnumb(r(table), "1.season"))
local season2_or = el(r(table), 1, colnumb(r(table), "2.season"))
local season2_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local season2_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local season2_p = el(r(table), 4, colnumb(r(table), "2.season"))
local season3_or = el(r(table), 1, colnumb(r(table), "3.season"))
local season3_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local season3_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local season3_p = el(r(table), 4, colnumb(r(table), "3.season"))

poisson spell_los sex_num i.age_grp i.charlson_grp i.imd i.season if surgery_site_num == 1 & ~inlist(month_index, 24, 25), irr
local knee_women_or = el(r(table), 1, colnumb(r(table), "sex_num"))
local knee_women_lci = el(r(table), 5, colnumb(r(table), "sex_num"))
local knee_women_uci = el(r(table), 6, colnumb(r(table), "sex_num"))
local knee_women_p = el(r(table), 4, colnumb(r(table), "sex_num"))
local knee_age60_or = el(r(table), 1, colnumb(r(table), "60.age_grp"))
local knee_age60_lci = el(r(table), 5, colnumb(r(table), "60.age_grp"))
local knee_age60_uci = el(r(table), 6, colnumb(r(table), "60.age_grp"))
local knee_age60_p = el(r(table), 4, colnumb(r(table), "60.age_grp"))
local knee_age70_or = el(r(table), 1, colnumb(r(table), "70.age_grp"))
local knee_age70_lci = el(r(table), 5, colnumb(r(table), "70.age_grp"))
local knee_age70_uci = el(r(table), 6, colnumb(r(table), "70.age_grp"))
local knee_age70_p = el(r(table), 4, colnumb(r(table), "70.age_grp"))
local knee_age80_or = el(r(table), 1, colnumb(r(table), "80.age_grp"))
local knee_age80_lci = el(r(table), 5, colnumb(r(table), "80.age_grp"))
local knee_age80_uci = el(r(table), 6, colnumb(r(table), "80.age_grp"))
local knee_age80_p = el(r(table), 4, colnumb(r(table), "80.age_grp"))
local knee_ch1_or = el(r(table), 1, colnumb(r(table), "1.charlson_grp"))
local knee_ch1_lci = el(r(table), 5, colnumb(r(table), "1.charlson_grp"))
local knee_ch1_uci = el(r(table), 6, colnumb(r(table), "1.charlson_grp"))
local knee_ch1_p = el(r(table), 4, colnumb(r(table), "1.charlson_grp"))
local knee_ch2_or = el(r(table), 1, colnumb(r(table), "2.charlson_grp"))
local knee_ch2_lci = el(r(table), 5, colnumb(r(table), "2.charlson_grp"))
local knee_ch2_uci = el(r(table), 6, colnumb(r(table), "2.charlson_grp"))
local knee_ch2_p = el(r(table), 4, colnumb(r(table), "2.charlson_grp"))
local knee_imd2_or = el(r(table), 1, colnumb(r(table), "2.imd"))
local knee_imd2_lci = el(r(table), 5, colnumb(r(table), "2.imd"))
local knee_imd2_uci = el(r(table), 6, colnumb(r(table), "2.imd"))
local knee_imd2_p = el(r(table), 4, colnumb(r(table), "2.imd"))
local knee_imd3_or = el(r(table), 1, colnumb(r(table), "3.imd"))
local knee_imd3_lci = el(r(table), 5, colnumb(r(table), "3.imd"))
local knee_imd3_uci = el(r(table), 6, colnumb(r(table), "3.imd"))
local knee_imd3_p = el(r(table), 4, colnumb(r(table), "3.imd"))
local knee_imd4_or = el(r(table), 1, colnumb(r(table), "4.imd"))
local knee_imd4_lci = el(r(table), 5, colnumb(r(table), "4.imd"))
local knee_imd4_uci = el(r(table), 6, colnumb(r(table), "4.imd"))
local knee_imd4_p = el(r(table), 4, colnumb(r(table), "4.imd"))
local knee_imd5_or = el(r(table), 1, colnumb(r(table), "5.imd"))
local knee_imd5_lci = el(r(table), 5, colnumb(r(table), "5.imd"))
local knee_imd5_uci = el(r(table), 6, colnumb(r(table), "5.imd"))
local knee_imd5_p = el(r(table), 4, colnumb(r(table), "5.imd"))
local knee_season1_or = el(r(table), 1, colnumb(r(table), "1.season"))
local knee_season1_lci = el(r(table), 5, colnumb(r(table), "1.season"))
local knee_season1_uci = el(r(table), 6, colnumb(r(table), "1.season"))
local knee_season1_p = el(r(table), 4, colnumb(r(table), "1.season"))
local knee_season2_or = el(r(table), 1, colnumb(r(table), "2.season"))
local knee_season2_lci = el(r(table), 5, colnumb(r(table), "2.season"))
local knee_season2_uci = el(r(table), 6, colnumb(r(table), "2.season"))
local knee_season2_p = el(r(table), 4, colnumb(r(table), "2.season"))
local knee_season3_or = el(r(table), 1, colnumb(r(table), "3.season"))
local knee_season3_lci = el(r(table), 5, colnumb(r(table), "3.season"))
local knee_season3_uci = el(r(table), 6, colnumb(r(table), "3.season"))
local knee_season3_p = el(r(table), 4, colnumb(r(table), "3.season"))

post poisson_models ("Women") (`women_or') (`women_lci') (`women_uci') (`women_p') (`knee_women_or') (`knee_women_lci') (`knee_women_uci') (`knee_women_p')
post poisson_models ("Age 60-69") (`age60_or') (`age60_lci') (`age60_uci') (`age60_p') (`knee_age60_or') (`knee_age60_lci') (`knee_age60_uci') (`knee_age60_p')
post poisson_models ("Age 70-79") (`age70_or') (`age70_lci') (`age70_uci') (`age70_p') (`knee_age70_or') (`knee_age70_lci') (`knee_age70_uci') (`knee_age70_p')
post poisson_models ("Age 80+") (`age80_or') (`age80_lci') (`age80_uci') (`age80_p') (`knee_age80_or') (`knee_age80_lci') (`knee_age80_uci') (`knee_age80_p')
post poisson_models ("Charlson 1") (`ch1_or') (`ch1_lci') (`ch1_uci') (`ch1_p') (`knee_ch1_or') (`knee_ch1_lci') (`knee_ch1_uci') (`knee_ch1_p')
post poisson_models ("Charlson 2+") (`ch2_or') (`ch2_lci') (`ch2_uci') (`ch2_p') (`knee_ch2_or') (`knee_ch2_lci') (`knee_ch2_uci') (`knee_ch2_p')
post poisson_models ("IMD 2") (`imd2_or') (`imd2_lci') (`imd2_uci') (`imd2_p') (`knee_imd2_or') (`knee_imd2_lci') (`knee_imd2_uci') (`knee_imd2_p')
post poisson_models ("IMD 3") (`imd3_or') (`imd3_lci') (`imd3_uci') (`imd3_p') (`knee_imd3_or') (`knee_imd3_lci') (`knee_imd3_uci') (`knee_imd3_p')
post poisson_models ("IMD 4") (`imd4_or') (`imd4_lci') (`imd4_uci') (`imd4_p') (`knee_imd4_or') (`knee_imd4_lci') (`knee_imd4_uci') (`knee_imd4_p')
post poisson_models ("IMD 5") (`imd5_or') (`imd5_lci') (`imd5_uci') (`imd5_p') (`knee_imd5_or') (`knee_imd5_lci') (`knee_imd5_uci') (`knee_imd5_p')
post poisson_models ("spring") (`season1_or') (`season1_lci') (`season1_uci') (`season1_p') (`knee_season1_or') (`knee_season1_lci') (`knee_season1_uci') (`knee_season1_p')
post poisson_models ("summer") (`season2_or') (`season2_lci') (`season2_uci') (`season2_p') (`knee_season2_or') (`knee_season2_lci') (`knee_season2_uci') (`knee_season2_p')
post poisson_models ("autumn") (`season3_or') (`season3_lci') (`season3_uci') (`season3_p') (`knee_season3_or') (`knee_season3_lci') (`knee_season3_uci') (`knee_season3_p')
postclose poisson_models


* Work out the average LoS in different groups
postfile los_means str30 varname varlevel hip_mean hip_sd knee_mean knee_sd using "los_means", replace
local myvarnames sex_num age_grp charlson_grp imd season

foreach var of local myvarnames {
	levelsof `var', local(levels) 
	foreach level of local levels {
		summ spell_los if `var' == `level' & surgery_site_num == 0 & ~inlist(month_index, 24, 25)
		local hip_mean = `r(mean)'
		local hip_sd = `r(sd)'
		summ spell_los if `var' == `level' & surgery_site_num == 1 & ~inlist(month_index, 24, 25)
		local knee_mean = `r(mean)'
		local knee_sd = `r(sd)'		
		
		post los_means ("`var'") (`level') (`hip_mean') (`hip_sd') (`knee_mean') (`knee_sd')
	}
}

postclose los_means


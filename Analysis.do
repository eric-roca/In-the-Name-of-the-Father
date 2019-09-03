***************************************************
*
* Code to analyse the results
* Eric Roca Fernandez
* eric.roca-fernandez@univ-amu.fr
*
***************************************************

clear

cd "~/Documents/Research/3. Inheritance Rules and State Capacity/Data/"


import delimited "Cognatic.txt", delimiter(";")
foreach i in g_optimal b_optimal y capacity {
	capture replace `i' = subinstr(`i', "[", "", 1)
	capture replace `i' = subinstr(`i', "]", "", 1)
}


foreach i in g_optimal b_optimal y capacity {
	capture replace `i' = "" if `i'=="nan"
	}

destring, replace
compress
save Cognatic.dta, replace
clear
import delimited "external_data_male.txt", delimiter(";")
save Cognatic_external.dta, replace
clear
use male.dta
merge m:1 simulation period using "male_external.dta"
drop _merge
save, replace

clear
import delimited "Absolute.txt", delimiter(";")
foreach i in g_optimal b_optimal y capacity {
	capture replace `i' = subinstr(`i', "[", "", 1)
	capture replace `i' = subinstr(`i', "]", "", 1)
}

foreach i in g_optimal b_optimal y capacity {
	capture replace `i' = "" if `i'=="nan"
	}

destring, replace
compress
save Absolute.dta, replace
clear
import delimited "external_data_absolute.txt", delimiter(";")
save absolute_external.dta, replace
clear
use Absolute.dta
merge m:1 simulation period using "absolute_external.dta"
drop _merge
save, replace

append using "Cognatic.dta"

save Data.dta, replace


clear

use Data.dta
gen obs = _n
label variable simulation `"Simulation"'
label variable id `"County id"'
label variable period `"Period"'
label variable y `"Manor size"'
label variable capacity `"Manor state capacity"'
label variable counties `"Total manors"'
label variable g_optimal `"Investment in g"'
label variable b_optimal `"Investment in b"'
label variable obs `"Observation id"'
label variable absolute `"Absolute primogeniture (1 if yes)"'
label variable marriages `"Total number of marriages"'
* Generate additional variables not included in the data-set


by period absolute, sort: egen dev=sd(y)
label variable dev `"Std. Dev. in size"'

gen marriables = counties - total_removed
label variable marriables `"Number of inheritors"'


foreach string in capacity counties y marriages total_removed g_optimal{
	gen avg_`string' = 0
	label variable avg_`string' "Avg. `string'"
	gen lb_avg_`string' = 0
	gen ub_avg_`string' = 0
	foreach ab in 0 1 {
		forval i=1/25 {
			quietly ci means `string' if period == `i' & absolute == `ab'
			quietly replace avg_`string' =  r(mean) if period == `i' & absolute == `ab' 
			quietly	 replace lb_avg_`string' = r(lb)   if period == `i' & absolute == `ab'
			quietly replace ub_avg_`string' = r(ub)   if period == `i' & absolute == `ab'
		}
	}		
}


* Average investment for counties that invest
gen inv_if_inv = g_optimal if g_optimal > 0
gen invests = 1 if g_optimal > 0
replace invests = 0 if invests!=1

gen y_if_inv = y if g_optimal > 0

label variable inv_if_inv "Avg. investment for manors that invest"
label variable y_if_inv "Avg. size of manors that invest"


foreach string in inv_if_inv invests y_if_inv {
	gen avg_`string' = 0
	gen lb_avg_`string' = 0
	gen ub_avg_`string' = 0
	foreach ab in 0 1 {
		forval i=1/25 {
			quietly ci means `string' if period == `i' & absolute == `ab'
			quietly replace avg_`string' =  r(mean) if period == `i' & absolute == `ab'
			quietly	 replace lb_avg_`string' = r(lb)   if period == `i' & absolute == `ab'
			quietly replace ub_avg_`string' = r(ub)   if period == `i' & absolute == `ab'
		}
	}		
}	


**************************************
* MARRIAGES
**************************************

* A) Average number of marriages per marriageable under each regime

gen mm = marriages/marriables
* A.1) Large number of manors, law of large numbers apply

sum mm if absolute==1&id==1&period==1
sum mm if absolute==0&id==1&period==1

* A.2) The ratio decreases with the number of manors

tab period if id==1&absolute==1, sum(mm)
tab period if id==1&absolute==0, sum(mm)

**************************************
* FIGURES
**************************************

* A) Average state capacity per period and inheritance rule

by period absolute, sort:  gen to_graph =1 if _n==1

foreach string in capacity {
twoway (rarea lb_avg_`string' ub_avg_`string' period if absolute ==0&to_graph==1, sort fcolor(ltblue) lcolor(ltblue)) ///
(rarea lb_avg_`string' ub_avg_`string' period if absolute==1&to_graph==1, sort fcolor(eltgreen) lcolor(eltgreen)) ///
(line avg_`string' period if absolute==0&to_graph==1, sort lcolor(black) lpattern(solid)) ///
(line avg_`string' period if absolute==1&to_graph==1, sort lcolor(black) lpattern(dash)), ///
ytitle(Average state cap.) xtitle(Period) ///
legend(order(3 "Male-cognatic primogeniture" 4 "Absolute primogeniture"))
}

* B) Average investment

foreach string in g_optimal {
twoway (rarea lb_avg_`string' ub_avg_`string' period if absolute ==0&to_graph==1, sort fcolor(ltblue) lcolor(ltblue)) ///
(rarea lb_avg_`string' ub_avg_`string' period if absolute==1&to_graph==1, sort fcolor(eltgreen) lcolor(eltgreen)) ///
(line avg_`string' period if absolute==0&to_graph==1, sort lcolor(black) lpattern(solid)) ///
(line avg_`string' period if absolute==1&to_graph==1, sort lcolor(black) lpattern(dash)), ///
ytitle(Average investment in state cap.) xtitle(Period) ///
legend(order(3 "Male-cognatic primogeniture" 4 "Absolute primogeniture"))
}


foreach string in inv_if_inv {
twoway (rarea lb_avg_`string' ub_avg_`string' period if absolute ==0&to_graph==1, sort fcolor(ltblue) lcolor(ltblue)) ///
(rarea lb_avg_`string' ub_avg_`string' period if absolute==1&to_graph==1, sort fcolor(eltgreen) lcolor(eltgreen)) ///
(line avg_`string' period if absolute==0&to_graph==1, sort lcolor(blacl) lpattern(solid)) ///
(line avg_`string' period if absolute==1&to_graph==1, sort lcolor(black) lpattern(dash)), ///
ytitle(Average investment of manors that invest) xtitle(Period) ///
legend(order(3 "Male-cognatic primogeniture" 4 "Absolute primogeniture"))
}

foreach string in invests {
twoway (rarea lb_avg_`string' ub_avg_`string' period if absolute ==0&to_graph==1, sort fcolor(ltblue) lcolor(ltblue)) ///
(rarea lb_avg_`string' ub_avg_`string' period if absolute==1&to_graph==1, sort fcolor(eltgreen) lcolor(eltgreen)) ///
(line avg_`string' period if absolute==0&to_graph==1, sort lcolor(black) lpattern(solid)) ///
(line avg_`string' period if absolute==1&to_graph==1, sort lcolor(black) lpattern(dash)), ///
ytitle(Share of manors that invest) xtitle(Period) ///
legend(order(3 "Male cognatic primogeniture" 4 "Absolute primogeniture"))
}

* C) Manor size

foreach string in y_if_inv {
twoway (rarea lb_avg_`string' ub_avg_`string' period if absolute ==0&to_graph==1, sort fcolor(ltblue) lcolor(ltblue)) ///
(rarea lb_avg_`string' ub_avg_`string' period if absolute==1&to_graph==1, sort fcolor(eltgreen) lcolor(eltgreen)) ///
(line avg_`string' period if absolute==0&to_graph==1, sort lcolor(black) lpattern(solid)) ///
(line avg_`string' period if absolute==1&to_graph==1, sort lcolor(black) lpattern(dash)), ///
ytitle(Average manor size) xtitle(Period) ///
legend(order(3 "Male-cognatic primogeniture" 4 "Absolute primogeniture"))
}

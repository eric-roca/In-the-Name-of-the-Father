***************************************************
*
* Code to analyse the results
* Turning point
* Eric Roca Fernandez
* eric.roca-fernandez@univ-amu.fr
*
***************************************************

set more off

cd "~/Documents/Research/3. Inheritance Rules and State Capacity/Data/"

import delimited Absolute.txt, delimiter(";")
save turning_absolute.dta, replace

clear
import delimited Cognatic.txt, delimiter(";")
save turning_cognatic.dta, replace

append using turning_absolute.dta

clear
use turning_cognatic
append using turning_absolute.dta

sort  phi psi pb pg children period simulation absolute
duplicates drop simulation period absolute phi psi pb pg children, force
gen dif = capacity-capacity[_n+1] if absolute==1&period==period[_n+1]
gen surpass = 1 if dif < 0 & !missing(dif)
replace surpass = 0 if dif >=0 & !missing(dif)
gen period_surpass = period*surpass if surpass > 0 & !missing(surpass)
sort  phi psi pb pg children period simulation absolute
egen id = group(simulation phi psi pb pg children)

gen final_surpass = 99
qui distinct id
local nn = r(ndistinct)
forval i=1/`=`nn'' {
	noisily di "`i' of `nn'"
	forval period = 25(-1)1 {
		noisily di "      Period: `period'"
		sum dif if period==`period'&id==`i'
		local avg = r(mean)
	  	
		if `avg'<0 {
			replace final_surpass = `period' if id==`i'
		}
		if `avg'>=0 {
			continue, break
		}
	}
}


save Turning.dta, replace

clear
use Turning.dta
replace final_surpass = . if final_surpass==99			
drop id
egen id = group(phi psi pb pg children)

* Compute the average time of surpass
by id, sort: egen avg_surpass = mean(final_surpass)
by id, sort: egen var_surpass = sd(final_surpass)
by id, sort: gen n_surpass = _N

* Generate the percentage of times that MALE does not surpass ABSOLUTE
gen has_data = (!missing(final_surpass))
by id, sort: egen pct_surpass = mean(has_data)
by id, sort: egen var_pct_surpass = var(has_data)

gen avg_surpass_ub = avg_surpass + 1.645*var_surpass^0.5/n_surpass
gen avg_surpass_lb = avg_surpass - 1.645*var_surpass^0.5/n_surpass

gen pct_surpass_ub = pct_surpass + 1.645*var_pct_surpass^0.5/n_surpass
gen pct_surpass_lb = pct_surpass - 1.645*var_pct_surpass^0.5/n_surpass


by id, sort: gen first_id = 1 if _n==1
keep if first_id == 1

label variable avg_surpass "Male-cognatic prim. take-over time"
label variable pct_surpass "% cases male-cognatic prim. takes over"
label variable phi "{&phi}"
label variable psi "{&psi}"
label variable pg "p{sub:g}"
label variable pb "p{sub:b}"
label variable children "{&Phi}"

#delimit ;
twoway 	(rarea avg_surpass_lb avg_surpass_ub phi if psi==float(5/12)&pb==float(1.2)&pg==float(1.375)&children==3, sort lcolor(gs4) color(gs4))
	(line avg_surpass phi if psi==float(5/12)&pb==float(1.2)&pg==float(1.375)&children==3, sort lcolor(black)),
	legend(order(2) rows(2)) ytitle("Male-cognatic prim. take-over time", axis(1));
graph export "/home/eric/Documents/Research/3. Inheritance Rules and State Capacity/Graphs/Comparator/phi.eps", as(eps) preview(off) replace;

twoway 	(rarea avg_surpass_lb avg_surpass_ub psi if phi==float(1)&pb==float(1.2)&pg==float(1.375)&children==3, sort lcolor(gs4) color(gs4))
	(line avg_surpass psi if phi==float(1)&pb==float(1.2)&pg==float(1.375)&children==3, sort lcolor(black)),
	legend(order(2) rows(2)) ytitle("Male-cognatic prim. take-over time", axis(1));
graph export "/home/eric/Documents/Research/3. Inheritance Rules and State Capacity/Graphs/Comparator/psi.eps", as(eps) preview(off) replace;

	
twoway 	(rarea avg_surpass_lb avg_surpass_ub pb if phi==float(1)&psi==float(5/12)&pg==float(1.375)&children==3, sort lcolor(gs4) color(gs4))
	(line avg_surpass pb if phi==float(1)&psi==float(5/12)&pg==float(1.375)&children==3, sort lcolor(black)),
	legend(order(2) rows(2)) ytitle("Male-cognatic prim. take-over time", axis(1));
graph export "/home/eric/Documents/Research/3. Inheritance Rules and State Capacity/Graphs/Comparator/pb.eps", as(eps) preview(off) replace;

	
twoway 	(rarea avg_surpass_lb avg_surpass_ub pg if phi==float(1)&pb==float(1.2)&psi==float(5/12)&children==3, sort lcolor(gs4) color(gs4))
	(line avg_surpass pg if phi==float(1)&pb==float(1.2)&psi==float(5/12)&children==3, sort lcolor(black)),
	legend(order(2) rows(2)) ytitle("Male-cognatic prim. take-over time", axis(1));
	graph export "/home/eric/Documents/Research/3. Inheritance Rules and State Capacity/Graphs/Comparator/pg.eps", as(eps) preview(off) replace;

	
twoway 	(rarea avg_surpass_lb avg_surpass_ub children if phi==float(1)&pb==float(1.2)&pg==float(1.375)&psi==float(5/12), sort lcolor(gs4) color(gs4))
	(line avg_surpass children if phi==float(1)&pb==float(1.2)&pg==float(1.375)&psi==float(5/12), sort lcolor(black)),
	legend(order(2) rows(2)) ytitle("Male-cognatic prim. take-over time", axis(1));
graph export "/home/eric/Documents/Research/3. Inheritance Rules and State Capacity/Graphs/Comparator/children.eps", as(eps) preview(off) replace;
#delimit cr

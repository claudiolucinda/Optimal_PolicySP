* Codigo Logsum_mix

qui drop if id==.
sort id
*merge m:1 id using branch04\trunk\Output\hdraws.dta, keep(match) nogen
merge m:1 id using Data/hdraws.dta, keep(match) nogen

estimates use "Data/modelo.ster"
matrix B=e(b)
matrix list B
drop if incinc==.

predict prob_choice
	
cap drop delta_ij_*
cap drop sum_i_*

forvalues i=1/50 {
replace m1_`i'=invnorm(m1_`i')
replace m2_`i'=invnorm(m2_`i')
gen voti_`i'=(_b[timetime]+_b[SD: timetime]*m2_`i'+_b[timexrenda]/incinc)/(_b[costcost]+_b[SD: costcost]*m1_`i'+_b[costxrenda]/incinc)
}

egen m1=rowmean(m1_*)
gen denom=-1/(_b[costcost]+_b[SD: costcost]*m1+_b[costxrenda]/incinc)
egen vot=rowmean(voti_*) 
sum vot, detail

local lo=r(p1)
local up=r(p99)
replace vot=0  if vot < 0 
replace vot=`up' if vot > `up'


gen xi=-(_b[dummy_ce_1]*dummy_ce_1+_b[dummy_ce_2]*dummy_ce_2 +_b[dummy_ce_3]*dummy_ce_3 +_b[dummy_ce_4]*dummy_ce_4+_b[dummy_ce_5]*dummy_ce_5+ /// 
_b[fem_1]*fem_1+_b[fem_2]*fem_2+_b[fem_3]*fem_3+_b[fem_4]*fem_4+_b[fem_5]*fem_5+ ///
_b[corredor10_1]*corredor10_1+_b[corredor10_2]*corredor10_2+_b[corredor10_3]*corredor10_3 +_b[corredor10_4]*corredor10_4+_b[corredor10_5]*corredor10_5+ ///
_b[estacao10_1]*estacao10_1+_b[estacao10_2]*estacao10_2+_b[estacao10_3]*estacao10_3+_b[estacao10_4]*estacao10_4+_b[estacao10_5]*estacao10_5+ ///
_b[incinc_1]*incinc_1 +_b[incinc_2]*incinc_2+_b[incinc_3]*incinc_3+_b[incinc_4]*incinc_4+_b[incinc_5]*incinc_5)

* custo individual
gen ci=xi/denom + 1*costcost_0+vot*timetime
gen votdt=vot*$dtdtraff


* computing logsum per trip
predict linear_choice, xb
/*
if $permits_system==1 {
	if $trade==0 {
		replace linear_choice=-100000 if permit==0 & dup==3 & dummy_auto==1
		}
	if $trade==1 {
		replace linear_choice=-100000 if permit==1
		}
	}
*/	
gen exp_choice=exp(linear_choice)

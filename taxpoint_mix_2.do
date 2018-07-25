* CÛdigo -- Efeitos Pedagio em um ponto
* Nome codigo TAXPOINT.DO
* Retorna uma global que È a soma do logsum em um ponto.
* Claudio R. Lucinda
* FEA-RP/USP
* 2015


use "Data/dados_start.dta", clear
destring id_pess, replace
**** 1 - valor inicial do imposto I0=5 *
qui gen costcost_0=costcost
qui gen costxrenda_0=costxrenda
qui generate timetime_1=timetime

gen dumSD_old=dumSD

global etq=0
qui replace costcost=costcost_0+$tax if dup==3 & dummy_ce==1
if $grp_rebate == 0 {
	qui replace costcost=costcost-$rebate 
}
else if $grp_rebate == 1 {
	qui replace costcost=costcost-$rebate if dup==$grp_rebate
}

qui replace costxrenda=(costcost)/incinc 
estimates use "Data/modelo.ster"
*estimates restore mod01
* prevendo as probabilidades
cap drop problogit_old
qui mixlpred problogit_old, nrep(50)
*qui predict problogit_old, pr
qui drop if incinc==.
qui drop if id==.
replace fe_via=round(fe_via)
/*
if $permits_system==1 {
	if $trade==0 {
		replace problogit_old=0 if permit==0 & dup==3 & dummy_auto==1
		}
	if $trade==1 {
		replace problogit_old=0 if permit==1
		}
	}
		
*/
save "Data/dados_demanda.dta", replace

do "$track2/miolo_mix_2.do"


cap drop pasclogit_0

run "$track2/logsum_mix_4.do"

do "$track2/miolo_SD.do"

qui gen esc_pred=m_choice*dup

* merge as regioes que o individuo cruza
qui merge m:1 origem destino peak using "Data/traf_rotas_manha.dta", nogen 
*keep(match)

gen ci_car= ci if esc_pred==3
sum ci_car [fw=fe_via], detail
global max_ci=r(max)
global ave_ci=r(p50)


			
sum votdt [fw=fe_via] if pico_manha==1 & esc_pred==3 & dummy_ce==1
global ext=r(sum)
*gen ext=votdt_car * traf_tot_car
*sum ext [fw=fe_via] if pico_manha==1 
*global extm=r(mean)
global mc=$ave_ci+$ext
display $max_ci       
display $mc
display $ave_ci


gen tottrips=0
replace tottrips=1 if esc_pred==3
*qui total tottrips if nro==1 & esc_pred==3
sum tottrips [fw=fe_via] if pico_manha==1
global tottrips_point=r(sum)
display $tottrips_point

* salvando os resultados 
* salva a escolha por viagem
rename problogit_old problogit_$etq
rename esc_pred choice_$etq
rename timetime time_$etq
gen inv_inc=1/incinc
mixlogsum lsum_$etq, intvar(inv_inc) intcoeff(costxrenda)
keep choice_$etq  fe_pess fe_via id_pess id dup dummy_ce problogit_$etq lsum_$etq  time_$etq timetime_1 incinc dist modo_dummy
*keep if choice_0~=0
drop if id==.
save "Data/choice_$etq.dta", replace



* calcula o logsum por pessoa: 
* eh a media das viagens da pessoa
replace time_$etq=0 if choice_$etq==0

gen car_user=0
replace car_user=1 if modo_dummy==1 & dup==3

qui collapse  (mean) lsum_$etq  fe_pess id_pess dummy_ce incinc dist (sum) time_$etq (max) car_user , by(id)
qui collapse  (mean)   fe_pess dummy_ce incinc dist (sum) lsum_$etq time_$etq (max) car_user, by(id_pess)
replace lsum_$etq = lsum_$etq + $lsum_rebate
rename time_$etq timesum_$etq
sort id_pess id
save "Data/lsum_$etq.dta", replace


clear

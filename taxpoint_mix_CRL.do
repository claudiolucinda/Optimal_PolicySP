* Código -- Efeitos Pedagio em um ponto
* Nome codigo TAXPOINT.DO
* Retorna uma global que é a soma do logsum em um ponto.
* Claudio R. Lucinda
* FEA-RP/USP
* 2015


use "Data/dados_start.dta", clear
**** 1 - valor inicial do imposto I0=5 *
qui gen costcost_0=costcost
qui gen costxrenda_0=costxrenda
qui generate timetime_1=timetime


qui replace costcost=costcost_0+$tax if dup==3 & dummy_ce==1
if $grp_rebate ==0 {
	qui replace costcost=costcost-$rebate 
}
else if $grp_rebate==1 {
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
save "Data/dados_demanda.dta", replace

run ".\Code_Analysis\Optimal_PolicySP\miolo_mix_2.do"

cap drop pasclogit_0

run ".\Code_Analysis\Optimal_PolicySP\logsum_mix_4.do"

bysort id: egen double probmax=max(problogit_old)


qui gen m_choice=0
qui replace m_choice=1 if probmax==problogit_old
qui gen esc_pred=m_choice*dup

qui merge m:1 origem destino peak using "Data/traf_rotas_manha.dta", nogen 

gen ci_car= ci if esc_pred==3
sum ci_car [fw=fe_via], detail
global max_ci=r(max)
global ave_ci=r(p50)

			
sum votdt [fw=fe_via] if pico_manha==1 & esc_pred==3 & dummy_ce==1
global ext=r(sum)

clear

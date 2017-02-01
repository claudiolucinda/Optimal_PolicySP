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
* CRL: Checar a forma aqui
qui replace costxrenda=(costcost_0+$tax)/incinc if dup==3 & dummy_ce==1

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

run "miolo_mix_2.do"


* para restaurar os dados_demanda.dta
*qui gen time`k'=timetime
*qui replace timetime=timetime_1
*drop time_renda 
*cap drop costcost cost_renda timetime_1
cap drop pasclogit_0
*qui gen time_renda=timetime/incinc
*qui gen timexrenda=timetime*incinc
*qui gen costcost=costcost_0
*qui gen cost_renda=cost_renda_0
*cap drop costcost_0 costxrenda_0
*save ".\Data\dados_demanda.dta", replace

run "logsum_mix_4.do"


/*qui predict xb0 if e(sample), xb
replace xb0=exp(xb0) if e(sample)
bysort id: egen soma=sum(xb0) if e(sample)

qui gen logsum=log(soma)/(_b[costcost]+_b[cost_renda]/incinc) if e(sample)
*/
merge m:1 origem destino peak using traf_rotas_noite.dta
drop if _merge==2
drop _merge
merge m:1 origem destino peak using traf_rotas_off.dta, update
drop if _merge==2
drop _merge
merge m:1 origem destino peak using traf_rotas_manha.dta, update 
drop if _merge==2
drop _merge

bysort id: egen double probmax=max(problogit_old)


* 1 para o modo escolhido, 0 nos demais
qui gen m_choice=0
qui replace m_choice=1 if probmax==problogit_old
qui gen esc_pred=m_choice*dup

* merge as regioes que o individuo cruza
qui merge m:1 origem destino peak using "Data/traf_rotas_manha.dta", nogen 
*keep(match)

gen ci_car= ci if esc_pred==3
sum ci_car [fw=fe_via], detail
global max_ci=r(max)
global ave_ci=r(p50)

*gen votdt_car=votdt if esc_pred==3
* COMO SOMAR TODOS OS MOTORISTAS QUE CRUZAM A ROTA DE i???????
*bysort origem destino: egen votdt_car=mean(votdt) if esc_pred==3

			*preserve
			*qui collapse (mean) votdt_car [fw=fe_via], by(origem destino)
			*qui save "Data/vot_car.dta", replace
			*restore
			*merge m:1 origem destino using "Data/vot_car.dta"
			
sum votdt [fw=fe_via] if pico_manha==1 & esc_pred==3 & dummy_ce==1
global ext=r(sum)
*gen ext=votdt_car * traf_tot_car
*sum ext [fw=fe_via] if pico_manha==1 
*global extm=r(mean)
global mc=$ave_ci+$ext
display $max_ci       
display $mc
display $ave_ci
/*
*qui total totcost if nro==1 & esc_pred==3
qui total totcost if esc_pred==3
mat temp=r(table)
global totcost_point=temp[1,1]
mat drop temp

qui total mcost if esc_pred==3
mat temp=r(table)
global mcost_point=temp[1,1]
mat drop temp
*/

gen tottrips=0
replace tottrips=1 if esc_pred==3
*qui total tottrips if nro==1 & esc_pred==3
sum tottrips [fw=fe_via] if pico_manha==1
global tottrips_point=r(sum)
display $tottrips_point

*qui total tottrips [fw=fe_via] if esc_pred==3
*mat temp=r(table)
*global tottrips_point=temp[1,1]
*mat drop temp


clear

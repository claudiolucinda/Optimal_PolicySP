 * Analise politica - majority voting - da aceitacao do pedigio urbano



clear all
set more off
macro drop _all

* QUEM E VOCE???
* lucinda declara lucinda=1 e moita declara lucinda=0
* todos os demais enderecos se ajustam automaticamente (I wish...)
local lucinda=1

if `lucinda'==1 {
   cd "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"
   global track1 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta"
   global track "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data\"
   global track2 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Code_Analysis\Optimal_PolicySP\"
   global track3 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\paper_apresentacoes\output\"
	*global track3 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\paper_apresentacoes\output"

   
}
else {
	*cd "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/"
	cd "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"
	*global track "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/Data/"
	global track "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data\"
	*global track1 "/Users/Rodrigo/Dropbox/Lucinda-Moita/Pesquisa OD/Bases dta/"
	global track1 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta"
	global track2 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Code_Analysis\Optimal_PolicySP\"
	*global track2 "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/Code_Analysis/Optimal_PolicySP"
	*global track3 "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/paper_apresentacoes/output"
	global track3 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\paper_apresentacoes\output"
	}

capture confirm file "Data/dados_start00.dta" 

if _rc~=0 {
	do "Demanda_v04.do"    
}
else {
	use "Data/dados_start00.dta", clear
}

drop if id==.

* dummy que identifica que usou o carro ao menos uma vez
gen carro_id=0
replace carro_id=1 if modo_dummy==1 & dup==3
bysort id_pess: egen car_user=max(carro_id)
drop carro_id

save "Data/dados_start.dta", replace

*tempname p
*postfile `p' tax logsum totcost tottrips average_cost mcost using "$track2/Dados_tabela.dta", replace
*postfile `p' tax tottrips average_cost mcost using "$track2/Dados_tabela3.dta", replace

*modos de transporte: 1"Bus" 2"Rail" 3"Driving" 4"Motorcycle" 5"Taxi" 6"Other"


***** (i)  SEM REDISTRIBUIR A RECEITA DO IMPOSTO  *****

***** 0 -  Calculando o logsum e escolhas sem imposto (benchmark)

global tax=0
global rebate=0
global etq=0
global grp_rebate=0
global revenue=0
global lsum_rebate=0
run "$track2/taxpoint_mix_2.do"
	
	
***** 1 - Define o imposto que se quer analisar, em geral o otimo, e calcula logsum e otimo
global tax=7.64
global etq tax
run "$track2/taxpoint_mix_2.do"




***** (ii)  REDISTRIBUINDO A RECEITA DO IMPOSTO  *****


***** (a) Redistribui Para Toda a Populacao

** 1 - Calculando o numero de viagens total na cidade
use "Data/choice_tax.dta", clear
estpost tab  choice_tax [fweight=round(fe_via)] if  choice_tax~=0  & dummy_ce==1
matrix chc=e(b)
global ncar=chc[1,3]

** 2 - Calculando a receita
* a unidade aqui e a viagem
global rebate=0
global etq=0
global grp_rebate=0
global tax=7
global revenue=$ncar*$tax

bysort id_pess: gen idn=_n
replace idn=. if idn~=1
replace fe_pess=round(fe_pess)
sum idn [fweight=fe_pess]
display r(sum)
global npess=r(sum)

** 3 - Define renda que retorna para cada pessoa - toda a populacao, com ou sem carro
global lsum_rebate=$revenue / $npess
display $lsum_rebate
** 4 - Preciso que, dado um imposto, as probabilidades convirjam
global tax=7
global etq rev
run "$track2/taxpoint_mix_2.do"



***** (b) Subsidiando o Onibus - dar um desconto na tarifa de onibus
* paper do Basso & Jara-Dias, mas
* nao conheco o custo do onibus, 
* nem como a frequencia varia com o fluxo de passageiros

global grp_rebate=1
global lsum_rebate=0
** 1 - calculo o numero de viagens inicial de onibus, antes do subsidio 
use "Data/choice_0.dta", clear
estpost tab  choice_0 [fweight=round(fe_via)] if  choice_0~=0 
matrix chc=e(b)
global nvia_bus=chc[1,1]

** 2 - Loop para achar o subisidio de equilibrio para o onibus, dado
* o imposto sobre o carro
scalar diff=1
scalar inner_tol=0.05
global tax=7
local flagrev=1
global etq rev_bus


while diff>inner_tol {
	if `flagrev'==1 {
		global rebate=2
		}
	local flagrev=`flagrev'+1
	display `flagrev'
	run "$track2/taxpoint_mix_2.do"
	* (3) - dadas as novas escolhas, acha o novo numero de viagens de onibus
	use "Data/choice_$etq.dta", clear
	estpost tab  choice_$etq [fweight=round(fe_via)] if  choice_$etq~=0 
	matrix chc=e(b)
	global rebate_2=$rebate
	global nvia_bus=chc[1,1]
	estpost tab  choice_$etq [fweight=round(fe_via)] if  choice_$etq~=0 & dummy_ce==1
	global revenue=chc[1,3]*$tax
	global rebate=$revenue / $nvia_bus
	display $rebate
	scalar diff=abs($rebate_2 - $rebate)
	display diff
	}







***************  TABELAS - LATEX  **********************************
*************************************************************

********  A - pros e contras, com imposto, sem transferencia *********

* geral
use "Data/lsum_0.dta", clear
merge 1:1 id_pess using "Data/lsum_tax.dta"
gen dif_logsum= lsum_0- lsum_tax
sum dif_logsum lsum_tax lsum_0
gen pro_tax=0
replace pro_tax=1 if dif_logsum<0
replace pro_tax=-1 if dif_logsum>0
tab pro_tax if pro_tax~=0
tab1 pro_tax [fweight=round(fe_pess)]
estpost tabulate pro_tax [fweight=round(fe_pess)], nototal
matrix freq_per= e(b)\e(pct)
matrix rownames freq_per= N "\%"
matrix colnames freq_per= Against Neutral Pro
outtable using "$track3/protax_table", mat(freq_per) replace ///
nobox center asis caption("Pro and Against the Tax") format(%6.0f) clabel(freq_per)


* car user vs non users
* dummy que identifica que usou o carro ao menos uma vez

sum dif_logsum [fweight=round(fe_pess)] if car_user==1, detail
tab pro_tax if pro_tax~=0 & car_user==1
tabulate pro_tax car_user [fweight=round(fe_pess)] if pro_tax~=0,  nofreq column
estpost tabulate pro_tax [fweight=round(fe_pess)] if pro_tax~=0 & car_user==1
est store protax2
matrix  pct_users=e(pct)
estpost tabulate pro_tax [fweight=round(fe_pess)] if pro_tax~=0 & car_user==0
est store protax3
matrix  pct_nonusers=e(pct)
matrix pct_all=(pct_users', pct_nonusers')
matrix rownames pct_all= Con Pro Total
matrix colnames pct_all= "User" "Non User"
outtable using "$track3/pct_all", mat(pct_all) replace ///
nobox center asis caption("Car Users vs Non Users: Pro and Against the Tax") ///
 format(%6.0f) clabel(pct_all)

* travel time change - por pessoa
gen diff_time= (timesum_tax-timesum_0)
histogram diff_time if diff_time~=0
sum diff_time [fweight=round(fe_pess)] if diff_time~=0 & dummy_ce==1, detail 
matrix timediff = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list timediff
mat colnames timediff="p99" "p95" "p90" "p75" "p50" "p25" "p10" "p5" "p1"
outtable using "$track3/time_change_tax", mat(pct_all) replace nobox center ///
 asis caption("Travel Time Change (minutes)  - congestoin tax versus no tax") format(%6.3f) clabel(time_chg_tax)
matrix drop  timediff
 
******* Welfare Change 

* dummy que identifica que usou o carro ao menos uma vez
use "Data/choice_0.dta", clear 
gen carro_id=0
replace carro_id=1 if choice_0==3
bysort id_pess: egen car_user_0=max(carro_id)
drop carro_id

* dummy que identifica que usou o carro ao menos uma vez com o imposto
merge 1:1 id dup using "Data/choice_tax.dta"
gen carro_id=0
replace carro_id=1 if choice_tax==3
bysort id_pess: egen car_user_tax=max(carro_id)
drop carro_id

*** switchers: car to other (bus+rail+other) 
gen switcher_tax=0
replace switcher_tax=1 if car_user_0==1 & car_user_tax==0
*qui collapse  (mean) lsum_tax car_user_tax fe_pess switcher_tax (sum) time_tax, by(id_pess)
qui collapse  (mean) car_user_0 car_user_tax fe_pess switcher_tax, by(id_pess)
merge 1:1 id_pess using "Data/lsum_0.dta", nogenerate
merge 1:1 id_pess using "Data/lsum_tax.dta", nogenerate
gen dif_logsum=(lsum_tax-lsum_0)/lsum_0 
sum dif_logsum [fweight=round(fe_pess)]  if switcher_tax~=0 , detail         
matrix pct_switch_tax = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_switch_tax

*** remaining drivers
gen remaining_tax=0
replace remaining_tax=1 if car_user_0==1 & car_user_tax==1
sum dif_logsum [fweight=round(fe_pess)] if remaining_tax==1, detail         
matrix pct_remain_tax = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_remain_tax
 
*** no drivers
gen nodrivers_tax=0
replace nodrivers_tax=1 if car_user_0==0 & car_user_tax==0
sum dif_logsum [fweight=round(fe_pess)] if nodrivers_tax==1, detail         
matrix pct_nodriver_tax = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_nodriver_tax

**tabela output
mat pct_all=(pct_remain_tax \ pct_switch_tax \ pct_nodriver_tax)
mat rownames pct_all="remaining-drivers" "switch-car-to-public" "non-drivers" 
mat colnames pct_all="p99" "p95" "p90" "p75" "p50" "p25" "p10" "p5" "p1"
mat list pct_all
outtable using "$track3/welfare_change_tax", mat(pct_all) replace nobox center ///
 asis caption("Welfare Change for Different Groups") format(%6.3f) clabel(welfare_chg_tax)
matrix drop  pct_all  


**** table of variables that explain the decision to switch
gen distinc=dist*incinc
reg switcher_tax dist incinc  distinc dummy_ce [fweight=round(fe_pess)] if car_user_0==1
estimate store reg1
esttab using "$track3/reg_switch.tex", label ///
 title(who stops driving? table\label{tab_switch}) replace
 
 
 
******** table of mode choice joint distribution, pre and post policy
use "Data/choice_0.dta", clear
* preparar a variavel timetime para o collapse - tempo por pessoa
gen dumi=0 
replace dumi=1 if choice_0~=0
gen time_00=timetime_1*dumi
collapse (max) choice_0 time_00, by(id) 
save "Data/choice_0_via.dta", replace
use "Data/choice_tax.dta", clear
gen dumi=0 
replace dumi=1 if choice_tax~=0
gen time_tax0=timetime*dumi
collapse (max) choice_tax fe_via time_tax0, by(id) 
merge 1:1 id using "Data/choice_0_via.dta"
tabulate choice_0 choice_tax [fweight=round(fe_via)], matcell(temp1)
mat list temp1
scalar row=rowsof(temp1)
mat ones=J(1,row,1)
mat tot_row=ones*temp1
mat temp11=temp1\tot_row
scalar col=colsof(temp1)
mat ones=J(1,col,1)
mat tot_col=temp11*ones'
mat ch0_pu=temp11,tot_col
mat rownames ch0_pu="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other" "Total"
mat colnames ch0_pu="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other" "Total"
outtable using "$track3/choice_0_tax", mat(ch0_pu) replace nobox ///
 asis caption("Transition matrix - with a congestion tax") format(%12.0fc) clabel(transition_0)
matrix drop  ch0_pu temp1 tot_row ones temp11  tot_col 


******** table of time change for drivers
use "Data/choice_0.dta", clear
merge 1:1 id dup using "Data/choice_tax.dta"
gen diff= time_tax-time_0
sum diff if  diff<0 & choice_tax==3 & choice_0==3, detail
histogram diff [fweight=round(fe_via)] if  diff<0 & diff>-1.5 & choice_tax==3 & choice_0==3, kdensity frequency ytitle("Frequency") xtitle("Time Difference - Minutes") scheme(sj)
graph export "Figs01.pdf", replace






********  B - Pros e Contras, com imposto, com Transferencia Lump Sum

**  pros e contras com revenue recycling
use "Data/lsum_0.dta", clear
merge 1:1 id_pess using "Data/lsum_rev.dta"
gen dif_logsum= lsum_0- lsum_rev
sum dif_logsum lsum_rev lsum_0
gen pro_tax=0
replace pro_tax=1 if dif_logsum<0
replace pro_tax=-1 if dif_logsum>0
tab pro_tax if pro_tax~=0
tab1 pro_tax [fweight=round(fe_pess)]
estpost tabulate pro_tax [fweight=round(fe_pess)], nototal
matrix freq_per_rev= e(b)\e(pct)
matrix rownames freq_per_rev= N "\%"
matrix colnames freq_per_rev= Against  Pro
outtable using "$track3/protax_rev_table", mat(freq_per_rev) replace ///
nobox center asis caption("Pro and Against with Revenue Redistribution") ///
format(%6.0f) clabel(freq_per_rev)


** table of mode choice joint distribution, pre and post policy
use "Data/choice_0.dta", clear
collapse (max) choice_0 fe_via, by(id) 
save "Data/choice_0_via.dta", replace
use "Data/choice_rev.dta", clear
collapse (max) choice_rev, by(id) 
merge 1:1 id using "Data/choice_0_via.dta"
tabulate choice_0 choice_rev [fweight=round(fe_via)], matcell(temp1)
mat list temp1
scalar row=rowsof(temp1)
mat ones=J(1,row,1)
mat tot_row=ones*temp1
mat temp11=temp1\tot_row
scalar col=colsof(temp1)
mat ones=J(1,col,1)
mat tot_col=temp11*ones'
mat ch0_pu=temp11,tot_col
mat rownames ch0_pu="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other" "Total"
mat colnames ch0_pu="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other" "Total"
outtable using "$track3/choice_0_rev", mat(ch0_pu) replace nobox ///
asis caption("Choices - tax and rebate for everyone") format(%6.0f) clabel(transition_0_tax)
matrix drop  ch0_pu temp1 tot_row ones temp11  tot_col 

******* Welfare Change ****

* dummy que identifica que usou o carro ao menos uma vez
use "Data/choice_0.dta", clear 
gen carro_id=0
replace carro_id=1 if choice_0==3
bysort id_pess: egen car_user_0=max(carro_id)
drop carro_id

* dummy que identifica que usou o carro ao menos uma vez com o imposto
merge 1:1 id dup using "Data/choice_rev.dta"
gen carro_id=0
replace carro_id=1 if choice_rev==3
bysort id_pess: egen car_user_rev=max(carro_id)
drop carro_id

*** switchers: car to other (bus+rail) 
gen switcher_rev=0
replace switcher_rev=1 if car_user_0==1 & car_user_rev==0
qui collapse  (mean) car_user_0 car_user_rev fe_pess switcher_rev, by(id_pess)
merge 1:1 id_pess using "Data/lsum_0.dta", nogenerate
merge 1:1 id_pess using "Data/lsum_rev.dta", nogenerate
gen dif_logsum=(lsum_rev-lsum_0)/lsum_0 
sum dif_logsum [fweight=round(fe_pess)]  if switcher_rev~=0 , detail         
matrix pct_switch_rev = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_switch_rev

*** remaining drivers
gen remaining_rev=0
replace remaining_rev=1 if car_user==1 & car_user_rev==1
sum dif_logsum [fweight=round(fe_pess)] if remaining_rev==1, detail         
matrix pct_remain_rev = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_remain_rev
 
*** no drivers
gen nodrivers_rev=0
replace nodrivers_rev=1 if car_user==0 & car_user_rev==0
sum dif_logsum [fweight=round(fe_pess)] if nodrivers_rev==1, detail         
matrix pct_nodriver_rev = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_nodriver_rev

**tabela output
mat pct_all=(pct_remain_rev \ pct_switch_rev \ pct_nodriver_rev)
mat rownames pct_all="remaining-drivers" "switch-car-to-public" "non-drivers"
mat colnames pct_all="p99" "p95" "p90" "p75" "p50" "p25" "p10" "p5" "p1"
mat list pct_all
outtable using "$track3/welfare_change_rev", mat(pct_all) replace nobox center ///
 asis caption("Welfare Change for Different Groups - lump sum redistribution") format(%6.3f) clabel(welfare_chg_rev)
matrix drop  pct_all  



 
******** C -  Imposto, Receita subsidia o onibus *******

use "Data/lsum_0.dta", clear
merge 1:1 id_pess using "Data/lsum_rev_bus.dta"
gen dif_logsum= lsum_0- lsum_rev_bus
sum dif_logsum lsum_rev_bus lsum_0
gen pro_tax=0
replace pro_tax=1 if dif_logsum<0
replace pro_tax=-1 if dif_logsum>0
tab pro_tax if pro_tax~=0
tab1 pro_tax [fweight=round(fe_pess)]
estpost tabulate pro_tax [fweight=round(fe_pess)], nototal
matrix freq_per_sub= e(b)\e(pct)
matrix rownames freq_per_sub= N "\%"
matrix colnames freq_per_sub= Against Neutral Pro
outtable using "$track3/protax_rev_bus_table", mat(freq_per_sub) replace ///
nobox center asis caption("Pro and Against with Bus Subsidy") ///
format(%6.0f) clabel(freqper_bus_sub)



*** table of mode choice joint distribution, pre and post policy
use "Data/choice_0.dta", clear
collapse (max) choice_0 fe_via, by(id) 
save "Data/choice_0_via.dta", replace
use "Data/choice_rev_bus.dta", clear
collapse (max) choice_rev_bus, by(id) 
merge 1:1 id using "Data/choice_0_via.dta"
tabulate choice_0 choice_rev_bus [fweight=round(fe_via)], matcell(temp1)
mat list temp1
scalar row=rowsof(temp1)
mat ones=J(1,row,1)
mat tot_row=ones*temp1
mat temp11=temp1\tot_row
scalar col=colsof(temp1)
mat ones=J(1,col,1)
mat tot_col=temp11*ones'
mat ch0_pu=temp11,tot_col
mat rownames ch0_pu="Bus" "Rail" "Driving" "Moto" "Taxi" "Other" "Total"
mat colnames ch0_pu="Bus" "Rail" "Driving" "Moto" "Taxi" "Other" "Total"
outtable using "$track3/choice_0_bus_subsidy", mat(ch0_pu) replace nobox ///
 asis caption("Transition matrix - tax and bus subsidy") format(%-12.0fc) clabel(transition_bus_sub)
matrix drop  ch0_pu temp1 tot_row ones temp11  tot_col 

******** table of time change for drivers
use "Data/choice_0.dta", clear
merge 1:1 id dup using "Data/choice_rev_bus.dta"
gen diff= time_rev_bus-time_0
sum diff [fweight=round(fe_via)] if  diff<0 & choice_rev_bus==3 & choice_0==3, detail
histogram diff [fweight=round(fe_via)] if  diff<0  & choice_rev_bus==3 & choice_0==3, kdensity frequency ytitle("Frequency") xtitle("Time Difference - Minutes") scheme(sj)
graph export "Fig02.pdf", replace




******* Welfare Change ****

* dummy que identifica que usou o carro ao menos uma vez
use "Data/choice_0.dta", clear 
gen carro_id=0
replace carro_id=1 if choice_0==3
bysort id_pess: egen car_user_0=max(carro_id)
drop carro_id

* dummy que identifica que usou o carro ao menos uma vez com o imposto
merge 1:1 id dup using "Data/choice_rev_bus.dta"
gen carro_id=0
replace carro_id=1 if choice_rev_bus==3
bysort id_pess: egen car_user_rev_bus=max(carro_id)
drop carro_id

*** switchers: car to other (bus+rail) 
gen switcher_rev_bus=0
replace switcher_rev_bus=1 if car_user_0==1 & car_user_rev_bus==0
qui collapse  (mean)  car_user_0  car_user_rev_bus fe_pess switcher_rev_bus, by(id_pess)
merge 1:1 id_pess using "Data/lsum_0.dta", nogenerate
merge 1:1 id_pess using "Data/lsum_rev_bus.dta", nogenerate
gen dif_logsum=(lsum_rev_bus-lsum_0)/lsum_0  
sum dif_logsum [fweight=round(fe_pess)]  if switcher_rev_bus~=0 , detail         
matrix pct_switch_rev_bus = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_switch_rev_bus

*** remaining drivers
gen remaining_rev_bus=0
replace remaining_rev_bus=1 if car_user_0==1 & car_user_rev_bus==1
sum dif_logsum [fweight=round(fe_pess)] if remaining_rev_bus==1, detail         
matrix pct_remain_rev_bus = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_remain_rev_bus
 
*** no drivers
gen nodrivers_rev_bus=0
replace nodrivers_rev_bus=1 if car_user_0==0 & car_user_rev_bus==0
sum dif_logsum [fweight=round(fe_pess)] if nodrivers_rev_bus==1, detail         
matrix pct_nodriver_rev_bus = (r(p99), r(p95), r(p90), r(p75), r(p50), r(p25), r(p10), r(p5), r(p1))
matrix list pct_nodriver_rev_bus

**tabela output
mat pct_all=(pct_remain_rev_bus \ pct_switch_rev_bus \ pct_nodriver_rev_bus)
mat rownames pct_all="remaining-drivers" "switch-car-to-public" "non-drivers" 
mat colnames pct_all="p99" "p95" "p90" "p75" "p50" "p25" "p10" "p5" "p1"
mat list pct_all
outtable using "$track3/welfare_change_rev_bus", mat(pct_all) replace nobox center ///
 asis caption("Welfare Change for Different Groups - public transit subsidies") format(%6.3f) clabel(welfare_chg_rev_bus)
matrix drop  pct_all  



***** DRIVING PERMITS MARKET


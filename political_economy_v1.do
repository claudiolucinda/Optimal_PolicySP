 * Analise politica - majority voting - da aceitacao do pedigio urbano



clear

* QUEM E VOCE???
* lucinda declara lucinda=1 e moita declara lucinda=0
* todos os demais enderecos se ajustam automaticamente (I wish...)
local lucinda=0

if `lucinda'==1 {
   cd "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"
   global track "Data/"
   global track1 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta"
}
else {
	cd "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/"
	*cd "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL"
	global track "Data/"
	global track1 "/Users/Rodrigo/Dropbox/Lucinda-Moita/Pesquisa OD/Bases dta/"
	*global track1 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta"
	*global track2 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data"
	global track2 "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/Data"
	}

capture confirm file "Data/dados_start00.dta" 

if _rc~=0 {
	do "Demanda_v03.do"    
}
else {
	use "Data/dados_start00.dta", clear
}

drop if id==.
save "Data/dados_start.dta", replace

*tempname p
*postfile `p' tax logsum totcost tottrips average_cost mcost using "$track2/Dados_tabela.dta", replace
*postfile `p' tax tottrips average_cost mcost using "$track2/Dados_tabela3.dta", replace

*modos de transporte: 1"Bus" 2"Rail" 3"Driving" 4"Motorcycle" 5"Taxi" 6"Other"


*** 0 -  calculando o logsum sem imposto (benchmark)

* prevendo as probabilidades
estimates use "Data/modelo.ster"
cap drop problogit_old
qui mixlpred problogit_old, nrep(50)
qui drop if incinc==.
qui drop if id==.

cap drop inv_inc m_choice
gen inv_inc=1/incinc
*mixlogsum lsum_tax if e(sample), intvar(inv_inc) intcoeff(costxrenda)
mixlogsum lsum_0, intvar(inv_inc) intcoeff(costxrenda)
*acha a escolha prevista
bysort id: egen double probmax=max(problogit_old)
gen m_choice=0
replace m_choice=1 if probmax==problogit_old
qui gen choice_0=m_choice*dup
keep problogit_old lsum_0 choice_0 id dup fe_via

save "Data/lsum_0.dta", replace





* 1 - define o imposto que se quer analisar, em geral o otimo
global tax=9.45

* 2 - preciso que, dado um imposto, as probabilidades convirjam
use "Data/dados_start.dta", clear
qui gen costcost_0=costcost
qui gen costxrenda_0=costxrenda
qui generate timetime_1=timetime
qui replace costcost=costcost_0+$tax if dup==3 & dummy_ce==1
qui replace costxrenda=(costcost_0+$tax)/incinc if dup==3 & dummy_ce==1
estimates use "Data/modelo.ster"
* prevendo as probabilidades
cap drop problogit_old
qui mixlpred problogit_old, nrep(50)
qui drop if incinc==.
qui drop if id==.
replace fe_via=round(fe_via)
save "Data/dados_demanda.dta", replace
run "miolo_mix_2.do"

* 3 - calcula o logsum
*mixlogsum lsum_tax if e(sample), intvar(inv_inc) intcoeff(costxrenda)
gen inv_inc=1/incinc
mixlogsum lsum_tax, intvar(inv_inc) intcoeff(costxrenda)
*acha a escolha prevista
bysort id: egen double probmax=max(problogit_old)
cap drop m_choice
gen m_choice=0
replace m_choice=1 if probmax==problogit_old
qui gen choice_tax=m_choice*dup
rename problogit_old problogit_tax
keep problogit_tax lsum_tax choice_tax id dup
keep if dup==3


merge m:m id using "Data/lsum_0.dta"


*******  ANALISE DO EFEITO DO IMPOSTO *******

******  A - sem reveneu recycling
gen dif_logsum= lsum_0- lsum_tax
sum dif_logsum lsum_tax lsum_0, detail

gen pro_tax=0
replace pro_tax=1 if dif_logsum<0
replace pro_tax=-1 if dif_logsum>0
replace pro_tax=0 if m_choice==0
tab pro_tax
tab pro_tax if pro_tax~=0
tab1 pro_tax [fweight=fe_via]
* fator de explansao da viagem: fe_via



******  B - com revenue recycling ******

*** (i) calculando o numero de viagens total na cidade
gen choice_car=0
replace choice_car=1 if choice_tax==3
gen choice_car_pre=0
replace choice_car_pre=1 if choice_0==3
sum choice_car choice_car_pre
display r(sum)
local ncar=r(sum)
sum choice_car choice_car_pre [fweight=fe_via] 
display r(sum)
local ncar=r(sum)

*** (ii) calculando a receita
gen revenue=choice_car*$tax
replace revenue=0 if dummy_ce~=1
sum revenue
display r(sum)
global rev=r(sum)
sum revenue [fweight=fe_via]
display r(sum)
global revweight=r(sum)


*** (iii)  redistribuindo a receita do imposto

** (iii-a) para toda a populacao
bysort id_pess: gen idn=_n
replace idn=. if idn~=1
replace fe_pess=round(fe_pess)
sum idn [fweight=fe_pess]
display r(sum)
global npess=r(sum)

* (1) define renda que retorna para cada pessoa
global rebate=$revweight / $npess

* (2) preciso que, dado um imposto, as probabilidades convirjam

*seleciono quem recebe o rebate  
qui replace costcost=costcost_0+$tax if dup==3 & dummy_ce==1
qui replace costcost=costcost-$rebate 
qui replace costxrenda=(costcost)/incinc 
estimates use "Data/modelo.ster"
* prevendo as probabilidades
cap drop problogit_old
qui mixlpred problogit_old, nrep(50)
qui drop if incinc==.
qui drop if id==.
replace fe_via=round(fe_via)
save "Data/dados_demanda.dta", replace
run "miolo_mix_2.do"

* 3 - calcula o logsum
*mixlogsum lsum_tax if e(sample), intvar(inv_inc) intcoeff(costxrenda)
replace inv_inc=1/incinc
mixlogsum lsum_rev, intvar(inv_inc) intcoeff(costxrenda)
*acha a escolha prevista
bysort id: egen double probmax=max(problogit_old)
cap drop m_choice
gen m_choice=0
replace m_choice=1 if probmax==problogit_old
qui gen choice_rev=m_choice*dup



merge m:m id using "Data/lsum_0.dta"


******  A - sem revenue recycling
gen dif_logsum= lsum_0- lsum_rev
sum dif_logsum lsum_tax lsum_rev lsum_0
gen pro_tax=0
replace pro_tax=1 if dif_logsum<0
replace pro_tax=-1 if dif_logsum>0
replace pro_tax=0 if m_choice==0
tab pro_tax  if idn==1
tab pro_tax if pro_tax~=0
tab1 pro_tax [fweight=fe_via] if idn==1
* fator de explansao da viagem: fe_via

* (ii) somente para os que tem carro 









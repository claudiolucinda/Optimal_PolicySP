***********************************************************
* Rotina Stata para organizar o trabalho
* Mexer somente nesta rotina
* Copyright 2014 Claudio R. Lucinda e Leandro Meyer
* FEA-RP/USP
***********************************************************

clear all
*set mem 6g
set more off, permanently
set seed 361
set matsize 800
* Selecionar o endereço de destino
* Coloca o seu endereço abaixo do meu e quando usar, comenta o meu e usa o seu
* Os Códigos vão ficar no diretório "trunk"
* Os dados estão na OD
* Os resultados da manipulação vão para o diretório Output
* cd "C:\Users\claudiolucinda\Documents\banco-mundial\"
*cd "C:\Users\CLAUDIOLUCINDA\Documents\Consultoria\Transport Demand\banco-mundial\"
*cd "C:\Users\Leandro\Desktop\Projetos\Pedágio Urbano\banco-mundial\"
* Diretório Máquina virtual Departamento

*global track "/Users/Rodrigo/Dropbox/Lucinda-Moita/"
*global track "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita"
global track "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita"
*cd "C:\Users\claudiolucinda\Documents\banco-mundial\"
*cd "/Users/Rodrigo/Dropbox/Lucinda-Moita/"
cd "$track"
*cd "C:\Users\claudiolucinda.FEA-RP\Documents\banco-mundial\"


****************************************************
* Checando se Possui um Diretório Output
****************************************************


*use "trunk\Pesquisa OD\Bases dta\banco_de_dados_od_2007_corrigido.dta", clear
use "$track/Pesquisa OD/Bases dta/banco_de_dados_od_2007_corrigido.dta", clear
*use "$track\Pesquisa OD\Bases dta\banco_de_dados_od_2007_corrigido.dta", clear

**************************************************
* Estatísticas Descritivas e Gráficos
**************************************************
*Variáveis de modal
quietly{
	sort modoprin
	by modoprin: gen modoprinN=_N
	gen modoprin_2=modoprin
	replace modoprin_2=19 if modoprinN<10000
	label define lmodoprin_2 1"Bus (SP)" 6"Driving" 7"Shared Ride" 12"Subway" 16"Walking" 19"Other options"
	label values modoprin_2 lmodoprin_2
}

quietly{
	sort modo2
	by modo2: gen modo2N=_N
	gen modo2_2=modo2
	replace modo2_2=19 if modo2N<1000
	label define lmodo2_2 1"Bus (SP)" 9"MicroBus(SP)" 12"Subway" 13"Train" 19"Other options"
	label values modo2_2 lmodo2_2
}

label define lmodoprin 1"Bus(SP)" 2"Bus(Intermunicipal)" 3"Bus(Metrop)" 4"Bus(Private)" 5"Scholar" 6"Driving" 7"Shared Ride" 8"Cab" 9"MicroBus(SP)" 10"Microbus(Intermunicipal)" 11"Microbus(Metrop)" 12"Subway" 13"Train" 14"Motorcycle" 15"Bike" 16"Walking" 17"Other" 
label values modoprin lmodoprin

label define lmodo2 1"Bus(SP)" 2"Bus(Intermunicipal)" 3"Bus(Metrop)" 4"Bus(Private)" 5"Scholar" 6"Driving" 7"Shared Ride" 8"Cab" 9"MicroBus(SP)" 10"Microbus(Intermunicipal)" 11"Microbus(Metrop)" 12"Subway" 13"Train" 14"Motorcycle" 15"Bike" 16"Walking" 17"Other" 
label values modo2 lmodo2

*Criando variáveis de zona
*do "branch04\trunk\Zoning.do"
do "branch04/paper_non_optimal_policies_v2015/Zoning.do"
*do "branch04\paper_non_optimal_policies_v2015\Zoning.do"

*Tempo de viagem 
quietly {
	gen ctempo_dec = hr_min_chegada/100
	gen ctempo_h = floor(ctempo_dec)
	gen ctempo_mm = mod(ctempo_dec,1)*100
	gen stempo_dec = hr_min_saida/100
	gen stempo_h = floor(stempo_dec)
	gen stempo_mm = mod(stempo_dec,1)*100
	gen time_h = ctempo_h - stempo_h
	replace time_h = ctempo_h + 24 - stempo_h if stempo_h > ctempo_h
	replace time_h = time_h *60
	gen time_mm = ctempo_mm - stempo_mm
	gen travel_time = time_h + time_mm
}


*Distancia das viagens
gen dist = ((co_d_y-co_o_y)^2 + (co_d_x - co_o_x)^2)^(1/2)/1000 
*deletando distancias com problema
drop if dist == 0 | (dist >=100 & dist <=68000)

*Velocidade
gen vel1 = dist/travel_time*60
gen pico = 0
replace pico = 1 if h_saida >= 5 & h_saida <=8
replace pico = 2 if h_saida >= 12 & h_saida <= 13
replace pico = 3 if h_saida >= 17 & h_saida <= 19

matrix velocidade=J(4, 3, 0) 
local i 0 
levelsof pico, local(colist)
foreach c of local colist{
	     quietly{
		      local ++i
			sum vel1 if pico ==`c'
			matrix velocidade[`i' , 1] = r(mean)
			sum vel1 if pico ==`c' & modo1 == 6
			matrix velocidade[`i' , 2] = r(mean)
			matrix velocidade[`i' , 3] = velocidade[`i' , 2]*0.7071361
		}
}
matrix rownames velocidade = Demais_horários Pico_manhã Pico_almoço Pico_noite
matrix colnames velocidade = vmedia_total vmedia_carros_ajustada
matrix list velocidade, format(%9.3f) ti("Average speed during different periods of the day")
gen vel2 = 0
replace vel2 =  18.390 if pico == 1
replace vel2 = 14.2 if pico == 3
replace vel2 = 8.784 if pico == 2
replace vel2 = 26.237 if pico == 0 


* CRL: Porque você tem estes números aqui? Não entendi, não era simplesmente dist/travel_time ???
*LGM: Como a distância que temos aqui é em linha reta, a medida de velocidade média da nossa amostra não é exatamente a verdadeira velocidade média. 
*Por isso, eu peguei a velocidade média da pesquisa do link abaixo (para pico de manhã e de tarde) e utilizei elas como base para 'corrigir' a velocidade 
*média da nossa amostra nos demais períodos. 


*http://www.nossasaopaulo.org.br/observatorio/regioes.php?regiao=33&tema=13&indicador=119
*pico manhã = 17 km/h
*pico tarde = 14.2 km/h

*Custos Implícitos
gen custo_im = 0
*OBS: RETIREI CUSTO IMPLICITO
*replace custo_im = (vl_ren_i/(30*24))*travel_time/60

*Custos explícitos
gen custo = 0
gen c2 = 0
gen c3 = 0
gen c4 = 0

*Carro
replace custo = (vel2/12.59549)*2.394*(travel_time/60) if modo1 == 6
replace c2 = (vel2/12.59549)*2.394*(travel_time/60) if modo2 == 6
replace c3 = (vel2/12.59549)*2.394*(travel_time/60) if modo3 == 6
replace c4 = (vel2/12.59549)*2.394*(travel_time/60) if modo4 == 6

*Moto
replace custo = (vel2/33.76499)*2.394*(travel_time/60) if modo1 == 14
replace c2 = (vel2/33.76499)*2.394*(travel_time/60) if modo2 == 14
replace c3 = (vel2/33.76499)*2.394*(travel_time/60) if modo3 == 14
replace c4 = (vel2/33.76499)*2.394*(travel_time/60) if modo4 == 14


*Metro, trem e onibus/microonibus municipal
replace custo = 2.3 if modo1 == 12 | modo1 == 13 | modo1 == 1 | modo1 == 9
replace c2 = 1.2 if modo2 == 12 | modo2 == 13 | modo2 == 1 | modo2 == 9

*Taxi 
replace custo = 3.5 + 28*(travel_time/60) if modo1 == 8
replace c2 = 3.5 + 28*(travel_time/60) if modo2 == 8
replace c3 = 3.5 + 28*(travel_time/60) if modo3 == 8
replace c4 = 3.5 + 28*(travel_time/60) if modo4 == 8

*Onibus fretado
replace custo = vel2*0.14*(travel_time/60) if modo1 == 4
replace c2 = vel2*0.14*(travel_time/60) if modo2 == 4
replace c3 = vel2*0.14*(travel_time/60) if modo3 == 4
replace c4 = vel2*0.14*(travel_time/60) if modo4 == 4

*Onibus intermunicipal/metropolitano
*do "C:\Users\Leandro\Desktop\Projetos\Pedágio Urbano\banco-mundial\trunk\Businter"
*do "branch04\trunk\Businter.do"
do "branch04/paper_non_optimal_policies_v2015/Businter.do"
*do "branch04\paper_non_optimal_policies_v2015\Businter.do"

* Custo Estacionamento
gen c5=vl_est if tp_esauto==6
replace c5=0 if c5==.
gen custo_ex = custo + c2 + c3 + c5
gen custo_tot = custo_ex	


* Código só para fazer as tabelas se necessário
local descrs=0

if `descrs'==1 {
	do "branch04\paper_non_optimal_policies_v2015\desc_stat.do"
}
*todos os resultados tem que ser salvos no diretório Output - o "trunk" fica só pros códigos


***************************************************
* Estimativa
***************************************************

* Aqui precisamos trabalhar inicialmente com o mlogit e o nlogit
* Acho que as opções que o agente enfrenta são:
* - Os modais sozinhos
* - algumas (3 ou 4) opções combinadas envolvendo os modais sozinhos
* - Outros (que são a Outside Option)
* - Acho que não devemos colocar "a pé" como opção, pelo motivo Eike Batista que disse antes.
* CRL - Acho a mesma coisa


***************************
**Definindo categorias(2)**
***************************

*do "branch04\trunk\modes.do"
do "branch04/paper_non_optimal_policies_v2015/modes.do"
*do "branch04\paper_non_optimal_policies_v2015\modes.do"


* Limpando o banco para caber
compress

foreach var of varlist c4 c3 c2 custo vel2  vel1 time_mm time_h stempo_dec ctempo_dec modo2_2 modo2N modoprinN tsc_8466 tsc_6994 zonatra1 zona_esc vinc2 vinc1 vl_est tp_esauto setor2 setor1 servir_d servir_o trab2_re trabext2 trabext1 qt_video qt_tvcor qt_radio qt_moto qt_micro qt_mlava qt_gel2 qt_gel1 qt_freez qt_empre qt_bicicle qt_banho qt_aspir {
	drop `var'
	}
* Mesma coisa
foreach var of varlist trab1_re pe_bici ocup2 ocup1 munitra2 munitra1 muni_dom muni_o muni_d muni_t3 muni_t2 muni_t1 muniesc modo4 modo3 modo2 modo1 modoprin min_saida min_cheg f_dom f_pess f_fam hr_min_chegada tp_esbici co_o_y co_d_y co_t3_y co_t2_y co_t1_y co_tr2_y co_tr1_y co_esc_y co_o_x co_d_x co_t3_x co_t2_x co_t1_x co_tr2_x co_tr1_x co_esc_x {
	drop `var'
	}

* Dummy "carro fora de casa"
cap drop dum_saida
cap drop dum_chegada

gen dum_saida=0
gen dum_chegada=0

bysort id_pess hr_min_saida: replace dum_saida=1 if modoprin==6 & motivo_o==8

bysort id_pess hr_min_saida: replace dum_chegada=1 if modoprin==6 & motivo_d==8


cap drop dumSD
*gen dum1=0

bysort id_pess: gen dumSD=dum_saida[_n-1]
bysort id_pess: replace dumSD=0 if dumSD==.
bysort id_pess: replace dumSD=1 if dumSD[_n-1]==1 & dum_chegada[_n-1]==0
	
*gerando modo escolhido
*gen modo_esc=0
*forvalues i=1/$n_esc {
*	replace modo_esc=`i' if asc_`i'==1
*	
*}

gen id = _n
expand $n_esc
sort id
quietly by id:  gen dup = cond(_N==1,0,_n)

*bysort zona_o modo_esc: gen max_mode_o=_N
*bysort zona_d modo_esc: gen max_mode_d=_N
*drop if dup==2 & (max_mode_o<52 | max_mode_d<52)
*drop if dup==3 & (max_mode_o<52 | max_mode_d<52)

*Dummy para auto
mark dummy_auto if qt_auto >=1

*Dummy para centro expandido
mark dummy_ce if zona_ag2 ==1


*dummy para modo escolhido
gen modo_dummy = 0
forvalues l = 1/$n_esc {
	replace modo_dummy = 1 if asc_`l' == 1 & dup == `l'
}

*Marcando origem e destino
gen trab_od=0
replace trab_od=1 if motivo_o <4 & motivo_d == 8 | motivo_d <4 & motivo_o == 8   

*mark trab_od if (motivo_o == 1 | motivo_o == 2 | motivo_o == 3 | motivo_o == 9 | motivo_d == 1 | motivo_d == 2 | motivo_d == 3 | motivo_d == 9 ) 

mark trab_od2 if (motivo_o == 1 | motivo_o == 2 | motivo_o == 3 | motivo_d == 1 | motivo_d == 2 | motivo_d == 3 ) 
mark educ_od if (motivo_o == 4 | motivo_d == 4 ) 
mark trab_educ if (motivo_o == 1 | motivo_o == 2 | motivo_o == 3 | motivo_d == 1 | motivo_d == 2 | motivo_d == 3 | motivo_o == 4 | motivo_d == 4 )


* incluindo estacao de metro e corredor de onibus
*merge m:1 zona_o using "$track\branch04\paper_non_optimal_policies_v2015\corredor_estacao_origem.dta"
merge m:1 zona_o using "$track/branch04/paper_non_optimal_policies_v2015/corredor_estacao_origem.dta"
drop _merge
*merge m:1 zona_d using "$track\branch04\paper_non_optimal_policies_v2015\corredor_estacao_destino.dta"
merge m:1 zona_d using "$track/branch04/paper_non_optimal_policies_v2015/corredor_estacao_destino.dta"
drop _merge
gen estacao11=0
replace estacao11=1 if estacao_o==1 & estacao_d==1
gen corredor11=0
replace corredor11=1 if corr_o==1 & corr_d==1
gen estacao10=0
replace estacao10=1 if estacao_o==1
gen corredor10=0
replace corredor10=1 if corr_o==1 


do "branch04/paper_non_optimal_policies_v2015/cf.do"
*do "branch04\paper_non_optimal_policies_v2015\cf.do"

* Eliminando as alternativa driving para quem não tem carro
drop if dup==3 & modo_dummy==0 & dummy_auto==0

*ajustando renda para o asclogit; colocando '0' no lugar de '.'
gen incinc = 0
forvalues k = 1/$n_esc {
	replace incinc = renda_fa if dup == `k'
*	replace incinc = vl_ren_i if dup == `k'
*	replace cost_`k' = 0 if cost_`k' ==.
*	replace time_`k' = 0 if time_`k' ==.
}
replace incinc=incinc/1000


mark fem if sexo==2
mark n_estudante if estuda==1
mark empreg if cd_ativi==1

/*
*********************
**Multinomial Logit**
*********************
local rownames2 ""
mat results=J(800,4,0)
local i=1


xi: asclogit modo_dummy costcost [pw=fe_via] if trab_od, alt(dup) case(id) base(6) nocons
mat results[`i',1]=_b[costcost]
mat results[`i',2]=_se[costcost]
*mat results[`i',3]=_b[timetime]
*mat results[`i',4]=_se[timetime]
local identif "nada"
local rownames2 "`rownames2' `identif'"

by zona_o zona_d: egen supertot=sum(dup)
xi: reg costcost anda_o  timetime supertot i.dia_sem tempo_via tot_viag incinc idade fem n_estudante no_morad empreg dummy_ce
qui predict double res_cc, residuals

forvalues i=1/$n_esc {

	qui mark depvar if asc_`i'==1 & dup==1
	logit depvar costcost res_cc [pw=fe_via] if trab_od, nocons iterate(50)
	estimates store mod0`i'
	drop depvar
}


estout mod*, cells(b t(par)) stats(chi2 p converged)
*/



label variable incinc "Income in 1000BRL"
label variable idade "Age"
label variable n_estudante "Student"
label variable no_morad "HH Size"
label variable empreg "Formally Employed"
label variable dummy_ce "Exp. Center"
label variable fem "Female"
label variable costcost "Trip Cost"
label variable timetime "Trip Time"

* HA VARIOS OUTLIERS, 99% GERADO PELA REGRESSAO QUE ESTIMA O CONTRAFACTUAL, E 90% REFERENTE AO TAXI.
* SOLUCAO ATUAL: LIMITAR O VALOR MAXIMO
replace costcost=300 if costcost>300
replace timetime=300 if timetime>300

cap drop costxrenda
cap drop timexrenda
qui gen costxrenda=costcost/incinc
qui gen timexrenda=timetime/incinc
 
* esse custo sempre traz de volta o custo original
cap gen custo_backup=costcost
cap gen costxrenda_backup=costxrenda

gen pico1=0
replace pico1=1 if pico!=0
/*
****************************************************************
* Escolhas Originais
*use "/Users/Rodrigo/Dropbox/Lucinda-Moita/branch04/dados_demanda_2014_10_01.dta", clear

**** USAR ESSA EQUA‚AO PARA AJUSTAR A SIMULACAO DE POLITICA ***
xi: asclogit modo_dummy costcost timetime costxrenda timexrenda [pw=fe_via] if trab_od, alt(dup) case(id) base(6) nocons casevars(dummy_ce fem corredor10 estacao10 incinc pico) iter(20) 
est store mod01, title("Work")

 
global modmod "mod01"
global est "01"
*do "branch04\trunk\PE_Asclogit.do"
do "branch04/PE_Asclogit.do"
rename esc_pred0 esc_pred1
rename logsum0 logsum1


*mat rename elasts elasts01
*mat rownames elasts01="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other"
*mat colnames elasts01="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other"

*outtable using "branch04\trunk\Output\elasts01", mat(elasts01) replace nobox center asis caption("Elasts MNL - Work Trips") format(%6.4f) clabel(elast01)
*outtable using "branch04/Output/elasts01", mat(elasts01) replace nobox center asis caption("Elasts MNL - Work Trips") format(%6.4f) clabel(elast01)


*xi: asclogit modo_dummy costcost timetime costxrenda timexrenda [pw=fe_via] if educ_od, alt(dup) case(id) base(6) nocons casevars(dummy_ce fem corredor10 estacao10 incinc pico) iter(20) 
*est store mod02, title("Educ.")
*global modmod "mod02"
*do "branch04\trunk\PE_Asclogit.do"
*do "branch04/PE_Asclogit.do"
*rename esc_pred0 esc_pred2
*rename logsum0 logsum2
*mat rename elasts elasts02
*mat rownames elasts02="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other"
*mat colnames elasts02="Bus" "Rail" "Driving" "Motorcycle" "Taxi" "Other"

*outtable using "branch04\trunk\Output\elasts02", mat(elasts02) replace nobox center asis caption("Elasts MNL - Educ Trips") format(%6.4f) clabel(elast02)
*outtable using "branch04/Output/elasts02", mat(elasts02) replace nobox center asis caption("Elasts MNL - Educ Trips") format(%6.4f) clabel(elast02)


****************************************************************


*qui estout mod01  using "branch04\trunk\Output\asclogit.tex", cells(b(fmt(%6.4f) star) t(par fmt(%6.4f)) ) /// 
qui estout mod01   using "branch04/Output/asclogit.tex", cells(b(fmt(%6.4f) star) t(par fmt(%6.4f)) ) /// 
stats(N chi2 ll, labels(`"Observations"' `"LR chi2"' `"Log-Lik."')) ///
title(Multinomial Logit Results \label{mlogtab}) varlabels(_cons Constant) ///
prehead("\begin{table}[htbp]\caption{@title}" "\begin{center} \tiny" "\begin{tabular}{l*{@M}{rr}}" "\hline \hline") posthead("\hline") label collabels(,none) ///
prefoot("\hline") postfoot("\hline \hline" "\multicolumn{@span}{p{6cm}}{\footnotesize\textit{Source:} Authors' Calculations. @starlegend}" "\end{tabular}" "\end{center}" "\end{table}") style(tex) ///
eqlabels(Alt.Vars. Bus Rail Driving Motorcycle Taxi,span prefix(\hline\multicolumn{@span}{c}{) suffix(})) stardetach replace





*nlogitgen type = dup(publico: 1 | 2 , privado: 3 | 4 | 5 , outros: 6 )
*nlogittree dup type, choice(modo_dummy)
*timer on 3
*nlogit modo_dummy costcost timetime [pw=fe_via] if trab_od || type: , base(outros) || dup: incinc idade fem n_estudante no_morad empreg dummy_ce, base(6) noconst case(id)
*est store mod03, title("Work - Nlogit")
*timer off 3
*timer on 4 
*nlogit modo_dummy costcost timetime [pw=fe_via] if educ_od || type: , base(outros) || dup: incinc idade fem n_estudante no_morad empreg dummy_ce, base(6) noconst case(id) 
*est store mod04, title("Educ - Nlogit")
*timer off 4

*/

tab dup, gen(d1)


foreach var of varlist dummy_ce fem corredor10 estacao10 incinc pico1 dumSD {
		local j=$n_esc-1
		forvalues i=1/`j' {
			qui gen `var'_`i'=d1`i'*`var'
		}
}


local nomevar "Exp. Center" "Female" "Bus Lane" "Metro Station" "Income" "Peak" 
local listmode "Bus" "Rail" "Driving" "Motorcycle" "Taxi"


local i=1
foreach var of varlist dummy_ce fem corredor10 estacao10 incinc pico1 {
	local temp1: word `i' of "`nomevar'"
	forvalues j=1/5 {
		local temp2: word `j' of "`listmode'"
		label variable `var'_`j' "`temp1'-`temp2'"
	}
	local ++i
}


do "branch04/paper_non_optimal_policies_v2015/hdraws_gen.do"
*do "branch04\paper_non_optimal_policies_v2015\hdraws_gen.do"

drop  ctempo_h ctempo_mm stempo_h stempo_mm  tipovg tipo_dom tipo_esc duracao anda_o anda_d sit_fam ///
 h_cheg h_saida idade cd_ativi co_ren_i motivo_d motivo_o cd_renfa nao_dcl_it cd_entre ano_auto1 ano_auto2 ano_auto3

timer on 1 
mixlogit modo_dummy dumSD_* dummy_ce_* fem_* corredor10_* estacao10_* incinc_* pico1_* costxrenda timexrenda [pw=fe_via] if trab_od, group(id) rand(costcost timetime)
timer off 1

estimates store mod01ml, title("Mod. Básico")

mark samp_setter if e(sample)

estimates save ".\pedagio_otimo\Codigos_CRL\Data\modelo_CRL.ster", replace

global vars=e(indepvars)
mixlbeta $vars if e(sample), saving(".\pedagio_otimo\Codigos_CRL\Data\Indiv_coeffs.dta") replace

preserve

use ".\pedagio_otimo\Codigos_CRL\Data\Indiv_coeffs.dta", clear

foreach var of global vars {
	rename `var' beta_`var'
}

sort id 
save ".\pedagio_otimo\Codigos_CRL\Data\Indiv_coeffs.dta", replace

restore
*estimates esample: if samp_setter==1
*use "Data/dados_start.dta", clear
**** 1 - valor inicial do imposto I0=5 *
qui gen costcost_0=costcost
*qui gen costxrenda_0=costxrenda
qui generate timetime_1=timetime

global tax=0

qui replace costcost=costcost_0+$tax if dup==3 & dummy_ce==1 & samp_setter==1
* CRL: Checar a forma aqui
qui replace costxrenda=(costcost_0+$tax)/incinc if dup==3 & dummy_ce==1 & samp_setter==1



estimates use ".\pedagio_otimo\Codigos_CRL\Data\modelo_CRL.ster"
estimates esample: if samp_setter==1
*estimates restore mod01
* prevendo as probabilidades
cap drop problogit_old
qui mixlpred problogit_old, nrep(50)
*qui predict problogit_old, pr
qui drop if incinc==.
qui drop if id==.
replace fe_via=round(fe_via)
save ".\pedagio_otimo\Codigos_CRL\Data\dados_demanda.dta", replace
set trace on
do ".\pedagio_otimo\Codigos_CRL\Optimal Nonlinear\miolo_mix_2.do"
set trace off
estimates use ".\pedagio_otimo\Codigos_CRL\Data\modelo_CRL.ster"
estimates esample: if samp_setter==1


keep if e(sample) 

merge m:1 id using ".\pedagio_otimo\Codigos_CRL\Data\Indiv_coeffs.dta", nogen

gen xi=0
foreach var of global vars {
	replace xi=xi+beta_`var'*`var'
}


gen vot=(beta_timetime)/(beta_costcost)

gen ci=(xi/beta_costcost)+costcost_0+vot*timetime
gen votdt=vot*dtdtraff


qui replace costcost=costcost_0+votdt if dup==3 & dummy_ce==1 & samp_setter==1
* CRL: Checar a forma aqui
qui replace costxrenda=(costcost_0+votdt)/incinc if dup==3 & dummy_ce==1 & samp_setter==1

estimates use ".\pedagio_otimo\Codigos_CRL\Data\modelo_CRL.ster"
estimates esample: if samp_setter==1
*estimates restore mod01
* prevendo as probabilidades
cap drop problogit_old
qui mixlpred problogit_old, nrep(50)
*qui predict problogit_old, pr
qui drop if incinc==.
qui drop if id==.
replace fe_via=round(fe_via)
save ".\pedagio_otimo\Codigos_CRL\Data\dados_demanda.dta", replace
cd "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"

do ".\Code_Analysis\Optimal_PolicySP\miolo_mix_2.do"
estimates use ".\Data\modelo_CRL.ster"
estimates esample: if samp_setter==1


keep if e(sample) 


gen xi_fin=0
foreach var of global vars {
	replace xi_fin=xi_fin+beta_`var'*`var'
}


gen vot_fin=(beta_timetime)/(beta_costcost)

gen ci_fin=(xi_fin/beta_costcost)+costcost_0+vot_fin*timetime
gen votdt_fin=vot*dtdtraff

sort origem destino
merge m:1 origem destino using ".\pedagio_otimo\Codigos_CRL\Data\temp_rotas_3.dta", nogen


* Falta aqui
* a) Achar a equação do tempo e pegar o coeficiente do tráfego
* b) Achar o tráfego.


gen vot_time=vot*timetime
bysort origem destino: egen vot_tot2=sum(vot_time)

gen NL_tax=(vot_tot2-vot_time)*dtdtraff
gen NL_tax_trip=NL_tax*timetime

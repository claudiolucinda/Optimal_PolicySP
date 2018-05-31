*** loop para as probabilidade convergirem, dado um imposto
generate diff=1
scalar flag=1
scalar max_diff=1
scalar inner_tol=1e-1
while max_diff>inner_tol {

	**** 2 - prevendo a escolha do meio com imposto


	* as probabilidades previstas nao somam 1!!!!!!!!! 
	* o que define a viagem nao e idpessoa!!!!!

	* definindo qual o meio escolhido pela simulacao
	*sort id
	run "$track2/miolo_SD.do"
	qui gen marcador=m_choice*dup
	
	
	**** 3 - recalculando o transito por meio de transporte em cada rota
	
	local pk=1
	local t=3
	* salvando os dados para usar varias vezes no loop a seguir
	qui save "./Data/temp_miolo_loop.dta", replace
	foreach xx in manha noite off {
		use "Data/temp_miolo_loop.dta", clear
		if `pk'==3 {
		local t=8
		}

		qui gen soma=fe_via if pico_`xx'==1
		* loop nos meios de transporte
		* soma quantas pessoas usaram um determinado meio de transporte em cada rota
		forvalues i=1/6 {
			preserve
			* por rota (origem e destino), soma as pessoas que estao usando cada meio
			* ATENCAO : checar se quando a soma for zero, esta aparecendo zero e nao missing
			*qui collapse (sum) soma [fw=fe_via] if marcador==`i', by(origem destino)
			qui collapse (sum) soma if marcador==`i', by(origem destino)
			sum
			replace soma=0 if soma==.
			*rename zona_o origem
			*rename zona_d destino
			rename soma soma_`i'
			qui save "Data/temp_rotas_`i'.dta", replace
			restore
		}

	qui use "Data/temp_rotas_1.dta", clear
	forvalues i=2/6 {
		qui merge 1:1 origem destino using "Data/temp_rotas_`i'.dta", keepusing(soma_`i') nogen
	}
	* fazendo o merge com a tabela que tem os caminhos das rotas
	sort origem destino
	* CRL: De onde veio isso aqui?
	* RM: do do-file que organizou os dados para a regressao de tempo em transito
	qui merge 1:1 origem destino using "Data/rotas_tudo.dta", nogen keep(match)
	*keep if _merge==3
	drop v24-v462
	sort origem destino
	*replace soma_3=0 if soma_3==.
	*replace soma_1=0 if soma_1==.
	

	qui save "Data/temp_rotas.dta", replace

	qui reshape long v,i(origem destino) j(caminho)
	qui drop if v==.
	qui collapse (sum) soma_*, by(v)

	rename soma_1 trafego_1
	rename soma_2 trafego_2
	rename soma_3 trafego_3
	rename soma_4 trafego_4
	rename soma_5 trafego_5
	rename soma_6 trafego_6
	rename v zona
	sort zona

	* esse arquivo tem o trafego por meio de transporte em cada zona, por periodo
	qui save "Data/trafego_`xx'.dta", replace

	* agora vai usar o caminho de zonas de uma rota, e colocar o transito existente em cada zona
	* usando o arquivo trafego.dta
	use "Data/temp_rotas.dta", clear
	cap drop _merge
	* NAO ENTENDI DIREITO ESTA PARTE!!!!!
	* ACHO QUE ESTA COLOCANDO NA LINHA DE UMA ROTA, PARA CADA REGIAO DESTA ROTA, O 
	* TRANSITO ASSOCIADO A ELA
	foreach var of varlist v* {
		qui gen zona=`var'
		sort zona 
		qui merge m:1 zona using "Data/trafego_`xx'.dta", keep(match master) nogen
		cap drop _merge
		rename trafego_1 tr_`var'_1
		rename trafego_2 tr_`var'_2
		rename trafego_3 tr_`var'_3
		rename trafego_4 tr_`var'_4
		rename trafego_5 tr_`var'_5
		rename trafego_6 tr_`var'_6
		drop zona
	}

	* ESTA SOMANDO NA LINHA - CHEGA NO TRANSITO TOTAL POR MEIO DE TRANSPORTE EM CADA ROTA
	qui egen traf_tot_1=rowtotal(tr_*_1)
	qui egen traf_tot_2=rowtotal(tr_*_2)
	qui egen traf_tot_3=rowtotal(tr_*_3)
	qui egen traf_tot_4=rowtotal(tr_*_4)
	qui egen traf_tot_5=rowtotal(tr_*_5)
	qui egen traf_tot_6=rowtotal(tr_*_6)
	keep destino origem traf_tot_*
	*label 1 "Bus" 2 "Rail" 3 "Driving" 4 "Motorcycle" 5 "Taxi" 6 "Other"
	*save ".\Data\rotas_prev`k'.dta", replace
	qui save "Data/rotas_prev.dta", replace


 
	*qui merge 1:1 origem destino using "Data/rotas_prev.dta", nogen
	*qui gen traf_tot_tudo=(traf_tot_1+ traf_tot_2+ traf_tot_3+ traf_tot_4+ traf_tot_5+ traf_tot_6)/1000000
	*qui replace traf_tot_3=traf_tot_3/1000000 
	*qui replace traf_tot_1=traf_tot_1/1000000 
	***** aqui 4 È onibus, 6  È carro, e 12 È metro

	rename traf_tot_3 traf_tot_car
	rename traf_tot_1 traf_tot_bus
	gen peak=`pk'
	* AQUI ESTA DIVIDINDO PELO NUMERO DE HORAS DO PERIODO
	* A REGRESSAO FEZ ISSO? SIM
	replace traf_tot_car=traf_tot_car/`t'
	replace traf_tot_car=traf_tot_car/`t'
	*replace traf_tot_car=traf_tot_car
	*replace traf_tot_car=traf_tot_car
    gen traf_tot_all=traf_tot_car+traf_tot_bus
	local pk=`pk'+1

	cap drop tr_car* tr_bus* v* soma*
	save "Data/traf_rotas_`xx'.dta", replace
	}

	
	****************

* gerar var tempo de viagem por meio de transporte
use "Data/tempo_viagem_dados.dta", clear
drop traf_tot_all traf_tot_bus traf_tot_car l_traf_bus_sqr l_traf_car_sqr l_traf_tot_all ///
 l_traf_tot_bus l_traf_tot_car l_traf_tot_sqr traf_tot_car_cub traf_tot_car_sqr 
* adiciona o trafego  - TRAFEGO TOTAL (TUDO!!)
merge 1:1 origem destino peak using "Data/traf_rotas_noite.dta"
drop if _merge==2
drop _merge
merge 1:1 origem destino peak using "Data/traf_rotas_off.dta", update
drop if _merge==2
drop _merge
merge 1:1 origem destino peak using "Data/traf_rotas_manha.dta", update 
drop if _merge==2
drop _merge

replace l_dist=0.001 if l_dist==.	
qui gen l_traf_tot_all=ln(traf_tot_all)
qui gen l_traf_tot_car=ln(traf_tot_car)
qui gen l_traf_car_sqr=l_traf_tot_car^2
qui gen l_traf_tot_bus=ln(traf_tot_bus)
qui gen traf_tot_car_sqr=traf_tot_car^2

cap drop tr_car* tr_bus* v* soma*
*save tempo_viagem_dados.dta, replace

		**** 4 - Tempo previsto mÈdio em cada rota por meio (carro, onibus, metro)
	** CRL: De onde veio este "tempo_viagem_dados"?
	
	
	* PROBLEMA: ESTOU USANDO OS MICRODADOS PARA CALCULAR O VALOR PREVISTO NUM MODELO COM OS DADOS AGREGADOS POR ROTA
	* onibus
	estimates use "Data/traffic2time_bus.ster"
	preserve
	qui predict tempo_bus_pred, xb
	qui replace tempo_bus_pred=. if tempo_via_4==.
	replace tempo_bus_pred=exp(tempo_bus_pred)
	keep destino origem peak tempo_bus_pred
	qui generate dup=1
	drop if destino~=0 | origem~=0
	qui save "Data/tempo_bus_pred.dta", replace
	restore

	* carro
	estimates use "Data/traffic2time_car.ster"
	preserve
	*qui replace traf_tot6= traf_tot_3
	*qui replace traf_tot4= traf_tot_1
	qui predict tempo_car_pred, xb
	*matrix bcar=e(b)
	global dtdtraff=_b[traf_tot_car]
	qui replace tempo_car_pred=. if tempo_via_6==.
	*keep destino origem peak tempo_car_pred dtdtraff
	drop if destino==0 | origem==0
	qui generate dup=3
	qui save "Data/tempo_car_pred.dta", replace
	restore

	* metro
	*qui reg tempo_via_12 traf_tot_all dist corr* metro*
	*preserve
	*qui replace traf_tot_all= traf_tot_tudo
	*qui predict tempo_metro_pred, xb
	*qui replace tempo_metro_pred=. if tempo_via_12==.
	*keep destino origem tempo_metro_pred
	*qui generate dup=2
	*qui save "Data/tempo_metro_pred.dta", replace
	*restore



	**** 5  - Checar se convergiu para um dado imposto
	* ver se as escolhas/probabilidades mudaram de uma iteração (t-1) para outra (t)
	 
	* as escolhas em t
	use "Data/dados_demanda.dta", clear
	drop if origem==0 | destino==0
	estimates use "Data/Modelo.ster"
	*qui xi: asclogit modo_dummy costcost timetime costxrenda timexrenda [pw=fe_via] if trab_od, alt(dup) case(id) base(6) nocons casevars( incinc idade fem n_estudante no_morad empreg) iter(20) 
	*est store mod01, title("Work")

	*rename zona_o origem
	*rename zona_d destino
	merge m:1 origem destino dup peak using "Data/tempo_car_pred.dta", nogen
	merge m:1 origem destino dup peak using "Data/tempo_bus_pred.dta", nogen 
	*qui merge m:1 origem destino dup using "Data/tempo_metro_pred.dta", nogen
	
	replace timetime=tempo_car_pred if tempo_car_pred~=.
	replace timetime=tempo_bus_pred if tempo_bus_pred~=.
	*qui replace timetime=tempo_metro_pred if tempo_metro_pred~=.

	drop timexrenda
	qui gen timexrenda=timetime/incinc
	*qui gen timexrenda=timetime*incinc
	qui mixlpred problogit_new, nrep(50)
/*	
	if $permits_system==1 {
		replace problogit_old=0 if permit==0 & dup==3 & dummy_auto==1
	}
*/
	*qui predict problogit_new, pr
	qui generate diff=problogit_old-problogit_new
	qui sum diff
	scalar max_diff=r(max)
	display "Max. Difference:"
	display max_diff
	qui replace problogit_old=problogit_new
	drop problogit_new tempo_car_pred tempo_bus_pred  diff
	
	scalar flag=flag+1
	qui drop if id==.
	qui save "Data/dados_demanda.dta", replace
}

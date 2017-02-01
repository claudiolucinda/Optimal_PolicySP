 * Figura pra o pedágio ótimo



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

tempname p
*postfile `p' tax logsum totcost tottrips average_cost mcost using "$track2/Dados_tabela.dta", replace
postfile `p' tax tottrips average_cost mcost ext using "$track2/Dados_tabela3.dta", replace

*global tax=1
set trace on
forvalues taxmax=0 (0.5) 16 {
	*local taxmax=15
	global tax=`taxmax'
	run "taxpoint_mix_2.do"

	*local f_taxmax=$lsum_point
	display `taxmax'
	*local f_totcost=$totcost_point
	local f_tottrips=$tottrips_point
	local f_averagecost=$ave_ci
	local f_margcost=$mc
	local f_ext=$ext
	*post `p' (`taxmax') (`f_taxmax') (`f_totcost') (`f_tottrips') (`f_averagecost') (`f_margcost')
	post `p' (`taxmax')   (`f_tottrips') (`f_averagecost') (`f_margcost') (`f_ext')
}

postclose `p'

* gerando o grafico
use "$track2/Dados_tabela3.dta", clear
gen demand= average_cost+ tax
gen diff= mcost- average_cost
rename mcost marg_social_cost
rename average_cost ave_priv_cost
twoway (line ave_priv_cost tottrips, sort) (line marg_social_cost tottrips, sort) (line demand tottrips, sort) if tottrips>40000
*graph export "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data\Graph_optimal_congestion_tax_July_2016.pdf", as(pdf) replace

 * Figura pra o ped·gio Ûtimo



clear all
set more off

* QUEM E VOCE???
* lucinda declara lucinda=1 e moita declara lucinda=0
* todos os demais enderecos se ajustam automaticamente (I wish...)
local lucinda=0

if `lucinda'==1 {
   cd "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"
   global track "Data/"
   global track1 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta"
   global track2 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Code_Analysis\Optimal_PolicySP"
}
else {
	cd "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/"
	*cd "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"
	global track "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/Data/"
	*global track "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data\"
	global track1 "/Users/Rodrigo/Dropbox/Lucinda-Moita/Pesquisa OD/Bases dta/"
	*global track1 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta"
	*global track2 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Code_Analysis\Optimal_PolicySP\"
	global track2 "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/Codigos_CRL/Code_Analysis/Optimal_PolicySP"
	global track3 "/Users/Rodrigo/Dropbox/Lucinda-Moita/pedagio_otimo/paper_apresentacoes/output"
	*global track3 "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\paper_apresentacoes\output"
	}

capture confirm file "Data/dados_start00.dta" 

if _rc~=0 {
	do "Demand_model_v04.do"    
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

tempname p
*postfile `p' tax logsum totcost tottrips average_cost mcost using "$track2/Dados_tabela.dta", replace
postfile `p' tax tottrips average_cost mcost ext using "$track2/Dados_tabela4.dta", replace


global lsum_rebate=0
global rebate=0
global etq=0
global grp_rebate=0
*global tax=1
*set trace off
forvalues taxmax=0 (2) 24 {
	*local taxmax=15
	global tax=`taxmax'
	run "$track2/taxpoint_mix_2.do"

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
use "$track2/Dados_tabela4.dta", clear
gen demand= average_cost+ tax
gen diff= mcost- average_cost
rename mcost marg_social_cost
rename average_cost ave_priv_cost
twoway (line ave_priv_cost tottrips, sort) (line marg_social_cost tottrips, sort) (line demand tottrips, sort) 
*graph export "C:\Users\rodrigomsm\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data\Graph_optimal_congestion_tax_July_2016.pdf", as(pdf) replace

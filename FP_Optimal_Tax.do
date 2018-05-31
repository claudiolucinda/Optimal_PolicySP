***********************************************************
* CÛdigo Para Achar o Ped·gio ”timo Exato
* Algoritmo Fixed Point Iteraction
* Claudio R. Lucinda
***********************************************************

clear

* QUEM E VOCE???
* lucinda declara lucinda=1 e moita declara lucinda=0
* todos os demais enderecos se ajustam automaticamente (I wish...)
local lucinda=1

if `lucinda'==1 {
   cd "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\"
   global track ".\Data\"
   global track1 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\Pesquisa OD\Bases dta\"
   global track2 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Code_Analysis\Optimal_PolicySP"
*   global track_miolo "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Code_Analysis\Optimal_PolicySP"
   
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

capture confirm file "$track/dados_start00.dta" 

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


global tax_1=8

global max_iter=100
global tol=1e-4
local i=1

global grp_rebate=0
global rebate=0
*set trace on
global tax=14
while abs($tax-$tax_1)>abs($tol) & `i'<$max_iter{
	di "Itera√ß√£o: `i'"
	global tax=$tax_1
	
	do "$track2/taxpoint_mix_2.do"
	global tax_1=$ext-(($ext/$tax_1)-1)
	di "t=$tax,t+1=$tax_1"
	local ++i
	



}

di "$tax_1"

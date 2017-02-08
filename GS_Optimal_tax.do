***********************************************************
* Código Para Achar o Pedágio Ótimo Exato
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
   global track2 "C:\Users\claudiolucinda\Dropbox\Lucinda-Moita\pedagio_otimo\Codigos_CRL\Data\"
   
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

capture confirm file ".\Data\dados_start00.dta" 

if _rc~=0 {
	do ".\Demanda_v03.do"    
}
else {
	use ".\Data\dados_start00.dta", clear
}

drop if id==.
save ".\Data\dados_start.dta", replace

global fact_conv=(sqrt(5)+1)/2

global tol=1e-4
global maxiter=1000

global a=8
run "taxpoint_mix_2.do"
global f_a=$ext
global diff_a=abs($a-$f_a)

global b=11
run "taxpoint_mix_2.do"
global f_b=$ext
global diff_b=abs($b-$f_b)

global c=$b - ($b-$a)/$fact_conv
run "taxpoint_mix_2.do"
global f_c=$ext

global d=$a + ($b-$a)/$fact_conv
run "taxpoint_mix_2.do"
global f_d=$ext

local i=1
while abs($diff_a+$diff_b)/2>abs($tol) & `i'<$max_iter{
	global diff_a=abs($a-$f_a)
	global diff_b=abs($b-$f_b)

	local tol_cri=abs($diff_a-$diff_b)
	di "IteraÃ§Ã£o `i'"
	di "Crit_tol: `tol_cri'"
	if $diff_a>$diff_b {
		global b=$c
		run "taxpoint_mix_2.do"
		global f_b=$ext
		global diff_b=abs($b-$f_b)
	}
	else {
		global a=$d
		run "taxpoint_mix_2.do"
		global f_a=$ext
		global diff_a=abs($a-$f_a)
	}
	global c=$b - ($b-$a)/$fact_conv
	global d=$a + ($b-$a)/$fact_conv
	local ++i

}

global Fin_value=($b+$a)/2
di "$Fin_value"

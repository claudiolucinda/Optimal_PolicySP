**************************************************************
* Código para fazer a variável de Dependência de Estado
* Claudio R. Lucinda
* 2018
**************************************************************

scalar max_diff_2=1
scalar inner_tol_2=1e-4
gen problogit_old2=problogit_old
while max_diff_2>inner_tol_2 {

	* as probabilidades previstas nao somam 1!!!!!!!!! 
	* o que define a viagem nao e idpessoa!!!!!

	* definindo qual o meio escolhido pela simulacao
	*sort id
	bysort id: egen double probmax2=max(problogit_old2)

	* 1 para o modo escolhido, 0 nos demais
	cap drop m_choice
	gen m_choice=0
	replace m_choice=1 if probmax2==problogit_old2
	*replace m_choice=1 if probmax==problogit_1
	* ATENCAO: aqui ha missing em incinc, o que faz que m_choice=1 para todas as observacoes de uma mesma id
		* para cada individuo marca qual o meio de transporte escolhido
	qui gen marcador=m_choice*dup

	* Dummy "carro fora de casa"
	cap drop dum_saida
	cap drop dum_chegada
	
	gen dum_saida=0
	gen dum_chegada=0

	bysort id_pess hr_min_saida: replace dum_saida=1 if marcador==6 & _Imotivo_o_8==1

	bysort id_pess hr_min_saida: replace dum_chegada=1 if marcador==6 & _Imotivo_d_8==1


	cap drop dumSD
	*gen dum1=0

	bysort id_pess: gen dumSD=dum_saida[_n-1]
	bysort id_pess: replace dumSD=0 if dumSD==.
	bysort id_pess: replace dumSD=1 if dumSD[_n-1]==1 & dum_chegada[_n-1]==0
	
	estimates use "Data/modelo.ster"
	*estimates restore mod01
	* prevendo as probabilidades
	cap drop problogit_new2
	qui mixlpred problogit_new2, nrep(50)
		qui generate diff_2=problogit_old2-problogit_new2
	qui sum diff_2
	scalar max_diff_2=r(max)
	qui replace problogit_old2=problogit_new2
	drop problogit_new2 diff_2 marcador
	



}

run "$track2/Pred_Choices.do"

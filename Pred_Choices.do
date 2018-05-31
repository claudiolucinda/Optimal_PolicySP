**********************************************************
* Computing Base Predicted Choices
* Claudio R. Lucinda
**********************************************************

bysort id: egen double probmax=max(problogit_old)

* 1 para o modo escolhido, 0 nos demais
cap drop m_choice
gen m_choice=0
replace m_choice=1 if probmax==problogit_old
*replace m_choice=1 if probmax==problogit_1
* ATENCAO: aqui ha missing em incinc, o que faz que m_choice=1 para todas as observacoes de uma mesma id
	* para cada individuo marca qual o meio de transporte escolhido


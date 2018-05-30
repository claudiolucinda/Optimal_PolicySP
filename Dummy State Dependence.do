* Dummy "carro fora de casa"
cap drop dum_saida
cap drop dum_chegada

gen dum_saida=0
gen dum_chegada=0

bysort id_pess hr_min_saida: replace dum_saida=1 if modoprin==6 & motivo_o==8

bysort id_pess hr_min_saida: replace dum_chegada=1 if modoprin==6 & motivo_d==8

order id_pess hr_min_saida hr_min_chegada modoprin motivo_o motivo_d dum_saida dum_chegada

cap drop dum1
*gen dum1=0

bysort id_pess: gen dum1=dum_saida[_n-1]
bysort id_pess: replace dum1=0 if dum1==.
bysort id_pess: replace dum1=1 if dum1[_n-1]==1 & dum_chegada[_n-1]==0


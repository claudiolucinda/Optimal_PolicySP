* Codigo Logsum_mix

qui drop if id==.
sort id
*merge m:1 id using branch04\trunk\Output\hdraws.dta, keep(match) nogen
merge m:1 id using Data/hdraws.dta, keep(match) nogen

estimates use "Data/modelo.ster"
*estimates restore mod01

* Calculando o Excedente do Consumidor
* CRL 23-11-2014
* Comentado extensivamente para o registro das coisas e saber o que alterar com as mudanças no modelo de demanda
* Etapa 1 - lidar com as variáveis que não têm coeficientes aleatórios.
* O objetivo é no final chegar num x*beta para estas variáveis e depois somar os coeficientes das variáveis com RC
* Puxando os nomes dos coeficientes e das variáveis
matrix B=e(b)
matrix list B
*local xlist : colnames B
* Tirando os nomes das variáveis que tem coeficientes aleatórios
*local xlist: subinstr local xlist "costcost" "", all
*local xlist: subinstr local xlist "timetime" "", all
*local xlist: subinstr local xlist "SD: timetime" "", all
*local xlist: subinstr local xlist "SD: costcost" "", all
*gen zr=0
*cap drop lo
drop if incinc==.
*st_view(X=., ., ("dummy_ce_*", "fem_*", "corredor10_*", "estacao10_*", "incinc_*", "costxrenda", "timexrenda", "zr", "zr", "zr", "zr"))

/*
gen prob_dif= problogit_old-probmax
bysort id: egen double prob2max=max(prob_dif) if probmax~=0
replace prob2max=-prob2max
gen diffprob=probmax-prob2max
sum diffprob if diffprob>0

*/
	
* Fazendo o x*beta neste loop
*cap drop lo
*gen lo=0
*foreach var of local xlist {
*	replace lo=lo+_b[`var']*`var' if e(sample)
*}
cap drop delta_ij_*
cap drop sum_i_*
* Agora, neste loop, fazendo as coisas com os coeficientes aleatórios. Tem duas partes:
* (a) Somando os x*beta das variaveis dos coeficientes aleatorios - tanto os mean coefficients quanto os RC*
* Porem, tem uma observacao:
* Foram utilizados os draws gerados por uma sequencia de Halton - que sao gerados da mesma forma que na estimacao do mixlogit
* Alem disso, no mixlogit, sao usados os draws com antithetics - enta`o dos 50 draws originais, temos 100 (50 originais mais 50 com sinais trocados
* Em cada loop - draw - somamos duas vezes, o draw original e o com o sinal trocado. por isso tem dois delta_ij e logsum (que no loop tá como sum_i no final)

****** CUSTOS *********

forvalues i=1/50 {
replace m1_`i'=invnorm(m1_`i')
replace m2_`i'=invnorm(m2_`i')
gen voti_`i'=(_b[timetime]+_b[SD: timetime]*m2_`i'+_b[timexrenda]/incinc)/(_b[costcost]+_b[SD: costcost]*m1_`i'+_b[costxrenda]/incinc)
}

egen m1=rowmean(m1_*)
gen denom=-1/(_b[costcost]+_b[SD: costcost]*m1+_b[costxrenda]/incinc)
egen vot=rowmean(voti_*) 
sum vot, detail

local lo=r(p1)
local up=r(p99)
replace vot=0  if vot < 0 
replace vot=`up' if vot > `up'


gen xi=-(_b[dummy_ce_1]*dummy_ce_1+_b[dummy_ce_2]*dummy_ce_2 +_b[dummy_ce_3]*dummy_ce_3 +_b[dummy_ce_4]*dummy_ce_4+_b[dummy_ce_5]*dummy_ce_5+ /// 
_b[fem_1]*fem_1+_b[fem_2]*fem_2+_b[fem_3]*fem_3+_b[fem_4]*fem_4+_b[fem_5]*fem_5+ ///
_b[corredor10_1]*corredor10_1+_b[corredor10_2]*corredor10_2+_b[corredor10_3]*corredor10_3 +_b[corredor10_4]*corredor10_4+_b[corredor10_5]*corredor10_5+ ///
_b[estacao10_1]*estacao10_1+_b[estacao10_2]*estacao10_2+_b[estacao10_3]*estacao10_3+_b[estacao10_4]*estacao10_4+_b[estacao10_5]*estacao10_5+ ///
_b[incinc_1]*incinc_1 +_b[incinc_2]*incinc_2+_b[incinc_3]*incinc_3+_b[incinc_4]*incinc_4+_b[incinc_5]*incinc_5)

* custo individual
gen ci=xi/denom + 1*costcost_0+vot*timetime
gen votdt=vot*$dtdtraff



/*

mata: mata clear
****mata***
mata
// calculo com a taxa incluida no custo: computar numero de pessoas e logsum
st_view(Dataset=. , . , ("dummy_ce_*", "fem_*", "corredor10_*", "estacao10_*", "incinc_*", "costxrenda", "timexrenda", "m1*", "m2*", "costcost", "timetime", "incinc", "id", "dup", "dtdtraff"),0)
bf = st_matrix("B")
cbf=cols(bf)
cbf
cb=cbf-4
cb
b=bf[1, (1::cb)]






lo=Dataset[.,(1::cb)]*b'
brnd=bf[1,(cb+1::cbf)]
costm=J(1,50,Dataset[., 128])
//incomx==J(1,50,Dataset[., 130])
rin=rows(Dataset)
rin
incmtx=J(rin,50,0)
for (i=1; i<=50; i++) { 
incmtx[.,i]=Dataset[., 130]
 }
timem=J(1,50,Dataset[., 129])
lom=J(1,50,lo)
m1=Dataset[.,(cb+1::cb+50)]
cols(m1)
m2=Dataset[.,(cb+51::cb+100)]
cols(m2)
//mcost=costm:*m1
//mtime=timem:*m2
delta=lom+brnd[1,1]*costm+brnd[1,2]*timem+brnd[1,3]*costm:*m1+brnd[1,4]*timem:*m2
expdelta=exp(delta)
//deltat=delta'
//dltm=mean(deltat)
//dlt=dltm'

uns=J(rin,50,1)
//denominator logsum
den_logsum=bf[1,28]*uns + bf[1,26]:/incmtx +bf[1,30]:*m1


// calculo do custo total e medio: sem a taxa
st_view(Dataset=. , . , ("dummy_ce_*", "fem_*", "corredor10_*", "estacao10_*", "incinc_*", "costxrenda_0", "timexrenda", "m1*", "m2*", "costcost_0", "timetime", "incinc", "id", "dup", "dtdtraff"),0)
bf = st_matrix("B")
lo=Dataset[.,(1::cb)]*b'
costm=J(1,50,Dataset[., 128])
//incomx==J(1,50,Dataset[., 130])
lom=J(1,50,lo)
delta_c=lom+brnd[1,1]*costm+brnd[1,2]*timem+brnd[1,3]*costm:*m1+brnd[1,4]*timem:*m2
deltat_c=delta_c'
dltm_c=mean(deltat_c)
dlt=dltm_c'



// marginal cost 
dtdtraffm=J(1,50,Dataset[., 133])

dcdt=(bf[1,29]*uns+bf[1,27]*uns:/incmtx+bf[1,31]:*m2)
mcostm=dcdt:*dtdtraffm
mcostt=mcostm'
mctt=mean(mcostt)
mcost=mctt'

co=cols(Dataset)
dup=Dataset[.,co-1]
id=Dataset[.,co-2]
end

* clear data in Stata
clear 
* load data from Mata
*drop delta* 
*drop edelta* 
*drop dlt 
getmata(delta*)=delta
getmata(edelta*)=expdelta
getmata(dlt)=dlt
getmata(den_logsum*)=den_logsum
getmata(dup)=dup
getmata(id)=id
getmata(mcost)=mcost
save "Data/Mata_data.dta", replace
use "Data/data_logsum.dta", clear
merge 1:1 dup id using "Data/Mata_data.dta"
//mata
//delta[(1::8),(1::8)]
//dlt[(1::8),1]
//dltm[1,1]
//end


forvalues i=1/50 {
	*gen delta_ij_`i'_plus=lo+_b[timetime]*timetime+_b[costcost]*costcost+((_b[SD: costcost]^2)^0.5)*costcost*invnorm(m1_`i')+((_b[SD: timetime]^2)^0.5)*timetime*invnorm(m2_`i') if e(sample)
	*gen delta_ij_`i'_minus=lo+_b[timetime]*timetime+_b[costcost]*costcost+((_b[SD: costcost]^2)^0.5)*costcost*invnorm(1-m1_`i')+((_b[SD: timetime]^2)^0.5)*timetime*invnorm(1-m2_`i') if e(sample)
	*replace delta_ij_`i'_plus=exp(delta_ij_`i'_plus) if e(sample)
	*replace delta_ij_`i'_minus=exp(delta_ij_`i'_minus) if e(sample)
	bysort id: egen sum_i_`i'=sum(edelta`i') 
	*bysort id: egen sum_i_`i'_minus=sum(delta_ij_`i'_minus) 
	*qui gen cost_i_`i'_plus=sum_i_`i'_plus
	*qui gen cost_i_`i'_minus=sum_i_`i'_minus
	*replace sum_i_`i'=-(ln(sum_i_`i'))/(_b[costcost]+(_b[costxrenda]/incinc)+((_b[SD: costcost]^2)^0.5)*invnorm(m1_`i')) if e(sample)
	replace sum_i_`i'=-(ln(sum_i_`i'))/den_logsum`i' 
	*replace sum_i_`i'_minus=-(ln(sum_i_`i'_minus))/(_b[costcost]+(_b[costxrenda]/incinc)+((_b[SD: costcost]^2)^0.5)*invnorm(1-m1_`i')) if e(sample)
	*gen sum_i_`i'=sum_i_`i'_plus+sum_i_`i'_minus
	*drop sum_i_`i'_plus sum_i_`i'_minus
	*drop delta_ij_`i'* sum_i_`i'_plus sum_i_`i'_minus
}

*cap drop logsum0	
egen logsum=rowmean(sum_i_*)
*egen totcost=rowmean(cost_i_*) if e(sample)
*egen totcost_plus=rowmean(delta_ij_*_plus)
*egen totcost_minus=rowmean(delta_ij_*_minus)
gen totcost=dlt

*replace logsum=logsum/2 if e(sample)
*replace totcost=totcost/2
* Aí aqui divido por 2 de novo porque em cada passada do loop eu tenho dois draws (o normal e o com o sinal trocado).
*drop sum_i*  delta_ij_`i'* lo
matrix drop B



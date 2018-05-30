# Optimal_PolicySP

## Ponto de partida: 
- `Demand_model_v04.do`: Estima o modelo de demanda. Chama os seguintes arquivos:

		+ `Businter.do`: calcula a distribuição dos custos de linhas de ônibus
		+ `modes.do`: Reclassificação das escolhas com base no modo principal reportado.
		+ `corredor_estacao_origem.dta`: dummy se existe corredor de ônibus na zona OD de origem.
		+ `corredor_estacao_destino.dta`: dummy se existe corredor de ônibus na zona OD de destino.
		+ `cf_v2.do`: Calcula os custos de viagem. Os determinados a partir das escolhas efetivas e os determinados a partir das alternativas não escolhidas.
		+ `Zoning.do`: Código para fazer gráficos e agregar as zonas OD em espaços maiores -- Por exemplo, centro expandido.
		+ Salva os seguintes arquivos:
			- `dados_demanda.dta`: dados do modelo de demanda antes de rodar o modelo.
			- `modelo.ster`: arquivo com os resultados do modelo.
			- `Elasticities.txt`: arquivo com a matriz de elasticidades
			- `mixlogit.txt`: arquivo com a tabela de resultados
			- `dados_start00.dta`: dados do modelo de demanda depois de rodar o modelo.
			- `Res_pt1.dta`: absolutamente a mesma coisa que `dados_start00.dta`. **Desnecessário**

## Figura para o Pedágio Ótimo:
- `Figure_gen_Oct17.do`. Chama os seguintes arquivos:

		+ `dados_start00.dta`: modelo de demanda gerado anteriormente. 
		+ `taxpoint_mix_2.do`: calcula as coisas relevantes para um determinado imposto.
		+ Salva os seguintes arquivos:
			- `Dados_tabela4.dta`: Dados para se fazer a figura.
			- `Dados_start4.dta`: Dados para iniciar a recursão

## Código para os efeitos no mercado em um ponto:
- `taxpoint_mix_2.do`. Chama os seguintes arquivos:

		+ `Dados_start4.dta`: Dados para fazer os cálculos.
		+ `modelo.ster`: estimativas do modelo de demanda.
		+ `miolo_mix2.do`: faz a iteração das coisas até o tráfego convergir.
		+ `logsum_mix_4.do`: faz o logsum e um treco que eu não entendo. **Mudar e usar a versão ado-file**
		+ `traf_rotas_manha.dta`: para cada par origem-destino, lista quais zonas atravessa.
# Protheus-FWCORM
Classe AdvPL para desempenhar um papél próximo ao de um ORM (Object Relational Mapper) para ambiente TOTVS Protheus.

Com FWCORM e FWCORMStruct compiladas, utilize do exemplo abaixo para observação de seu funcionamento. Note que deverá ser utilizado a chave de um pedido de vendas existente na database

```python
#INCLUDE "TBICONN.CH"
#INCLUDE "PROTHEUS.CH"

User Function ADVPLTest()

	Local nOption := 1

	ConOut("__TesteAdvPL:ENTRADA DA FUNCAO")

	PREPARE ENVIRONMENT EMPRESA '99' FILIAL '01' MODULO 'FAT'

	ConOut("__TesteAdvPL:PREPARE ENVIRONMENT")

	Do Case
	
	Case nOption == 1

		Private oVendas
		Private lRet := nil

		oVendas := FWCORM():New("SC5","Pedidos")
		If oVendas:Seek("Pedidos",xFilial("SC5")+"000001",1) // utilizar um pedido válido na database!!
			oVendas:oData:Pedidos[1]:C5_EMISSAO // "2019/10/30"
			oVendas:oStruct:SC5:SX3:C5_EMISSAO:X3_TITULO // "DT Emissao"
		EndIf
		
	EndCase

	RESET ENVIRONMENT

Return()
```

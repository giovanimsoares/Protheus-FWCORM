#INCLUDE "TBICONN.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} TestAdvpl
//TODO Descrição auto-gerada.
@author giovani
@since 24/07/2019
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
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
		lRet := oVendas:Seek("Pedidos",xFilial("SC5")+"000001",1) // localiza o pedido "001247" e popula oData com todas as colunas que correspondem a ele

	EndCase

	RESET ENVIRONMENT

Return()

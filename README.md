# Protheus-FWCORM
Classe AdvPL para desempenhar um papél similar ao de um ORM (Object Relational Mapper) para ambiente TOTVS Protheus.

Com FWCORM e FWCORMStruct compiladas, utilize do exemplo abaixo para observação de seu funcionamento.

```xBase
#INCLUDE "FWCORM.CH"
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

		// Cria intância da classe FWCORM()
		oVendas := FWCORM():New("SC5","Pedidos")

		// Uso do método Seek()
		// obs.: localiza apenas o registro correspondente à chave de busca e índices informados
		If oVendas:Seek("Pedidos",xFilial("SC5")+"000001",1) 
			ConOut(oVendas:oData:Pedidos[1]:C5_EMISSAO) // "2019/10/30"
			ConOut(oVendas:oStruct:SC5:SX3:C5_EMISSAO:X3_TITULO) // "DT Emissao"
		EndIf

		// Uso do método FindAll()
		// obs.: localiza todos os registros conforme parâmetros de busca informados
		If oVendas:FindAll( { where{C5_NUM = '000001'} } ) 
			oVendas:FindAll( {;
				Where{ C5_CLIENTE ==  '006357' } ;
				  and{ C5_LOJA    ==  '01'     } ;
				  and{ C5_MENNOTA <>  '      ' } ;
				  and{ C5_EMISSAO == {'20191106','20191107'} } ;
			} )
		EndIf
		
	EndCase

	RESET ENVIRONMENT

Return()
```
# Implementações futuras...
### 1. Método FindAll() 

Incrementar o método para funcionar com argumentos "Or".

### 2. Método SetRelation() 
```xBase
oVendas:SetRelation("SC6",{ {"C6_FILIAL","C5_FILIAL"}, {"C6_NUM","C5_NUM"} },"Itens")
oVendas:SetRelation("SA1",{ {"A1_FILIAL","xFilial('SA1')"}, {"A1_COD","C5_CLIENTE"}, {"A1_LOJA","C5_LOJACLI"} },"Cliente")
```
### 3. Método GetLenght() e getFieldValue() 
```xBase
For nX := 1 to oVendas:GetLenght("Pedidos")
	ConOut(oVendas:getFieldValue("C5_NUM","Pedidos",nY))
	For nY := 1 to oVendas:GetLenght("Itens",nX)
		ConOut(oVendas:getFieldValue("C6_PRODUTO","Itens",{nY,nX}))
	Next
Next
```
### 4. Método updFieldValue() 
```xBase
// Exemplo 1
oVendas:updFieldValue("C5_ENTREG", "PEDIDOS", "AV. DESEMB. SANTOS NEVES, 748", 123 )

// Exemplo 2
For nX := 1 to Len oVendas:GetLenght("Pedidos")
	For nY := 1 to Len oVendas:GetLenght("Itens",nX)
		oVendas:updFieldValue("C6_OBS", "ITENS", "TESTE", {nX,nY} )
	Next
Next

```
### 5. Método GetPosition() 
```xBase
// ############################################################
// Obtem lista de posições referenciando objetos de oVendas
// em que C6_PRODUTO seja igual à "005147".
// ############################################################
// Estrutura de oLista - objeto baseado em Json
// { "ELEMENT":[
//			{
//				"PEDIDOS":1,
//				"ITENS" :[1,2,3]
//			},
//			{
//				"PEDIDOS":2,
//				"ITENS" :[1,2]
//			}
// ] }
// ############################################################
oLista := oVendas:GetPosition( { |obj| obj:PEDIDOS:ITENS:C6_PRODUTO == "005147" } )
aTES := oVendas:getFieldValue("C6_TES","Itens",oLista)
```
### 6. Método upFieldValue() 
```xBase
// ############################################################
// Atualiza o conteúdo de C6_OBS com a string "TESTE" passando
// oLista como argumento. Ou seja, todos os elementos
// referenciados por oLista serão atualizados
// ##
// Obs.: Retorna .T. ou .F. para indicar sucesso ou falha.
// ############################################################
oVendas:updFieldValue( "C6_OBS", "ITENS", "TESTE", oLista )
```

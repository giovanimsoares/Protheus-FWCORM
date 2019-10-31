#INCLUDE "TOTVS.CH"

#DEFINE CLRF CHR(13)+CHR(10)
#DEFINE QT '"'


CLASS FWCORMStruct

	DATA cAlias  // tabela principal do banco de dados para instanciação da classe
	DATA aNames  // nomes das tabelas e campos de cAlias
	DATA aStruct // array de objetos Json utilizado para criar os objetos que povoarão oStruct
	DATA aStrPos // aponta qual é a pocição de cAlias e tabelas relacionadas dentro de aStruct
	DATA oStruct // objeto com toda a estrutura de dicionários de cAlias e tabelas relacionadas

	METHOD New( cAlias ) CONSTRUCTOR
	METHOD GetStruct()
	METHOD GetNames()
	METHOD LoadStruct( cAlias )

ENDCLASS

METHOD New(cAlias) CLASS FWCORMStruct AS OBJECT

	Default cAlias := ""

	If !Empty(cAlias)
		::cAlias  := cAlias
		::aNames  := {}
		::aStrPos := {}
		If !Self:LoadStruct(cAlias)
			Conout( '__FWCORMSTRUCT():NEW() SAYS: FALHA AO CARREGAR A ESTRUTURA DE ' + QT + cAlias + QT )
		EndIf
	Else
		Conout( '__FWCORMSTRUCT():NEW() SAYS: ARGUMENTO CALIAS NAO INFORMADO' )
	EndIf

Return Self

METHOD GetStruct(cAlias) CLASS FWCORMStruct AS OBJECT // UNDEFINED

	// Carrega a estrutura novamente se necessário
	// Obs.: necessário para chamada do método
	// direto de uma classe que herda
	// de FWCORMStruct()
	If ValType(::oStruct) == "U"
		::LoadStruct(cAlias)
	EndIf

Return ::oStruct

METHOD GetNames() CLASS FWCORMStruct AS ARRAY

	If ValType(Self:aNames) != "A"
		::aNames := {}
	EndIf

Return ::aNames

METHOD LoadStruct(cAlias) CLASS FWCORMStruct AS LOGICAL

	Local nI       := 0
	Local nPos     := 0

	Local aX3      := {}
	Local aStruct  := {}
	Local aX3Names := {}

	Local oX2      := JsonObject():New()
	Local oX3      := JsonObject():New()
	Local oStruct  := JsonObject():New()

	Local lOK      := .T.

	While lOK

		// --------------------------------------------------
		// Obtem dados da estrutura SX2 - Tabelas
		// --------------------------------------------------
		DbSelectArea('SX2')
		SX2->(DbSetOrder(1)) // X2_CHAVE
		If SX2->(MsSeek(cAlias))
			oX2['X2_CHAVE  '] := RTrim( SX2->X2_CHAVE   )
			oX2['X2_PATH   '] := RTrim( SX2->X2_PATH    )
			oX2['X2_ARQUIVO'] := RTrim( SX2->X2_ARQUIVO )
			oX2['X2_NOME   '] := RTrim( SX2->X2_NOME    )
			oX2['X2_NOMESPA'] := RTrim( SX2->X2_NOMESPA )
			oX2['X2_NOMEENG'] := RTrim( SX2->X2_NOMEENG )
			oX2['X2_MODO   '] := RTrim( SX2->X2_MODO    )
			oX2['X2_MODOUN '] := RTrim( SX2->X2_MODOUN  )
			oX2['X2_MODOEMP'] := RTrim( SX2->X2_MODOEMP )
			oX2['X2_UNICO  '] := RTrim( SX2->X2_UNICO   )
		Else
			Conout( '__FWCORMSTRUCT():GET() SAYS: O REGISTRO SOLICITADO NAO EXISTE NA SX2 - ' + QT + cAlias + QT )
			lOK := .F. // sinaliza falha
			Loop // abandona execução
		EndIf

		// --------------------------------------------------
		// Obtem dados da estrutura SX3 - Campos
		// --------------------------------------------------
		DbSelectArea("SX3")
		SX3->(DbSetOrder(1)) // X3_ARQUIVO+X3_ORDEM
		If SX3->(MsSeek(cAlias))
			While !SX3->(EOF()) .And. SX3->X3_ARQUIVO == cAlias

				aAdd( aX3, JsonObject():New() )

				nPos := Len(aX3)

				aX3[nPos]['X3_ARQUIVO'] := RTrim(SX3->X3_ARQUIVO)
				aX3[nPos]['X3_ORDEM'  ] := RTrim(SX3->X3_ORDEM  )
				aX3[nPos]['X3_CAMPO'  ] := RTrim(SX3->X3_CAMPO  )
				aX3[nPos]['X3_TITULO' ] := RTrim(SX3->X3_TITULO )
				aX3[nPos]['X3_DESCRIC'] := RTrim(SX3->X3_DESCRIC)
				aX3[nPos]['X3_TITSPA' ] := RTrim(SX3->X3_TITSPA )
				aX3[nPos]['X3_DESCSPA'] := RTrim(SX3->X3_DESCSPA)
				aX3[nPos]['X3_TITENG' ] := RTrim(SX3->X3_TITENG )
				aX3[nPos]['X3_DESCENG'] := RTrim(SX3->X3_DESCENG)
				aX3[nPos]['X3_TIPO'   ] := RTrim(SX3->X3_TIPO   )
				aX3[nPos]['X3_VISUAL' ] := RTrim(SX3->X3_VISUAL )
				aX3[nPos]['X3_CONTEXT'] := RTrim(SX3->X3_CONTEXT)
				aX3[nPos]['X3_F3'     ] := RTrim(SX3->X3_F3     )
				aX3[nPos]['X3_VALID'  ] := RTrim(SX3->X3_VALID  )
				aX3[nPos]['X3_RELACAO'] := RTrim(SX3->X3_RELACAO)
				aX3[nPos]['X3_USADO'  ] := RTrim(SX3->X3_USADO  )
				aX3[nPos]['X3_RESERV' ] := RTrim(SX3->X3_RESERV )
				aX3[nPos]['X3_BROWSE' ] := RTrim(SX3->X3_BROWSE )
				aX3[nPos]['X3_PROPRI' ] := RTrim(SX3->X3_PROPRI )
				aX3[nPos]['X3_ORDEM'  ] := RTrim(SX3->X3_ORDEM  )
				aX3[nPos]['X3_TAMANHO'] := SX3->X3_TAMANHO
				aX3[nPos]['X3_DECIMAL'] := SX3->X3_DECIMAL

				oX3[Rtrim(SX3->X3_CAMPO)] := aX3[nPos]

				aAdd( aX3Names, { RTrim(SX2->X2_CHAVE), RTrim(SX3->X3_CAMPO) } )

				SX3->(DbSkip())
			EndDo
		Else
			Conout('__FWCORMSTRUCT():GET() SAYS: O REGISTRO SOLICITADO NAO EXISTE NA SX3 - ' + QT + cAlias + QT )
			lOK := .F. // sinaliza falha
			Loop // abandona execução
		EndIf
		Exit // abandona laço while
	EndDo

	If lOK

		// Adiciona um elemento no Array de Json Objects
		aAdd( aStruct, JsonObject():New() )

		// Obtem a última posição recém inserida
		nPos := Len(aStruct)

		// Adiciona na posição os objetos Json SX2 e SX3
		aStruct[nPos]['SX2'] := oX2
		aStruct[nPos]['SX3'] := oX3

		// Inicializa ::aStrPos no caso de o método ser executado por uma
		// chamada direta, ou seja, sem passar pelo construtor New()/Create()
		If ValType(Self:aStrPos) != "A"
			::aStrPos := {}
		EndIf

		// Layout de aStrPos
		// ::aStrPos := {;
		// 	{'SC5',1},;
		// 	{'SC6',2} }
		aAdd( ::aStrPos, { cAlias, nPos } )

		// oStruct['SC5'] := aStruct[1]
		// oStruct['SC6'] := aStruct[2]
		// oStruct['SB1'] := aStruct[3]
		// oStruct['SA1'] := aStruct[4]
		// etc...
		For nI:=1 to Len(::aStrPos)
			oStruct[::aStrPos[nI,1]] := aStruct[::aStrPos[nI,2]]
		Next

		// Obtem string Json
		cStruct := oStruct:toJson()

		// Descarta objetos Json não mais utilizados no processo
		FreeObj(oX2)
		FreeObj(oX3)
		FreeObj(oStruct)

		// Deserializa a string Json em um objeto
		FwJsonDeserialize(cStruct,@oStruct)

		::oStruct := oStruct

		// Inicializa ::aNames no caso de o método ser executado por uma
		// chamada direta, ou seja, sem passar pelo construtor New()/Create()
		If ValType(Self:aNames) != "A"
			::aNames := {}
		EndIf

		::aNames := aX3Names

	EndIf

Return lOK

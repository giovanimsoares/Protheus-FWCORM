#Include "TOTVS.ch"

#DEFINE CLRF CHR(13)+CHR(10)
#DEFINE QT '"'


CLASS FWCORM FROM FWCORMStruct

	DATA cAlias  // tabela principal do banco de dados para instanciação da classe
	DATA aLabels // apelidos amigáveis para referenciar tabelas do banco de dados
	DATA oData

	METHOD New( cAlias, cLabel ) CONSTRUCTOR
	METHOD Seek( cName, cSeek, nIndex )
	METHOD FindAll( aExpr )

ENDCLASS


METHOD New(cAlias, cLabel) CLASS FWCORM AS OBJECT //UNDEFINED

	Default cAlias := ""
	Default cLabel := ""

	If !Empty(cAlias)

		_Super:New(cAlias,cLabel)

		::cAlias := cAlias
		::aLabels := {}

		// Layout de aLabels
		// ::aLabels := {;
		// 	{ "SC5" , "Pedidos" };
		//	{ "SC6" , "Itens"   } };
		If !Empty( cLabel )
			aAdd( ::aLabels, { cAlias, cLabel } )
		EndIf
	Else
		ConOut( '__FWCORM():NEW() SAYS: ARGUMENTO CALIAS NAO INFORMADO' )
	EndIf

Return SELF


/*/{Protheus.doc} FWCORMStruct:FindAll()
Localiza um conjunto de registro no banco de dados e popula o objeto oData.
@author Giovani M. Soares.
@since 14/11/2019
@version 1.0
@return lRet, .T. representa sucesso na operação e .F. indica falhas.
@param cAlias, characters, Nome ou apelido da tabela do banco de dados.
@param nIndex, numeric, Índice para busca, valor padrão 1.
@param cSeek, characters, Chave de busca conforme índice informado.
@obs Obs.: O apelido (nome amigável) pode ser utilizado no argumento cAlias do método.
@type Method
/*/
METHOD FindAll( aExpr ) CLASS FWCORM AS LOGICAL

	Local aData        := {}
	Local aSQLExp      := {}
	Local aFields      := {}
	Local nX, nY       := 0
	Local cData        := ""
	Local cField       := ""
	Local cSQLExp      := ""
	Local cSQLAlias    := ""
	Local cSQLTable    := ""
	Local cSQLNickName := ""
	Local lRet         := .F.
	Local oData        := JsonObject():New()
	Local oJsValue     := JsonObject():New()
	Local oStruct

	Default aExpr   := {}

	If Len(aExpr) > 0

		aFields := _Super:GetFields()
		oStruct := _Super:GetStruct()

		aSQLExp := mkSQL(aExpr,aFields,oStruct,::cAlias)

		If Len(aSQLExp) > 0

			cSQLExp := aSQLExp[1]
			aSQLFields := aSQLExp[2]

			// Obtem alias disponível para execução da consulta
			cSQLAlias := GetNextAlias()

			// Verifica se existe consulta aberta para o alias
			If Select(cSQLAlias) > 0
				(cSQLAlias)->(DbCloseArea())
			EndIf

			BeginSQL Alias cSQLAlias
				SELECT * FROM ( %exp:cSQLExp% ) AS QUERY
			EndSQL

			DbSelectArea(cSQLAlias) ; (cSQLAlias)->(DbGoTop())

			If !(cSQLAlias)->(EOF())

				While !(cSQLAlias)->(EOF())

					// { {'SC5','PEDIDOS',{'C5_FILIAL','C5_NUM','...'} },;
					//   {'SC6','ITENS',{'C6_FILIAL','C6_NUM','...'} } }
					For nX:=1 to Len(aSQLFields) // TODO: CONTINUAR DAQUI...
						cSQLTable := aSQLFields[nX,1] // tabela referente aos campos da consulta sql
						cSQLNickName := aSQLFields[nX,2] // apelido da tabela
						For nY:=1 to Len(aSQLFields[nX,3])
							cField := aSQLFields[nX,3,nY]
							oJsValue[cField] := (cSQLAlias)->(&(cField))
						Next
					Next

					aAdd( aData, oJsValue )

					oData[cSQLNickName] := aData // TODO: REVISAR QUANDO HOUVER FUNCIONAMENTO COM O METODO SETRELATION

					(cSQLAlias)->(DbSkip())

				EndDo

				cData := oData:toJson()

				FreeObj(oData)

				FwJsonDeserialize(cData,@oData)

				::oData := oData

				lRet := .T.

			Else
				ConOut( '__FWCORM():FINDALL() SAYS: NAO HA DADOS CORRESPONDENTES A EXPRESSAO DE BUSCA' )
			EndIf
		Else
			ConOut( '__FWCORM():FINDALL() SAYS: A EXPRESSAO DE BUSCA INFORMADA COMO ARGUMENTO NAO E VALIDA ' )
		EndIf
	Else
		ConOut( '__FWCORM():FINDALL() SAYS: ARGUMENTO NAO INFORMADO ' )
	EndIf

Return lRet


/*/{Protheus.doc} FWCORMStruct:Seek()
Localiza um registro no banco de dados e popula o objeto oData.
@author Giovani M. Soares.
@since 28/10/2019
@version 1.0
@return lRet, .T. representa sucesso na operação e .F. indica falhas.
@param cAlias, characters, Nome ou apelido da tabela do banco de dados.
@param nIndex, numeric, Índice para busca, valor padrão 1.
@param cSeek, characters, Chave de busca conforme índice informado.
@obs Obs.: O apelido (nome amigável) pode ser utilizado no argumento cAlias do método.
@type Method
/*/
METHOD Seek( cAlias, cSeek, nIndex ) CLASS FWCORM AS LOGICAL

	Local nPos     := 0
	Local nX, nY   := 0
	Local aData    := {}
	Local aFields  := {}
	Local cField   := ""
	Local cLabel   := ""
	Local oData    := JsonObject():New()
	Local oJsValue := JsonObject():New()
	Local bError   := {||}
	Local lRet     := .F.

	Default nIndex := 1
	Default cSeek  := ""
	Default cAlias := ""

	// Necessário tratamento por meio do BEGIN SEQUENCE
	// pois nem sempre o objeto/array _REMNANT existirá dentro de oXML
	bError := ErrorBlock( {|oError| GetError(oError)})

	BEGIN SEQUENCE

		// --------------------------------------------------
		// Determina a tabela que será utilizada para o seek
		// junto ao banco de dados.
		// Obs.: caso não econtre, tenta localizar a tabela
		//       pelo apelido (nome amigável).
		// --------------------------------------------------
		If cAlias != ::cAlias
			cAlias := getAlias(cAlias,::aLabels)
			cLabel := getLabel(cAlias,::aLabels)
		EndIf

		// --------------------------------------------------
		// Se cAlias existir busca pelo registro conforme
		// argumentos nIndex e cSeek.
		// --------------------------------------------------
		If !Empty(cAlias)

			DbSelectArea(cAlias) ; (cAlias)->(DbSetOrder(nIndex))

			If (cAlias)->(MsSeek(cSeek))

				aFields := _Super:GetFields()

				For nX := 1 To Len( aFields )

					// Considera em aFields, apenas a tabela referente a cAlias
					If aFields[nX,1] != cAlias
						Loop
					EndIf

					// Percorre a lista de nomes de campos contida em aFields na posição 3
					For nY:=1 to Len( aFields[nX,3] )

						cField := aFields[nX,3,nY]

						If !isVirtual( cAlias, cField, ::oStruct )
							oJsValue[cField] := (cAlias)->(&(cField))
						EndIf

					Next

				Next nX

				oData[cLabel] := { oJsValue }

				cData := oData:toJson()

				FreeObj(oData)

				FwJsonDeserialize(cData,@oData)

				::oData := oData

				lRet := .T.

			Else
				ConOut( '__FWCORM():SEEK() SAYS: NAO FOI POSSIVEL LOCALIZAR NENHUM REGISTRO PELA CHAVE E INDICE INFORMADOS -' +;
				' CHAVE: ' + QT + Upper(cSeek) + QT +;
				' INDICE: ' + cValToChar(nIndex) )
			EndIf
		Else
			ConOut( '__FWCORM():SEEK() SAYS: O ARGUMENTO CALIAS INFORMADO NAO E VALIDO - ' + QT + Upper(cName) + QT )
		EndIf

	END SEQUENCE

	ErrorBlock(bError) // restaura tratamento de erro padrão do sistema

Return lRet


Static Function isVirtual(cAlias,cField,oStruct)
	Local cMacro := ""
	Local lVirtual := .F.
	cMacro := "oStruct:" + cAlias +":SX3:"+ cField + ":X3_CONTEXT" // Self:oStruct:SC5:SX3:C5_FILIAL:X3_CONTEXT
	If &(cMacro) == "V" // executa macro e avalia se o campo é real ou virtual
		lVirtual := .T.
	EndIf
Return lVirtual


/*/{Protheus.doc} getLabel
Localiza o apelido do objeto pelo nome do alias informado.
@author Giovani M. Soares.
@since 10/19/2019
@version 1.0
@return cLabel, nome amigável localizado
@param cAlias, characters, nome da tabela para busca
@param aLabel, array, array de apelidos que será realizada a busca
@type Static Function
/*/
Static Function getLabel(cAlias,aLabels)
	Local nPos := 0
	Local cLabel := ""
	If Len( aLabels ) > 0
		nPos := aScan( aLabels, { |x| Upper(x[1]) == Upper(cAlias) } )
		If nPos > 0
			cLabel := aLabels[nPos,2]
		EndIf
	Else
		cLabel := cAlias
	EndIf
Return cLabel


/*/{Protheus.doc} getAlias
Localiza o alias do objeto pelo nome amigável (label) informado.
@author Giovani M. Soares.
@since 10/19/2019
@version 1.0
@return cAlias, alias localizado
@param cLabel, characters, nome amigável para busca
@param aLabels, array, array de apelidos que será realizada a busca
@type Static Function
/*/
Static Function getAlias(cLabel,aLabels)
	Local nPos := 0
	Local cAlias := ""
	If Len( aLabels ) > 0
		nPos := aScan( aLabels, { |x| Upper(x[2]) == Upper(cLabel) } )
		If nPos > 0
			cAlias := aLabels[nPos,1]
		EndIf
	EndIf
Return cAlias


/*/{Protheus.doc} mkSQL
Constrói uma consulta SQL a partir dos parâmetros de entrada aExpr e aFields
@author Giovani M. Soares.
@since 10/19/2019
@version 1.0
@return cSQLExp, expressão SQL para execução
@param aExpr, array, expressão para formatação em sintaxe de consulta sql
@param aFields, array, array contendo o nome dos campos
@type Static Function
/*/
Static Function mkSQL(aExpr,aFields,oStruct,cAlias) // TODO ajustar referencia de aFields

	Local aRet         := {}
	Local aSQLFields   := {}
	Local nX           := 0
	Local nPos         := 0
	Local cLabel       := ""
	Local cField       := ""
	Local cClause      := ""
	Local cSQLExp      := ""
	Local cWhereExp    := ""
	Local xValue       := nil

	For nX:=1 to Len(aExpr)

		// Sintaxe em que expressão e valor são informadas como uma string única
		If Len(aExpr[nX]) == 2

			// Expressão unificada com o valor - "C5_NUM=="000001"
			cExpr := aExpr[nX,2]

			// Identifica o operador para a expressão
			nPos := 0
			Do Case
			Case (nPos := At('=' ,cExpr), nPos) > 0 ; cOperator := "="
			Case (nPos := At('==',cExpr), nPos) > 0 ; cOperator := "="
			Case (nPos := At('!=',cExpr), nPos) > 0 ; cOperator := "<>"
			Case (nPos := At('<>',cExpr), nPos) > 0 ; cOperator := "<>"
			Case (nPos := At('>=',cExpr), nPos) > 0 ; cOperator := ">="
			Case (nPos := At('<=',cExpr), nPos) > 0 ; cOperator := "<="
			Otherwise
				cOperator := ""
			EndCase

			// Obtem nome do campo referenciado pela expressão
			cField := Left(cExpr,nPos-1)

			If !isFieldOK(cField,aFields,oStruct)
				ConOut( '__FWCORM():MKSQL() SAYS: O CAMPO ' +QT+ cField +QT+ ' E INEXISTENTE NO DICIONARIO DE DADOS' ) ; Exit
			EndIf

			// Obtem o valor de comparação referenciado pela expressão
			nPosQuote := At('"',cExpr)
			nPosArray := At('{',cExpr)
			Do Case
				Case nPosQuote == 0 .And. nPosArray == 0        // valor é um numérico
					xValue := Right(cExpr,Len(cExpr)-(nPos+1))

				Case nPosQuote > 0 .And. nPosArray == 0         // valor é uma string
					xValue := SubStr(cExpr,nPosQuote+1,(Len(cExpr)-nPosQuote)-1)  // Right(cExpr,Len(cExpr)-(nPosQuote)+1)
					xValue := "'" + xValue + "'"

				Case nPosQuote > 0 .And. nPosArray > 0          // valor é um array
					xValue := Right(cExpr,Len(cExpr)-(nPosArray-1))
					xValue := StrTran(xValue,'"',"'")
					xValue := StrTran(xValue,'{',"(")
					xValue := StrTran(xValue,'}',")")
					cOperator := "IN" // muda para o operador IN
			EndCase

			// Cláusula da consulta sql (where, and, or)
			cClause := Upper(aExpr[nX,1])

			// Obtem o apelido que será utilizado para referenciar a consulta
			cLabel := aFields[1,2]

			// Monta a expressão Where da consulta SQL
			cWhereExp += Space(1)
			cWhereExp += cClause + Space(1)
			cWhereExp += Upper(cLabel) + "." + cField + Space(1)
			cWhereExp += cOperator + Space(1)
			cWhereExp += xValue

		EndIf
	Next

	// Monta expressão SQL para que será o retorno da função
	If !Empty(cWhereExp)

		cSQLExp += "SELECT " + mkSQLField(aFields,oStruct,@aSQLFields)
		cSQLExp += "FROM " + RetSQLName(cAlias) + " AS " + Upper(cLabel)
		cSQLExp += cWhereExp

		// Marcadores para utilização com Embedded SQL
		cSQLExp := "%" + cSQLExp + "%"

		aRet := {cSQLExp,aSQLFields}

	EndIf

Return aRet


Static Function isFieldOK(cField,aFields,oStruct)
	Local aAux := {}
	Local nX := 0
	Local cAlias := ""
	Local lFieldOK := .F.
	For nX:=1 to Len( aFields ) // percorre lista de campos
		aAux := aFields[nX,3]
		If aScan( aAux, { |x| UPPER( RTRIM(x) ) == UPPER( RTRIM(cField) ) } ) > 0 // localiza na lista de campos o campo desejado
			cAlias := aFields[nX,1]
			If !isVirtual( cAlias, cField, oStruct ) // verifica se o campo é de escopo virtual
				lFieldOK := .T. // se localizou o campo e o mesmo não for virtual, retorna .T.
				Exit // abandona laço for
			EndIf
		EndIf
	Next
Return lFieldOK


Static Function mkSQLField(aFields,oStruct,aSQLFields) //aSQLFields deve ser passado por memory reference @
	Local nLen   := 0
	Local nX, nY := 0
	Local cAlias := ""
	Local cPrefx := ""
	Local cField := ""
	Local cPrefxAnt := ""
	Local cSQLField := ""
	Default aSQLFields := {}
	For nX:=1 to Len( aFields )
		cAlias := aFields[nX,1] // tabela
		cPrefx := aFields[nX,2] // nome amigavel da tabela
		If Empty(cPrefx)
			cPrefx := cAlias
		EndIf
		For nY:=1 to Len( aFields[nX,3] )
			cField := aFields[nX,3,nY] // nome do campo
			If !isVirtual( cAlias, cField, oStruct )
				If !Empty(cSQLField)
					cSQLField += ", "
				EndIf
				cSQLField += Upper(cPrefx)+"."+cField
				If cPrefxAnt != cPrefx
					cPrefxAnt := cPrefx
					aAdd(aSQLFields,{})
					nLen := Len(aSQLFields)
					aAdd(aSQLFields[nLen],cAlias)
					aAdd(aSQLFields[nLen],cPrefx)
					aAdd(aSQLFields[nLen],{})
				EndIf
				nLen := Len(aSQLFields)
				aAdd(aSQLFields[nLen,3],cField) // popula aSQLFields
			EndIf
		Next
	Next
	cSQLField += Space(1)
Return cSQLField


/*
Static Function retNames(aFields,cAlias)
	Local aNames := {}
	Local nX, nY := 0
	Local cField := ""
	Default cAlias := ""
	For nX:=1 to Len( aFields )
		If !Empty(cAlias) .And. cAlias != aFields[nX,1]
			Loop
		EndIf
		For nY:=1 to Len(aFields[nX,3])
			cField := aFields[nX,3,nY]
			aAdd(aNames,cField)
		Next
	Next
Return aNames
*/
/*
Static Function GetError(oError)
	Break
Return()
*/

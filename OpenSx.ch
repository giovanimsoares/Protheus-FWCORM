#INCLUDE 'PROTHEUS.CH'

Static Function OpenSX(cSx,cAlias,aErro)

	Local lRet := .F.

	Default aErro := {}

	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf

	OpenSxs(,,,,,cAlias,cSx,,.F.)

	If Select(cAlias) > 0
		lRet := .T.
	Else
		aErro := {cSx,cAlias}
	EndIf

Return lRet

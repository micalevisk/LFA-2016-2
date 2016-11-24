#!/bin/bash
#
#	v1.24-1
#	Text2JGrammar
#	USO: ./Text2JGrammar.sh <texto especificador>
#	Parse TEXT PLAIN para JFLAP Grammar (XML)
#	Created by Micael Levi on 11/24/2016
#	Copyright (c) 2016 mllc@icomp.ufam.edu.br; All rights reserved.
#
#


## Formato:
: '
- As implicâncias (setas) são indicadas por ">"
- As regras são separadas por ";"
- O pipe (barra vertical) é indicado por ","
- O lambda é indicado por um espaço (ou simplesmente ausência de caractere)
- Caso algum terminal seja igual a alguma keyword, coloque-o entre aspas
'


shopt -s compat31
IFS_BKP="$IFS"

entrada="P > 0P,1P,1A; A > 0B; B > 1" #==> entrada="P > 0P; P>1P; P>1A; A > 0B; B > 1"

############################[ CONSTANTES ]#######################################
DELIM_REGRAS=';'
DELIM_SEQUENCIAS=','


TOP="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><!--Created with Text2JGrammar--><structure>&#13;
	<type>grammar</type>&#13;
	<!--The list of productions.-->&#13;"
DOWN="</structure>"

BODY=()
################################################################################


function join_by { local IFS="$1"; shift; echo "$*"; } #==> function join_by { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }



## Removendo nulos da entrada:
entrada=$(tr -d '[[:blank:]]' <<< ${entrada})

## Separando as regras(em um array):
IFS=$DELIM_REGRAS
read -ra regras <<< "$entrada"

## Tratando as regras:
for regra in "${regras[@]}"
do	
	IFS=$DELIM_REGRAS

	## Definindo variaveis e sequências (separa variavel e sequencia):
	regra=`sed -r "s/^(\w+?)>(.+)$/\1${DELIM_REGRAS}\2/" <<< ${regra}`
	read -ra arr_regra <<< "$regra"
	[ ${#arr_regra[@]} -ne 2 ] && exit

	## Montando linha do objeto <left> (variaveis)
	variavel="\t\t<left>${arr_regra[0]}</left>&#13;"

	## Montando linha do objeto <right> (sequencias):
	## Verificar se possui multiplas sequencias e, caso tenha separa-as num array:
	sequencias="${arr_regra[1]}"
	if [[ $sequencias =~ \\b,\\b ]]
	then	
		IFS=$DELIM_SEQUENCIAS
		## Separando as sequencias (terminais e variaveis) em um array
		read -ra arr_sequencias <<< "$sequencias"
		
		## Loop para cada sequencia relacionada a mesma variavel	
		for i in ${!arr_sequencias[@]}; do
			sequencia="${arr_sequencias[$i]}"
			sequencia="\t\t<right>${sequencia}</right>&#13;"
			arr_sequencias[$i]="\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
		done

		REGRA=`join_by $'\n' ${arr_sequencias[@]}`

	else
		sequencia="\t\t<right>${sequencias}</right>&#13;"
		REGRA="\n\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
	fi

	IFS="$IFS_BKP"
	[ "${REGRA}" ] && BODY+=(${REGRA})
done




## EXIBIR RESULTADO:
echo -e "$TOP\n${BODY[@]}\n$DOWN"
IFS="$IFS_BKP"

# (c) http://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
# (c) http://stackoverflow.com/questions/9792702/does-bash-support-word-boundary-regular-expressions
# (c) http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
# (c) http://ahmed.amayem.com/bash-arrays-2-different-methods-for-looping-through-an-array/
# (c) http://stackoverflow.com/questions/1951506/bash-add-value-to-array-without-specifying-a-key

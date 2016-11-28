#!/bin/bash
#
#	v1.28-1
#	Text2JGrammar - Parse PLAIN TEXT para JFLAP Grammar (XML)
#
#	Programas utilizados (em ordem de frequência): $ cat function-Text2JGrammar.sh | egrep -o '\w+' | sort | uniq -c |  grep -E '(echo|grep|read|sed)' | sort -hr
#	echo, read, sed, grep
#
#	USE:
#	$ Text2JGrammar "<texto formatado>" [output-file]
#
#	EX.:
#	$ Text2JGrammar "P > 0P,1P,1A; A > 0B; B > 1; B>0" mygrammar.jff
#	$ cat inputfile.txt | Text2JGrammar
#	$ echo "P > 0P; P > 1" | Text2JGrammar
#	$ Text2JGrammar < inputfile.txt
#	$ Text2JGrammar 'P > 0P,1P,1A; A > 0B; B > 1; B>0' > mygrammar.jff
#
#	Created by Micael Levi on 11/24/2016
#	Copyright (c) 2016 mllc@icomp.ufam.edu.br; All rights reserved.
#

## FIXME não identifca o arquivo de saída se a STDIN for redirecionada.
## FIXME usar get-opt para visualizar o help e definir o arquivo de saída (quando se redireciona a STDIN)
## FIXME possibilidade de definição de keywords ao chamar função específica.

## TODO adicionar cores nas mensagens informativas (upper case).
## TODO otimizar para ler da STDIN (leitura de arquivo onde delimitador de regras são as quebras de linha).
## TODO otimizar para identificar se a entrada está correta.
## TODO otimizar para formatar as regras de acordo com um tipo específico de gramática.


IFS_BKP="$IFS"

## Especificação do Formato:
: '
- Para verificar a configuração atual, execute a função "Text2JGrammar.keywords"

Por padrão:
- As implicações (setas) são indicadas por ">"
- As regras são separadas por ";"
- O pipe (barra vertical) é indicado por ","
- O lambda é indicado por "§"
- Caso algum símbolo seja igual a algum caractere especial, execute a função "Text2JGrammar.changekeywords"
'

########## [KEYWORDS] ##########
IMPLICACAO='>'
LAMBDA='§'
DELIM_REGRAS=';' # não pode ser '\'
DELIM_SEQUENCIAS=','
################################



: '
modos de leituras da STDIN
1)	echo "..." | execute	(OU cat inputfile | execute)
2)	execute < inputfile
3)	execute <<< "..."
4)	execute "..."		(OU execute -opts "...")
'
__JSkills-multiSTDIN()
{
	[[ -n "$1" ]] && echo "$*" || cat -
}



###########################[ FUNÇÕES AUXILIARES PARA O Text2JGrammar ]###########################
__Text2JGrammar-help()
{
	local DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/function-${FUNCNAME[1]}.sh"
	grep -m1 -Pzo "(?<=: '\n)[^']*(?=')" "$DIR"
}


__Text2JGrammar-cls()
{
	echo -e '\033[u'
	echo -en "\ec"
}


Text2JGrammar.changekeywords()
{
	echo -e "DEFINA AS KEYWORDS (APENAS 1 CARACTERE):\n"
	read -p "alias seta (>): " -n 1 -r IMPLICACAO; echo
	read -p "alias lambda (§): " -n 1 -r LAMBDA; echo
	read -p "alias separador de regras (;): " -n 1 -r DELIM_REGRAS; echo
	read -p "alias separador de sequências  (,): " -n 1 -r DELIM_SEQUENCIAS; echo
	__Text2JGrammar-cls
}


Text2JGrammar.keywords()
{
	echo $IMPLICACAO " (significa '->')"
	echo $LAMBDA " (lambda)"
	echo $DELIM_REGRAS " (separa as resgras)"
	echo $DELIM_SEQUENCIAS " (significa '|')"
}
#################################################################################################



#########################[ FUNÇÃO PRINCIPAL ]#########################
function Text2JGrammar
{
	[[ $# -lt 2 ]] && { __Text2JGrammar-help ; return 1; }

	local entrada="$(__JSkills-multiSTDIN "${1}")"
	local arqsaida="${2}"
	local BODY=()

	# echo "nargs   =>$#"
	# echo "entrada =>[${entrada}]"
	# echo "arqsaida=>[${arqsaida}]"

	## FIXME remover daqui e utilizar a opt -h,--help para executar o mesmo comando.
	[[ -z "$entrada" || -z "$arqsaida" ]] && { __Text2JGrammar-help ; return 2; }

	#######################################[ CONSTANTES ]#######################################
	local TOP="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><!--Created with Text2JGrammar v1.28-1--><structure>&#13;\n\t<type>grammar</type>&#13;\n\t<!--The list of productions.-->&#13;"
	local DOWN="</structure>"
	############################################################################################


	[[ -e "$arqsaida" ]] && {
		read -p "Replace existing file '${arqsaida}' (y)? " -n 1 -r
		[[ $REPLY =~ ^[Yy]$ ]] || return 2
		__Text2JGrammar-cls
	}


	## Removendo brancos da entrada:
	entrada=${entrada//[[:blank:]]/}

	## Separando as regras(em um array):
	IFS=$DELIM_REGRAS
	read -ra regras <<< "$entrada"

	PREVIEW="";

	## Tratando as regras:
	for regra in "${regras[@]}"
	do
		IFS=$DELIM_REGRAS

		## Definindo variaveis e sequências (separa variavel e sequencia):
		regra=$(sed -r "s/^(.+?)${IMPLICACAO}(.+)$/\1${DELIM_REGRAS}\2/" <<< ${regra})
		read -ra arr_regra <<< "$regra"
		[ ${#arr_regra[@]} -ne 2 ] && return

		## Montando linha do objeto <left> (variaveis):
		variavel_txt="${arr_regra[0]}"
		variavel="\t\t<left>${variavel_txt}</left>&#13;"

		## Montando linha do objeto <right> (forma sentencial):
		## Verificar se possui multiplas sequencias e, caso tenha separa-as num array:
		formaSentencial_txt="${arr_regra[1]}"
		if [[ $formaSentencial_txt =~ ${DELIM_SEQUENCIAS} ]]
		then
			IFS=$DELIM_SEQUENCIAS
			REGRA=""
			## Separando as formas sentenciais (terminais e variaveis) em um array
			read -ra arr_sequencias <<< "$formaSentencial_txt"

			## Loop para cada sequencia relacionada a mesma variavel
			for i in ${!arr_sequencias[@]}; do
				sequencia_txt="${arr_sequencias[$i]}"
				[[ $sequencia_txt =~ $LAMBDA ]] && sequencia="\t\t<right/>&#13;" || sequencia="\t\t<right>${sequencia_txt}</right>&#13;"
				arr_sequencias[$i]="\n\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
				REGRA+="${arr_sequencias[$i]}"

				PREVIEW+="${variavel_txt} --> ${sequencia_txt}\n"
			done
		else
			sequencia="\t\t<right>${formaSentencial_txt}</right>&#13;"
			REGRA="\n\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"

			PREVIEW+="${variavel_txt} --> ${formaSentencial_txt}\n"
		fi


		IFS="$IFS_BKP"
		[[ -n "${REGRA}" ]] && BODY+=(${REGRA})
	done




	## EXIBIR RESULTADO:
	[[ -z "${PREVIEW}" ]] && { __Text2JGrammar-help ; return 3; }
	echo -e "COMO FICOU:"
	echo -e "==========="
	echo -e "${PREVIEW}"
	read -p "Está correto? (y)? " -n 1 -r
	[[ $REPLY =~ ^[Yy]$ ]] || return 4
	echo -e "\nGRAMÁTICA GERADA COM SUCESSO!"

	RESULTADO="$TOP\n${BODY[@]}\n$DOWN"
	echo -e  "${RESULTADO}" | sed '4d' > ${arqsaida}	# echo -e  "${RESULTADO}"  | tee ${arqsaida}


}



# (c) http://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
# (c) http://stackoverflow.com/questions/9792702/does-bash-support-word-boundary-regular-expressions
# (c) http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
# (c) http://ahmed.amayem.com/bash-arrays-2-different-methods-for-looping-through-an-array/
# (c) http://stackoverflow.com/questions/1951506/bash-add-value-to-array-without-specifying-a-key

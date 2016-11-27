#!/bin/bash
#
#	v1.27-1
#	Text2JGrammar - Parse PLAIN TEXT para JFLAP Grammar (XML)
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

## TODO otimizar para ler da STDIN (leitura de arquivo onde delimitador de regras são as quebras de linha).
## TODO otimizar para identificar se a entrada está correta.
## TODO otimizar para formatar as regras de acordo com um tipo específico de gramática.

# shopt -s compat31
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
__JSkills-multiSTDIN(){
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

	local entrada="$(__JSkills-multiSTDIN "${1}")"
	local arqsaida="${2}"
	local BODY=()

	# echo "nargs   =>$#"
	# echo "entrada =>[${entrada}]"
	# echo "arqsaida=>[${arqsaida}]"

	## FIXME remover daqui e utilizar a opt -h,--help para executar o mesmo comando.
	[[ -z "$entrada" ]] && { __Text2JGrammar-help ; return 1; }

	#######################################[ CONSTANTES ]#######################################
	local TOP="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?><!--Created with Text2JGrammar v1.27-1--><structure>&#13;\n\t<type>grammar</type>&#13;\n\t<!--The list of productions.-->&#13;\e[1A"
	local DOWN="</structure>"
	############################################################################################


	[[ -e "$arqsaida" ]] && {
		read -p "Replace '${arqsaida}' (y)? " -n 1 -r
		[[ $REPLY =~ ^[Yy]$ ]] || return 2
		__Text2JGrammar-cls
	}


	## Removendo brancos da entrada:
	entrada=$(tr -d '[[:blank:]]' <<< ${entrada})

	## Separando as regras(em um array):
	IFS=$DELIM_REGRAS
	read -ra regras <<< "$entrada"

	## Tratando as regras:
	for regra in "${regras[@]}"
	do
		IFS=$DELIM_REGRAS

		## Definindo variaveis e sequências (separa variavel e sequencia):
		regra=$(sed -r "s/^(.+?)${IMPLICACAO}(.+)$/\1${DELIM_REGRAS}\2/" <<< ${regra})
		read -ra arr_regra <<< "$regra"
		[ ${#arr_regra[@]} -ne 2 ] && return

		## Montando linha do objeto <left> (variaveis)
		variavel="\t\t<left>${arr_regra[0]}</left>&#13;"

		## Montando linha do objeto <right> (forma sentencial):
		## Verificar se possui multiplas sequencias e, caso tenha separa-as num array:
		forma_sentencial="${arr_regra[1]}"
		if [[ $forma_sentencial =~ ${DELIM_SEQUENCIAS} ]]
		then
			IFS=$DELIM_SEQUENCIAS
			REGRA=""
			## Separando as formas sentenciais (terminais e variaveis) em um array
			read -ra arr_sequencias <<< "$forma_sentencial"

			## Loop para cada sequencia relacionada a mesma variavel
			for i in ${!arr_sequencias[@]}; do
				sequencia="${arr_sequencias[$i]}"
				[[ $sequencia =~ $LAMBDA ]] && sequencia="\t\t<right/>&#13;" || sequencia="\t\t<right>${sequencia}</right>&#13;"
				arr_sequencias[$i]="\n\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
				REGRA+="${arr_sequencias[$i]}"
			done
		else
			sequencia="\t\t<right>${forma_sentencial}</right>&#13;"
			REGRA="\n\t<production>&#13;\n${variavel}\n${sequencia}\n\t</production>&#13;"
		fi

		IFS="$IFS_BKP"
		[[ -n "${REGRA}" ]] && BODY+=(${REGRA})
	done


	## EXIBIR RESULTADO:
	RESULTADO="$TOP\n${BODY[@]}\n$DOWN"
	echo -e  "${RESULTADO}"  | tee ${arqsaida}

	IFS="$IFS_BKP"
}



# (c) http://stackoverflow.com/questions/918886/how-do-i-split-a-string-on-a-delimiter-in-bash
# (c) http://stackoverflow.com/questions/9792702/does-bash-support-word-boundary-regular-expressions
# (c) http://stackoverflow.com/questions/1527049/bash-join-elements-of-an-array
# (c) http://ahmed.amayem.com/bash-arrays-2-different-methods-for-looping-through-an-array/
# (c) http://stackoverflow.com/questions/1951506/bash-add-value-to-array-without-specifying-a-key

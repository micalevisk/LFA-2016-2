#!/bin/bash

## bashrc="$HOME/.bashrc"
bashrc="/etc/bash.bashrc"
SKILLS_JFLAP_PATH='/cygdrive/c/Users/user/Documents/GitHub/LFA_feelings'


if ! grep -n --color -m1 "^[^#]*${SKILLS_JFLAP_PATH}" "$bashrc" #>/dev/null 2>&1
then
	cat - >> "$bashrc" <<-EOS


	## Instalação das funções extras para o JFlap (https://github.com/micalevisk/LFA_feelings)
	export LFA_GITHUB="${SKILLS_JFLAP_PATH}"
	source "\${LFA_GITHUB}/function-Text2JGrammar.sh"
	EOS

	echo 'Feito!'
	echo "As skills pro JFLAP foram instaladas no $bashrc"
else
	echo "Nada a fazer. Você já possui as habilidades extras no $bashrc"
fi

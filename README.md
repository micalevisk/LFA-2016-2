# Text2JGrammar

### to download and change permission (_bash_):
```bash
wget "https://raw.githubusercontent.com/micalevisk/LFA_feelings/master/Text2JGrammar.sh" &&
chmod +x "Text2JGrammar.sh"
```

### Input Syntax:
- As implicações (setas) são indicadas por **>**
- As regras são separadas por **;**
- O pipe (barra vertical) é indicado por **,**
- O lambda é indicado por **§**
- Caso algum símbolo seja igual a algum caractere especial, altere a _keyword_ no arquivo.

### To Use (on terminal)
```bash
./Text2JGrammar.sh "P > 0P,1P,1A; A > 0B; B > 1; B>0" mygrammar.jff
```

### e.g.:
_this input plain text:_ ```P > 0P,1P,1A; A > 0B; B > 1```

_means:_ ![http://image.prntscr.com/image/a261182c347a4c7daa7694029105d5af.png](http://image.prntscr.com/image/a261182c347a4c7daa7694029105d5af.png)
_on JFLAP_

### Preview
[![asciicast](https://asciinema.org/a/94028.png)](https://asciinema.org/a/94028)

-----------------

# CompiladorCalculadoraC3A

## Aprenentatges
- Taula de símbols
- Anàlisi lèxic, sintàctic, semàntic
- Atributs i comprovació de tipus
- Utilització conjunta de Flex, Bison i Symtab
- Generació de Codi de tres adreces (C3A)

## Compilació
1. Clona el repositori:
   ```bash
   git clone https://github.com/PolPujolSantaella/CompiladorCalculadoraC3A.git
   cd CompiladorCalculadora
   ```

2. Compila el projecte
   ```bash
   make all
   ```

## Execució
Per provar el joc de proves que he realitzat només cal fer un:
   ```bash
   make eg
   ```
Aquest et genera un arxiu ex_sortida.out que conté la sortida corresponent.

## Per netejar-ho tot menys arxius fonts
   ```bash
   make clean
   ```
# Descripció del Projecte
Aquest projecte consisteix en un compilador bàsic que processa un llenguatge sencill i genera codi intermig en format de tres direccions (C3A). Aquest compilador ha sigut dissenyat per gestionar expressions aritmètiques, sentencies iteratives, procediments predefinits, y la utilització de taules unidimensionals.

El objectiu es proporcionar un entendiment pràctic de la construcció de compiladors, desde el anàlis lèxic i sintàctic fins la generació de codi intemig.

## Decissions de disseny

Apart de totes les decissions de disseny de la pràctica anterior:

- Generació de Codi Intemig: He implementat funcions auxiliars com generate_temp per gestionar variables temporals i gen_c3a per simplificar la escriptura del codi intermig.

## Limitacions

- Taules unidimensional: Actualment, no s'ha implementat el suport per taules unidimensionals. Això inclou la seva declaració, accés mitjançant índexs i assignacions desplazades. Una possible millora sería implementar el càlcul de desplaçaments en memòria i generar el codi intermig corresponent.



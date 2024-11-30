%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "calculadora.tab.h" 

#define TEMP_PREFIX "$t"
#define SENTENCE_MAX_LENGTH 256

extern FILE *yyout;
extern int yylineno;
extern int yylex();
/*extern void yyerror(char*);*/

char *instructions[100];
int line_comp = 1;
int temp_comp = 1;

char *temp_line;


void printSentencies();
void gen_c3a(int args_count, ...);
void freeSentencies(); 
char* generate_temp();
void genC3A_aritmetica(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* operador);
void genC3A_salt_cond(sym_value_type s1, const char *operador, sym_value_type s2, char *jump);


%}

%code requires {
	#include "calculadora_funcions.h"
	#include "symtab.h"
}

%union{

	struct{
		char *lexema;
		sym_value_type value;
	} id;
	
	sym_value_type expr;
	char *cadena;
}

%token <id> ID ID_ARITM 
%token <cadena> INTEGER FLOAT
%token ASSIGN SUMA RESTA MULT DIV MOD POT 
%token REPEAT DO DONE
%token FI_SENT ABRIR_PAR CERRAR_PAR

%type <id> id
%type <expr> expresion expresion_aritmetica expre_prec1_arit expre_prec2_arit expre_base_arit
%type <expr> ini_bucle

%%

programa : llista_sentencias { 
				printSentencies();
				freeSentencies();
			} 
;

llista_sentencias: llista_sentencias sentencia 
				| sentencia
; 

sentencia: simple | iterativa;

simple: FI_SENT
		| assignacio FI_SENT
		| procediments FI_SENT
;

assignacio: id ASSIGN expresion {
				$1.value = $3;
				sym_enter($1.lexema, &$1.value);
				gen_c3a(3, $1.lexema, ":=", $3.lloc);
			}
;
			
id: ID | ID_ARITM;

expresion: expresion_aritmetica; 

expresion_aritmetica: expre_prec1_arit
				| expresion_aritmetica SUMA expre_prec1_arit{ genC3A_aritmetica(&$$, $1, $3, "ADD");  }
				| expresion_aritmetica RESTA expre_prec1_arit { genC3A_aritmetica(&$$, $1, $3, "SUB");  }
				| SUMA expre_prec1_arit { $$ = $2;  }
				| RESTA expre_prec1_arit {
					$$.lloc = generate_temp();
					$$.tipus = $2.tipus;
					if ($2.tipus == ENTERO) gen_c3a(4, $$.lloc, ":=" "CHSI", $2.lloc);
					else gen_c3a(4, $$.lloc, ":=", "CHSF", $2.lloc);
				}
;

expre_prec1_arit: expre_prec2_arit
				| expre_prec1_arit MULT expre_prec2_arit { genC3A_aritmetica(&$$, $1, $3, "MUL"); }
				| expre_prec1_arit DIV expre_prec2_arit { 
					if (($3.tipus == ENTERO && atoi($3.lloc) == 0) || ($3.tipus == REAL && atof($3.lloc) == 0)){
						yyerror("No es pot dividir entre 0");
					}
					else {
						genC3A_aritmetica(&$$, $1, $3, "DIV");
					}
				}
				| expre_prec1_arit MOD expre_prec2_arit {
					if ($1.tipus == ENTERO && $3.tipus == ENTERO){
						genC3A_aritmetica(&$$, $1, $3, "MOD");
					}
					else yyerror("Nomes es fa modul entre enters");
				}
;

expre_prec2_arit: expre_base_arit
				| expre_prec2_arit POT expre_base_arit {
					if ($3.tipus == ENTERO){
						int exp = atoi($3.lloc);
						sym_value_type temp, result;
						temp.lloc = (char *)malloc(sizeof(char)*strlen($1.lloc)+2);
						strcpy(temp.lloc, $1.lloc);
						temp.tipus = $1.tipus;
						for (int i=0; i<exp; i++){
							result.lloc = generate_temp();
							genC3A_aritmetica(&result, $1, temp, "MUL");
							strcpy(temp.lloc, result.lloc);
						}
						$$ = result;
					} 
					else yyerror("Operacio no permesa");
				}
;

expre_base_arit: ABRIR_PAR expresion_aritmetica CERRAR_PAR { $$ = $2; }
				| INTEGER { $$.tipus = ENTERO; $$.lloc = $1; };
				| FLOAT { $$.tipus = REAL; $$.lloc = $1; }
				| ID_ARITM { 
					if (sym_lookup($1.lexema, &$1.value) != SYMTAB_OK) {
						fprintf(stderr, "Error semàntic en la línea %d: Variable '%s' no definida. \n", yylineno, $1.lexema);
					}
					$$.tipus = $1.value.tipus;
					$$.lloc = $1.lexema;
				}
;

iterativa: REPEAT expresion_aritmetica ini_bucle DO llista_sentencias DONE {
			if ($3.tipus == ENTERO) gen_c3a(5, $3.lloc, ":=", $3.lloc, "ADDI", "1");
			else if ($3.tipus == REAL) gen_c3a(5, $3.lloc, ":=", $3.lloc, "ADDF", "1");
			else yyerror("Bad request");
			genC3A_salt_cond($3, "LT", $2, temp_line); 
		}
;

ini_bucle: {
				$$.lloc = malloc(sizeof(char)*5);
				$$.tipus = ENTERO;
				strcpy($$.lloc, generate_temp());
				gen_c3a(3, $$.lloc, ":=", "0");
				temp_line = malloc(sizeof(char)*5);
				sprintf(temp_line, "%d", line_comp);
			}
;

procediments: put;

put: ID_ARITM{
		sym_lookup($1.lexema, &$1.value);
		gen_c3a(2, "PARAM", $1.lexema);
		char *op = malloc(sizeof(char)*5);
		strcpy(op, "PUT");
		if ($1.value.tipus == ENTERO) strcat(op, "I,");
		else if ($1.value.tipus==REAL) strcat(op, "F,");
		gen_c3a(3, "CALL", op, "1");
	}
;


%%

void printSentencies(){
	for (int i=1; i < line_comp; i++){
		fprintf(yyout, "%d: %s\n", i, instructions[i]);
	}
	fprintf(yyout, "%d: HALT\n", line_comp);
}

void gen_c3a(int args_count, ...){
	va_list args;
	va_start(args, args_count);
	
	size_t total_length = 1;
	va_list temp_args; 
	va_copy(temp_args, args);
	
	for(int i=0; i < args_count; i++){
		total_length += strlen(va_arg(temp_args, char*)) + 1;
	}
	va_end(temp_args);
	
	char *buffer = malloc(total_length * sizeof(char));
	if (!buffer) {
		fprintf(stderr, "Error: no s'ha assignat memoria per la instrucció\n");
		exit(1);
	}
	buffer[0] = '\0';
	
	for (int i=0; i < args_count; i++) {
		strcat(buffer, va_arg(args, char*));
		strcat(buffer, " ");
	}
	va_end(args);
	
	instructions[line_comp++] = buffer;
}

void freeSentencies() {
	for (int i=0; i < line_comp; i++) {
		free(instructions[i]);
	}
}

char *generate_temp() {
	char *buffer = (char *) malloc(sizeof(char)*3+sizeof(int));
	sprintf(buffer, "%s0%d", TEMP_PREFIX, temp_comp++);
	return buffer;
}

void genC3A_aritmetica(sym_value_type *s0, sym_value_type s1, sym_value_type s2, const char* operador){
	char *o_integer = (char *)malloc(sizeof(char)*strlen(operador)+2);
	char *o_float = (char *)malloc(sizeof(char)*strlen(operador)+2);
	
	strcpy(o_integer, operador);
	strcpy(o_float, operador);
	strcat(o_integer, "I");
	strcat(o_float, "F");
	
	if (s1.tipus == s2.tipus) {
		s0->lloc=generate_temp();
		s0->tipus = s1.tipus;
		char *op = s1.tipus == ENTERO ? o_integer : o_float;
		gen_c3a(5, s0->lloc, ":=", s1.lloc, op, s2.lloc);
	}
	else if (s1.tipus == REAL || s2.tipus == REAL) {
		s0->tipus = REAL;
		if (s1.tipus == REAL) {
			char *castedValue = generate_temp();
			gen_c3a(4, castedValue, ":=", "I2F", s2.lloc);
			s0->lloc=generate_temp();
			gen_c3a(5, s0->lloc, ":=", s1.lloc, o_float, castedValue);
		}
		else if (s2.tipus == REAL) {
			char *castedValue = generate_temp();
			gen_c3a(4, castedValue, ":=", "I2F", s1.lloc);
			s0->lloc = generate_temp();
			gen_c3a(5, s0->lloc, ":=", castedValue, o_float, s2.lloc);
		}
		else yyerror("Operacio no permesa");
	}
	else yyerror("Operacio no permesa");
	free(o_float);
	free(o_integer);
}

void genC3A_salt_cond(sym_value_type s1, const char *oprel, sym_value_type s2, char *jump){
	if (s1.tipus == s2.tipus){
		char *op = (char *)malloc(sizeof(char)*strlen(oprel)+2);
		strcpy(op, oprel);
		if (s1.tipus == ENTERO) strcat(op, "I");
		else strcat(op, "F");
		gen_c3a(6, "IF", s1.lloc, op, s2.lloc, "GOTO", jump);
		free(op);
	}
	else yyerror("Tenen que ser del mateix tipus");
}
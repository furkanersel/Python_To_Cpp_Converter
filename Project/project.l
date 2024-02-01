digit	[0-9]
letter	[A-Za-z]

%{
  #include <stdio.h>
  #include <string.h>
  #include "y.tab.h"
  #include <iostream>
  using namespace std;
  int linenum = 1;
  int tabCounter = 0;
%}

%%

"if" {yylval.str = strdup(yytext); return IF;}
"elif" {yylval.str = strdup("else if"); return ELIF;}
"else" {yylval.str = strdup(yytext); return ELSE;}
[+-]?{digit}+ {yylval.str = strdup(yytext); return INTEGER;}
[+-]?{digit}*(\.)?{digit}+ {yylval.str = strdup(yytext); return FLOAT;}
\"(\\.|[^"\\])*\" {yylval.str = strdup(yytext); return STRING;} 
{letter}({letter}|{digit})*	{yylval.str = strdup(yytext); return IDENTIFIER;}
"+" {yylval.str = strdup(yytext); return PLUSOP;}
"-" {yylval.str = strdup(yytext); return MINUSOP;}
"/" {yylval.str = strdup(yytext); return MULTOP;}
"*" {yylval.str = strdup(yytext); return DIVOP;}
"=="|"!="|"<"|"<="|">"|">="	{yylval.str = strdup(yytext); return COMPARISON;}
":" return DP;
"=" {yylval.str = strdup(yytext); return ASSIGNOP;}
\n {linenum++; return NEWLINE;}
\t {tabCounter++; return TAB;}

%%
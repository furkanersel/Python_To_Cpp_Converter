%{
#include <stdio.h>
#include <iostream>
#include <string>
#include <set>
#include <cstring>
using namespace std;
#include "y.tab.h"

#define MAX 100

extern FILE *yyin;
extern int yylex();

void yyerror(string s);

extern int linenum;
extern int tabCounter;
int currentTab = 0;
string output = "";

string types[MAX];
bool typesClosed[MAX];
int typesTabCount[MAX];
int typeIndex = 0;

string variables[MAX];
string variableTypes[MAX];
int variableIndex = 0;

string typeCheck[MAX];
int typeCheckIndex = 0;

void scopeIsEmpty(){
    if(typeIndex > 0){
        string currentType = types[typeIndex - 1];

        if((currentType == "if" || currentType == "elif" || currentType == "else") &&
            !(typesTabCount[typeIndex - 1] == tabCounter - 1) && !typesClosed[typeIndex - 1]){
            cout << "There is a tab inconsistency in line " << linenum << endl;
            exit(0);
        }
    }
}

void checkTypeConsistency(string typeCheck[], int typeCheckIndex, int linenum, string &check) {
    bool flag = true;

    if (typeCheckIndex > 0) {
        check = typeCheck[0];

        for (int i = 1; i < typeCheckIndex; i++) {
            if (typeCheck[i] != check) {
                if ((check == "flt" && typeCheck[i] == "int") || (check == "int" && typeCheck[i] == "flt")) {
                    check = "flt";
                    
                } else {
                    flag = false;
					break;
                }
            }
        }
    }

    if (!flag) {
        cout << "Type inconsistency in line " << linenum << endl;
        exit(0);
    }
}

string handleClosingBraces(int tabCounter){
    string closingBraces = "";
	
    for(int i = typeIndex - 1; i >= 0; i--){
        if (typesTabCount[i] >= tabCounter && !typesClosed[i]){
            for (int j = typesTabCount[i]; j > 0; j--){
                closingBraces += "\t";
            }
            closingBraces += "}\n";
            typesClosed[i] = true;
        }
    }
    return closingBraces;
}

string handleIfStatement(int tabCounter){
    scopeIsEmpty();

    string closingBraces = handleClosingBraces(tabCounter);

    typesTabCount[typeIndex] = tabCounter;
    types[typeIndex] = "if";
    typesClosed[typeIndex] = false;
    typeIndex++;

    return closingBraces;
}

string handleElseIfStatement(int tabCounter){
    scopeIsEmpty();

    bool flag = false;
    for (int i = typeIndex - 1; i >= 0; i--){
        if(typesTabCount[i] == tabCounter && (types[i] == "if" || types[i] == "elif") && !typesClosed[i]){
            flag = true;
        }
    }

    if (!flag) {
        cout << "If/else inconsistency in line " << linenum << endl;
        exit(0);
    }

    string closingBraces = handleClosingBraces(tabCounter);

    typesTabCount[typeIndex] = tabCounter;
    types[typeIndex] = "elif";
    typesClosed[typeIndex] = false;
    typeIndex++;

    return closingBraces;
}

string handleElseStatement(int tabCounter){
    scopeIsEmpty();

    bool flag = false;
    for (int i = typeIndex - 1; i >= 0; i--) {
        if (typesTabCount[i] == tabCounter && (types[i] == "if" || types[i] == "elif") && !typesClosed[i]){
            flag = true;
        }
    }

    if (!flag){
        cout << "If/else inconsistency in line " << linenum << endl;
        exit(0);
    }

    string closingBraces = handleClosingBraces(tabCounter);

    typesTabCount[typeIndex] = tabCounter;
    types[typeIndex] = "else";
    typesClosed[typeIndex] = false;
    typeIndex++;

    return closingBraces;
}

string addTabs(int tabs){
    string tabsString;
    for (int i = 0; i < tabs; i++){
        tabsString += '\t';
    }
    return tabsString;
}

string createIfStatement(const string &expr1, const string &comp, const string &expr2, int tabCounter){
	string combined = "if( " + expr1 + " " + comp + " " + expr2 + " )\n";
    combined += addTabs(tabCounter) + "{" + "\n";
    return combined;
}

string createElseIfStatement(const string &expr1, const string &comp, const string &expr2, int tabCounter){
    string combined = "else if( " + expr1 + " " + comp + " " + expr2 + " )\n";
    combined += addTabs(tabCounter) + "{" + "\n";
    return combined;
}

string createElseStatement(int tabCounter){
    string combined = "else\n";
    combined += addTabs(tabCounter) + "{" + "\n";
    return combined;
}

string addTabToString(const string &str){
    return "\t" + str;
}

void printVariables(){
    set<string> seenVariables; // To not allow duplicated print variable
    string typeArrays[3];

    for(int i = 0; i < variableIndex; i++){
        string combined = variables[i] + "_" + variableTypes[i];

        if(seenVariables.find(variables[i]) == seenVariables.end()){
            seenVariables.insert(variables[i]);
            if (variableTypes[i] == "int") typeArrays[0] += combined + ",";
            else if (variableTypes[i] == "flt") typeArrays[1] += combined + ",";
            else if (variableTypes[i] == "str") typeArrays[2] += combined + ",";
        }
    }

    const string typeNames[] = { "int", "float", "string" };
    for(int i = 0; i < 3; i++){
        if(!typeArrays[i].empty()) {
            cout << typeNames[i] << " " << typeArrays[i].substr(0, typeArrays[i].size() - 1) << ";\n\t";
        }
    }
    cout << endl << "\t";
}

void printOutput(const string &output){
    char prevChar = '\0';
    for (char s : output){
        cout << s;
        if (s == '\n') cout << "\t";
        prevChar = s;
    }

    cout << endl;
    cout << "}" << endl; // close void main()
}

%}

%union {
    char *str;
}

%token <str> IF ELIF ELSE IDENTIFIER STRING COMPARISON DP ASSIGNOP NEWLINE TAB INTEGER FLOAT PLUSOP MINUSOP MULTOP DIVOP
%type <str> assignment expression if_statement else_if_statement else_statement statement conditions 
%left PLUSOP MINUSOP 
%left MULTOP DIVOP 
%right COMPARISON
%%

program:
    statements 
    {
        cout << "void main()\n{\n\t";
        printVariables();
        printOutput(output);
    };

statements:
    statement statements
    |
    statement
    ;

statement:
    assignment
    {
        if(currentTab < tabCounter)
        {
            cout << "There is a tab inconsistency in line "<< (linenum) << endl;
            exit(0);
        }
        scopeIsEmpty();

        string combined = handleClosingBraces(tabCounter);
        combined += string($1) + "\n";

		types[typeIndex] = "assignment";
        typesTabCount[typeIndex] = tabCounter;
        typesClosed[typeIndex] = true;
        typeIndex++;

        $$ = strdup(combined.c_str());
        output.append($$);
        tabCounter = 0;
    }
    |
    conditions
    {
        currentTab = tabCounter + 1;
		tabCounter = 0;
    }
    |
    NEWLINE
    ;

assignment:
    IDENTIFIER ASSIGNOP assignment
    {
        string check;
        checkTypeConsistency(typeCheck, typeCheckIndex, linenum, check);

        variables[variableIndex] = string($1);
        variableTypes[variableIndex] = check;
        variableIndex++;
     
        string combined = string($1) + "_" + check + " " + string($2) + " " + string($3) + ";";
        $$ = strdup(combined.c_str());
    }
    |
    TAB assignment
    {
        string combined = string("\t") + string($2);
        $$ = strdup(combined.c_str());
    }
    |
    expression
    ;
	
conditions:
    if_statement
	{
		string combined = handleIfStatement(tabCounter);
		combined += $1;
		$$ = strdup(combined.c_str());
		output.append($$);
	}
    | 
	else_if_statement
	{
		string combined = handleElseIfStatement(tabCounter);
		combined += $1;
		$$ = strdup(combined.c_str());
		output.append($$);
	}
    | 
    else_statement
	{
		string combined = handleElseStatement(tabCounter);
		combined += $1;
		$$ = strdup(combined.c_str());
		output.append($$);	
	}
    ;

if_statement:
    IF expression COMPARISON expression DP 
    {
        string combined = createIfStatement($2, $3, $4, tabCounter);
        $$ = strdup(combined.c_str());
        typeCheckIndex = 0; 
    }
    | 
	TAB if_statement 
    {
        string combined = addTabToString($2);
		$$ = strdup(combined.c_str());
    }
    ;

else_if_statement:
    ELIF expression COMPARISON expression DP 
    {
        string combined = createElseIfStatement($2, $3, $4, tabCounter);
        $$ = strdup(combined.c_str());
        typeCheckIndex = 0; 
    }
    | 
	TAB else_if_statement 
    {
        string combined = addTabToString($2);
		$$ = strdup(combined.c_str());
    }
    ;

else_statement:
    ELSE DP 
    {
        string combined = createElseStatement(tabCounter);
        $$ = strdup(combined.c_str());
    }
    | 
    TAB else_statement 
    {
        string combined = addTabToString($2);
	    $$ = strdup(combined.c_str());
    }
    ;

expression:
    expression MULTOP expression
    {
        string combined = string($1) + " " + string($2) + " " + string($3);
        $$ = strdup(combined.c_str());
    }
    |
    expression DIVOP expression
    {
        string combined = string($1) + " " + string($2) + " " + string($3);
        $$ = strdup(combined.c_str());
    }
    |
    expression PLUSOP expression
    {
        string combined = string($1) + " " + string($2) + " " + string($3);
        $$ = strdup(combined.c_str());
    }
    |
    expression MINUSOP expression
    {
        string combined = string($1) + " " + string($2) + " " + string($3);
        $$ = strdup(combined.c_str());
    }
    |
	IDENTIFIER
	{
		string combined = string($1);

		for(int i = 0; i < variableIndex; i++){
			if(variables[i] == $1) {
				typeCheck[typeCheckIndex++] = variableTypes[i];
				combined += "_" + variableTypes[i];
				break;
			}
		}
		$$ = strdup(combined.c_str());
	}    
	|
    INTEGER
    {
        $$ = strdup($1);
        typeCheck[typeCheckIndex++] = "int";
    }
    |
    FLOAT
    {
        $$ = strdup($1);
        typeCheck[typeCheckIndex++] = "flt";
    }
    |
    STRING
    {
        $$ = strdup($1);
        typeCheck[typeCheckIndex++] = "str";
    }
    ;
%%

void yyerror(string s) {
    cout << "Error: " << s << endl;
}

int yywrap() {
    return 1;
}

int main(int argc, char *argv[]) {
    /* Call the lexer, then quit. */
    yyin = fopen(argv[1], "r");
    yyparse();
    fclose(yyin);
    return 0;
}
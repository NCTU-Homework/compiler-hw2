%{
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

extern int32_t line_num;  /* declared in scanner.l */
extern char buffer[512];  /* declared in scanner.l */
extern FILE *yyin;        /* declared by lex */
extern char *yytext;      /* declared by lex */

extern int yylex(void); 
static void yyerror(const char *msg);
%}

%token COMMA SEMI COLON L_BRACKET R_BRACKET L_SQBRACKET R_SQBRACKET LT LE NE GE GT EQ AND OR NOT ARRAY BEGINNING BOOL DEF DO ELSE ENDING FALSE FOR INT IF OF PRINT READ REAL STRING THEN TO TRUE RETURN VAR WHILE IDENTIFIER DEC_CONST OCT_CONST FLOAT_CONST SCIENTIFIC_CONST STRING_CONST
%start program
%right ASSIGN
%left LE LT EQ NE GE GT 
%left PLUS MINUS
%left STAR DIV MOD
%left AND OR NOT
%%

program:   IDENTIFIER SEMI var_const_decl_list func_decl_def_list compound ENDING;

func_decl: task_decl | procedure_decl;
func_def:  task_def | procedure_def;
task_decl: IDENTIFIER L_BRACKET arg_list R_BRACKET COLON scalar_type SEMI;
task_def:  IDENTIFIER L_BRACKET arg_list R_BRACKET COLON scalar_type compound ENDING;
procedure_decl: IDENTIFIER L_BRACKET arg_list R_BRACKET SEMI;
procedure_def:  IDENTIFIER L_BRACKET arg_list R_BRACKET compound ENDING;

    /* (utility) */

var_decl: VAR identifier_list COLON data_type SEMI;
const_decl: VAR identifier_list COLON literal_const SEMI;
var_ref: IDENTIFIER | array_ref;
array_ref: IDENTIFIER sqbracket_list;

data_type: scalar_type | structured_type;
scalar_type: INT | REAL | STRING | BOOL;
structured_type: ARRAY int_const OF data_type;
int_const: OCT_CONST | DEC_CONST;
literal_const: STRING_CONST | DEC_CONST | OCT_CONST | FLOAT_CONST | SCIENTIFIC_CONST | TRUE | FALSE;
    
    /* lists */

func_decl_def_list:
        | func_decl_def_list func_decl
        | func_decl_def_list func_def
        ;

    /* [expr][expr]... */
sqbracket_list: 
        | sqbracket_list L_SQBRACKET expression R_SQBRACKET
        ;

    /* a : int ; b , c : string ; ... */
arg_list0: identifier_list COLON data_type
        | arg_list SEMI identifier_list COLON data_type
        ;
arg_list:
        | arg_list0
        ;

    /* identifier, identifier, ... */
identifier_list: IDENTIFIER
        | IDENTIFIER COMMA identifier_list
        ;

    /* [var_decl const_decl]+ */    
var_const_decl_list:
        | var_const_decl_list var_decl
        | var_const_decl_list const_decl
        ;

    /* statement* */
statement_list:
        | statement_list statement
        ;

    /* expression+ */
expression_list0: expression
        | expression_list COMMA expression
        ;
expression_list:
        | expression_list0
        ;

    /* statement section */
statement: compound | simple | if_statement | while_statement | for_statement | retrun_statement | procedure_call_statement;
compound: BEGINNING var_const_decl_list statement_list ENDING;
simple: var_ref ASSIGN expression SEMI
        | PRINT var_ref SEMI
        | PRINT expression SEMI
        | READ var_ref SEMI
        ;
if_statement: IF expression THEN compound ELSE compound ENDING IF
        | IF expression THEN compound ENDING IF
        ;
while_statement: WHILE expression DO compound ENDING DO;
for_statement: FOR IDENTIFIER ASSIGN int_const TO int_const DO compound ENDING DO;
retrun_statement: RETURN expression SEMI;
procedure_call_statement: function_call SEMI;

    /* expression section */
expression: literal_const | var_ref | unary_operation | logic_operation | multiplication | division | mod_operation | addition | subtraction | relation | bracket_operation | function_call;
unary_operation: MINUS expression | NOT expression;
logic_operation: expression AND expression | expression OR expression | expression NOT expression;
multiplication: expression STAR expression;
division: expression DIV expression;
mod_operation: expression MOD expression;
addition: expression PLUS expression;
subtraction: expression MINUS expression;
relation: expression LE expression | expression LT expression | expression EQ expression | expression NE expression | expression GT expression | expression GE expression;
bracket_operation: L_BRACKET expression R_BRACKET;
function_call: IDENTIFIER L_BRACKET expression_list R_BRACKET;
%%

void yyerror(const char *msg) {
    fprintf(stderr,
            "\n"
            "|--------------------------------------------------------------------------\n"
            "| Error found in Line #%d: %s\n"
            "|\n"
            "| Unmatched token: %s\n"
            "|--------------------------------------------------------------------------\n",
            line_num, buffer, yytext);
    exit(-1);
}

int main(int argc, const char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: ./parser <filename>\n");
        exit(-1);
    }

    yyin = fopen(argv[1], "r");
    assert(yyin != NULL && "fopen() fails.");

    yyparse();

    printf("\n"
           "|--------------------------------|\n"
           "|  There is no syntactic error!  |\n"
           "|--------------------------------|\n");
    return 0;
}

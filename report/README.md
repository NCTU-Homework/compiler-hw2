# hw2 report

|      |         |
| ---: | :------ |
| Name | 曾文鼎  |
|   ID | 0716023 |

## How much time did you spend on this project

~ 8 hour.

## Project overview

### scanner.l

scanner.l 會將使用者的 source code 轉為 tokens ，然後餵給 parser.y 去做分析。因此首要步驟就是修改 scanner.l ，令所有的 token 都要回傳其 token name ，即：

```
";" { TOKEN_CHAR(';'); return SEMI; }
```

### 宣告 tokens

我們要定義所有將出現的 token ，即：

```
%token COMMA SEMI COLON ... <略>
```

並定義程式的起始點：

```
%start program
```

### 定義 main grammar

定義文法的部分，可以邊看 readme 邊做。遇到需要 helper grammar 的部分，可以先宣告個新的文法，等等 main grammar 都寫好之後再做。像是整個程式的文法可以如此表示：

```
grammar: IDENTIFIER SEMI var_const_decl_list func_decl_def_list compound ENDING;
```

當中的 `IDENTIFIER` `SEMI` `ENDING` 是已在 scanner.l 定義好的 tokens ，而 compound 則是之後才會實作的 main grammar 。至於 `var_const_decl_list` `func_decl_def_list` 則是 helper grammar 。在撰寫 `program` 的文法時，我可以將 `var_const_decl_list` `func_decl_def_list` 留到之後再寫。

接著實作像是 function call 和 function definition 等等的，照著 README 做就好。我將 function 區分為 task 和 procedure 兩種，前者有回傳值，後者則無。

```
func_decl:      task_decl | procedure_decl;
func_def:       task_def | procedure_def;
task_decl:      IDENTIFIER L_BRACKET arg_list R_BRACKET COLON scalar_type SEMI;
task_def:       IDENTIFIER L_BRACKET arg_list R_BRACKET COLON scalar_type compound ENDING;
procedure_decl: IDENTIFIER L_BRACKET arg_list R_BRACKET SEMI;
procedure_def:  IDENTIFIER L_BRACKET arg_list R_BRACKET compound ENDING;
```

變數和常數文法也很簡單。同樣， helper grammar 像是 `identifier_list` `data_type` 等以後再定義：

```
var_decl:   VAR identifier_list COLON data_type SEMI;
var_ref:    IDENTIFIER | array_ref;
const_decl: VAR identifier_list COLON literal_const SEMI;
```

Statement 可以如下定義：

```
statement: compound | simple | if_statement | while_statement | for_statement | retrun_statement | procedure_call_statement;
```

然後定義 sub grammar：

```
compound: BEGINNING var_const_decl_list statement_list ENDING;
simple:   var_ref ASSIGN expression SEMI
          | PRINT var_ref SEMI
          | PRINT expression SEMI
          | READ var_ref SEMI
          ;
if_statement: IF expression THEN compound ELSE compound ENDING IF
            | IF expression THEN compound ENDING IF
            ;
while_statement:          WHILE expression DO compound ENDING DO;
for_statement:            FOR IDENTIFIER ASSIGN int_const TO int_const DO compound ENDING DO;
retrun_statement:         RETURN expression SEMI;
procedure_call_statement: function_call SEMI;
```

### 定義 expression

顯然， expression 可以是一個常數或變數的 reference。此外還需要實作各種操作：

```
expression: literal_const
          | var_ref
          | L_BRACKET expression R_BRACKET
          | unary_operation
          | logic_operation
          | multiplication
          | division
          | mod_operation
          | addition
          | subtraction
          | relation
          | function_call
          ;
```

諸如加法或邏輯運算等 operation 之操作極度簡單。以下僅示範加法：

```
addition: expression PLUS expression
```

### 定義 helper grammar

在最廣泛使用的輔助文法當中，最經典的兩個莫過於：

1. a list that contains at least one element
2. a list that contains zero or more element

對於第一種 list ，例如 `identifier_list` ，可以如此定義：

```
identifier_list: IDENTIFIER | IDENTIFIER COMMA identifier_list;
```

對於第二種 list ，例如 `expression_list` ，在不考慮逗號隔開的情況下，可以這樣定義：

```
expression_list: expression | expression_list expression;
```

若要考慮實現隔開的文法，只要額外使用一個 helper grammar 即可。

```
expression_list0: expression | expression_list COMMA expression;
expression_list: | expression_list0;
```

## What is the hardest you think in this project

我覺得解決 ambigious 有些困難。

例如這樣的 conflict：

```
State 155

   83 logic_operation: expression . AND expression
   84                | expression . OR expression
   85                | expression . NOT expression
   86 multiplication: expression . STAR expression
   87 division: expression . DIV expression
   87         | expression DIV expression .
   88 mod_operation: expression . MOD expression
   89 addition: expression . PLUS expression
   90 subtraction: expression . MINUS expression
   91 relation: expression . LE expression
   92         | expression . LT expression
   93         | expression . EQ expression
   94         | expression . NE expression
   95         | expression . GT expression
   96         | expression . GE expression

    LT   shift, and go to state 112
    LE   shift, and go to state 113
    NE   shift, and go to state 114
    GE   shift, and go to state 115
    GT   shift, and go to state 116
    EQ   shift, and go to state 117
    AND  shift, and go to state 118
    OR   shift, and go to state 119
    NOT  shift, and go to state 120

    LT        [reduce using rule 87 (division)]
    LE        [reduce using rule 87 (division)]
    NE        [reduce using rule 87 (division)]
    GE        [reduce using rule 87 (division)]
    GT        [reduce using rule 87 (division)]
    EQ        [reduce using rule 87 (division)]
    AND       [reduce using rule 87 (division)]
    OR        [reduce using rule 87 (division)]
    NOT       [reduce using rule 87 (division)]
    $default  reduce using rule 87 (division)
```

後來才知道這跟優先權有一些關係。在二元操作中，顯然最優先的應該是邏輯運算子 `AND` `OR` `NOT` ，其次是乘法、除法與求餘。再其次是加法和減法。最後是邏輯運算子 `<` `>` `<>` 等等。所以實作優先順序就好了。

```
%left LE LT EQ NE GE GT
%left PLUS MINUS
%left STAR DIV MOD
%left AND OR NOT
```

不過還是有一些 ambigious 比較難搞。雖然我完全看得懂 parser 的 warning output ，也知道具
體是那些地方發生了 conflict ，但我不清楚如何修改 grammar 才能不失優雅地排除 ambigious
。

## Feedback to T.A.s

> Please help us improve our assignment, thanks.

No.

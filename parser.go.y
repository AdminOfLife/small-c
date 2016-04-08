%{
package main

import (
    "os"
    "go/scanner"
    "go/token"
    "fmt"
)

%}

%union {
  token Token

  expression Expression
  expressions []Expression

  declarator Declarator
  declarators []Declarator

  statement Statement
  statements []Statement

  parameters []ParameterDeclaration
  parameter_declaration ParameterDeclaration
}

%type<expression> external_declaration declaration function_definition
%type<expression> expression add_expression mult_expression assign_expression primary_expression logical_or_expression logical_and_expression equal_expression relation_expression unary_expression
%type<expressions> program
%type<statements> statements
%type<statement> statement compound_statement
%type<declarator> declarator
%type<declarators> declarators
%type<parameters> parameters
%type<parameter_declaration> parameter_declaration
%type<token> unary_op
%token<token> NUMBER IDENT TYPE IF LOGICAL_OR LOGICAL_AND RETURN EQL NEQ GEQ LEQ ELSE WHILE

%left '+'
%left '*'
%left '='

%%

program
  : external_declaration
  {
    $$ = []Expression{$1}
    yylex.(*Lexer).result = $$
  }
  | program external_declaration
  {
    $$ = append($1, $2)
    yylex.(*Lexer).result = $$
  }

declaration
  : TYPE declarators ';'
  {
    $$ = Declaration{ varType: $1.lit, declarators: $2 }
  }

declarators
  : declarator
  {
    $$ = []Declarator{ $1 }
  }
  | declarators ',' declarator
  {
    $$ = append($1, $3)
  }

declarator
  : IDENT
  {
    $$ = Declarator{ identifier: $1.lit }
  }
  | IDENT '[' NUMBER ']'
  {
    $$ = Declarator{ identifier: $1.lit, size: $3.lit }
  }

external_declaration
  : declaration
  | function_definition

function_definition
  : TYPE IDENT '(' ')' compound_statement
  {
    $$ = FunctionDefinition{ typeName: $1.lit, identifier: $2.lit, statement: $5 }
  }
  | TYPE IDENT '(' parameters ')' compound_statement
  {
    $$ = FunctionDefinition{ typeName: $1.lit, identifier: $2.lit, statement: $6 }
  }

parameters
  : parameter_declaration
  {
    $$ = []ParameterDeclaration{ $1 }
  }
  | parameters ',' parameter_declaration
  {
    $$ = append($1, $3)
  }

parameter_declaration
  : TYPE IDENT
  {
    $$ = ParameterDeclaration{ typeName: $1.lit, identifier: $2.lit }
  }

compound_statement
  : '{' '}'
  {
    $$ = CompoundStatement{}
  }
  | '{' statements '}'
  {
    $$ =  CompoundStatement{ statements: $2 }
  }

statements
  : statement
  {
    $$ = []Statement{ $1 }
  }
  | statements statement
  {
    $$ = append($1, $2)
  }

statement
  : ';'
  {
    $$ = ExpressionStatement{}
  }
  | expression ';'
  {
    $$ = ExpressionStatement{ expression: $1 }
  }
  | compound_statement
  | IF '(' expression ')' statement
  {
    $$ = IfStatement{ expression: $3, trueStatement: $5 }
  }
  | IF '(' expression ')' statement ELSE statement
  {
    $$ = IfStatement{ expression: $3, trueStatement: $5, falseStatement: $7 }
  }
  | WHILE '(' expression ')' statement
  {
    $$ = WhileStatement{ condition: $3, statement: $5 }
  }
  | RETURN ';'
  {
    $$ = ReturnStatement{}
  }
  | RETURN expression ';'
  {
    $$ = ReturnStatement{ expression: $1 }
  }

expression
  : assign_expression

assign_expression
  : logical_or_expression
  | logical_or_expression '=' logical_or_expression
  {
    $$ = AssignExpression{ left: $1, right: $3 }
  }

logical_or_expression
  : logical_and_expression
  | logical_and_expression LOGICAL_OR logical_and_expression
  {
    $$ = BinOpExpression{ left: $1, operator: $2.lit, right: $3}
  }

logical_and_expression
  : equal_expression
  | equal_expression LOGICAL_AND equal_expression
  {
    $$ = BinOpExpression{ left: $1, operator: $2.lit, right: $3}
  }

equal_expression
  : relation_expression
  | relation_expression EQL relation_expression
  {
    $$ = BinOpExpression{ left: $1, operator: $2.lit, right: $3}
  }
  | relation_expression NEQ relation_expression
  {
    $$ = BinOpExpression{ left: $1, operator: $2.lit, right: $3}
  }

relation_expression
  : add_expression
  | add_expression '>' add_expression
  {
    $$ = BinOpExpression{ left: $1, operator: ">", right: $3}
  }
  | add_expression '<' add_expression
  {
    $$ = BinOpExpression{ left: $1, operator: "<", right: $3}
  }
  | add_expression GEQ add_expression
  {
    $$ = BinOpExpression{ left: $1, operator: $2.lit, right: $3}
  }
  | add_expression LEQ add_expression
  {
    $$ = BinOpExpression{ left: $1, operator: $2.lit, right: $3}
  }

add_expression
  : mult_expression
  | add_expression '+' mult_expression
  {
    $$ = BinOpExpression{ left: $1, operator: "+", right: $3 }
  }
  | add_expression '-' mult_expression
  {
    $$ = BinOpExpression{ left: $1, operator: "-", right: $3 }
  }

mult_expression
  : unary_expression
  | mult_expression '*' primary_expression
  {
    $$ = BinOpExpression{ left: $1, operator: "*", right: $3 }
  }
  | mult_expression '/' primary_expression
  {
    $$ = BinOpExpression{ left: $1, operator: "/", right: $3 }
  }

unary_expression
  : primary_expression
  | unary_op unary_expression
  {
    $$ = UnaryExpression{ operator: $1.lit, expression: $2 }
  }

unary_op
  : '-' { $$ = Token{ lit: "-" } }
  | '&' { $$ = Token{ lit: "&" } }
  | '*' { $$ = Token{ lit: "*" } }

primary_expression
  : NUMBER
  {
    $$ = NumExpr{ lit: $1.lit }
  }
  | IDENT
  {
    $$ = NumExpr{ lit: $1.lit }
  }

%%

type Lexer struct {
    scanner.Scanner
    result Expression
}

var tokenMap = map[token.Token]int {
  token.LOR: LOGICAL_OR,
  token.LAND: LOGICAL_AND,
  token.IF: IF,
  token.ELSE: ELSE,
  token.RETURN: RETURN,
  token.EQL: EQL,
  token.NEQ: NEQ,
  token.GEQ: GEQ,
  token.LEQ: LEQ,
}

func identToNumber(lit string) int {
  if lit == "int" || lit == "void" {
    return TYPE
  } else if lit == "while" {
    return WHILE
  } else {
    return IDENT
  }
}

func (l *Lexer) Lex(lval *yySymType) int {
  pos, tok, lit := l.Scan()
  token_number := int(tok)

  if len(os.Getenv("DEBUG")) > 0 {
    fmt.Println(tok, lit)
  }

  if tokenMap[tok] > 0 {
    return tokenMap[tok]
  }

  switch tok {
  case token.EOF:
    return -1
  case token.INT:
    token_number = NUMBER
  case token.ADD, token.SUB, token.MUL, token.QUO, token.AND,
    token.COMMA, token.SEMICOLON,
    token.ASSIGN,
    token.GTR, token.LSS,
    token.LBRACK, token.RBRACK,
    token.LBRACE, token.RBRACE,
    token.LPAREN, token.RPAREN:
    // newline
    if tok.String() == ";" && lit != ";" {
      // read next
      return l.Lex(lval)
    }
    token_number = int(tok.String()[0])
  case token.IDENT:
    token_number = identToNumber(lit)
  default:
    return -1
  }

  lval.token = Token{ tok: tok, lit: lit, pos: pos }

  return token_number
}

func (l *Lexer) Error(e string) {
  panic(e)
}

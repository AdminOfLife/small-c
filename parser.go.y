%{
package main

import (
    "go/scanner"
    "go/token"
)

type Expression interface{}
type Token struct {
    tok token.Token
    lit string
    pos token.Pos
}

type NumExpr struct {
    lit string
}
type BinOpExpr struct {
    left     Expression
    operator rune
    right    Expression
}

type Declarator struct {
  identifier string
  size string
}

type Declaration struct {
  varType string
  declarators []Declarator
}

%}

%union {
  token Token
  expr Expression
  expressions []Expression
  declarator Declarator
  declarators []Declarator
}

%type<expr> declaration expr
%type<expressions> program
%type<declarator> declarator
%type<declarators> declarators
%token<token> NUMBER IDENT TYPE

%left '+'
%left '*'

%%

program
  : declaration
  {
    $$ = []Expression{$1}
    yylex.(*Lexer).result = $$
  }
  | program declaration
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

expr
  : NUMBER
  {
    $$ = NumExpr{ lit: $1.lit }
  }
  | expr '+' expr
  {
    $$ = BinOpExpr{ left: $1, operator: '+', right: $3 }
  }
  | expr '*' expr
  {
    $$ = BinOpExpr{ left: $1, operator: '*', right: $3 }
  }

%%

type Lexer struct {
    scanner.Scanner
    result Expression
}

func (l *Lexer) Lex(lval *yySymType) int {
  pos, tok, lit := l.Scan()
  token_number := int(tok)

  switch tok {
  case token.INT:
    token_number = NUMBER
  case token.ADD, token.MUL, token.COMMA, token.SEMICOLON, token.LBRACK, token.RBRACK:
    token_number = int(tok.String()[0])
  case token.IDENT:
    if lit == "int" || lit == "void" {
      token_number = TYPE
    } else {
      token_number = IDENT
    }
  default:
    return 0
  }

  lval.token = Token{ tok: tok, lit: lit, pos: pos }

  return token_number
}

func (l *Lexer) Error(e string) {
  panic(e)
}

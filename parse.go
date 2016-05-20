package main

import (
	"fmt"
)

// Parse returns ast
func Parse(src string) ([]Statement, error) {
	l := new(Lexer)
	l.Init(src)
	yyErrorVerbose = true

	fail := yyParse(l)
	if fail == 1 {
		err := fmt.Errorf("%d:%d: %s", l.pos.Line, l.pos.Column, l.errMessage)

		return nil, err
	}

	return l.result, nil
}

// Walk iterates over statement nodes and replace syntax sugar
func Walk(statement Statement) Statement {
	switch s := statement.(type) {
	case *FunctionDefinition:
		for i, p := range s.Parameters {
			s.Parameters[i] = WalkExpression(p)
		}

		s.Statement = Walk(s.Statement)

		return s

	case *CompoundStatement:
		for i, st := range s.Statements {
			s.Statements[i] = Walk(st)
		}

		for i, d := range s.Declarations {
			s.Declarations[i] = Walk(d)
		}

		return s

	case *ForStatement:
		// for (init; cond; loop) s
		// => init; while (cond) { s; loop; }
		body := Walk(s.Statement)
		return &CompoundStatement{
			Statements: []Statement{
				&ExpressionStatement{Value: s.Init},
				&WhileStatement{
					pos:       s.Pos(),
					Condition: s.Condition,
					Statement: &CompoundStatement{
						Statements: []Statement{
							body,
							&ExpressionStatement{Value: s.Loop},
						},
					},
				},
			},
		}

	case *WhileStatement:
		s.Condition = WalkExpression(s.Condition)
		s.Statement = Walk(s.Statement)

	case *IfStatement:
		s.Condition = WalkExpression(s.Condition)
		s.TrueStatement = Walk(s.TrueStatement)
		s.FalseStatement = Walk(s.FalseStatement)

		return s

	case *ReturnStatement:
		s.Value = WalkExpression(s.Value)
		return s

	case *ExpressionStatement:
		s.Value = WalkExpression(s.Value)
		return s
	}

	return statement
}

func WalkExpression(expression Expression) Expression {
	switch e := expression.(type) {
	case *ExpressionList:
		for i, value := range e.Values {
			e.Values[i] = WalkExpression(value)
		}

		return e

	case *FunctionCallExpression:
		e.Argument = WalkExpression(e.Argument)

		return e

	case *BinaryExpression:
		e.Left = WalkExpression(e.Left)
		e.Right = WalkExpression(e.Right)

		return e

	case *UnaryExpression:
		e.Value = WalkExpression(e.Value)

		if e.Operator == "-" {
			return &BinaryExpression{
				Left:     &NumberExpression{pos: e.Pos(), Value: "0"},
				Operator: "-",
				Right:    e.Value,
			}
		} else if e.Operator == "&" {
			// &(*e) -> e
			switch value := e.Value.(type) {
			case *UnaryExpression:
				if value.Operator == "*" {
					return value.Value
				}
			}
		}

		return e

	case *ArrayReferenceExpression:
		// a[100]  =>  *(a + 100)
		e.Target = WalkExpression(e.Target)
		e.Index = WalkExpression(e.Index)

		return &UnaryExpression{
			Operator: "*",
			Value: &BinaryExpression{
				Left:     e.Target,
				Operator: "+",
				Right:    e.Index,
			},
		}
	}

	return expression
}

package main

import (
	"fmt"
	"go/token"
)

type Env struct {
	Table    map[string]*Symbol
	Level    int
	Children []*Env
	Parent   *Env
}

func (env *Env) CreateChild() *Env {
	newEnv := &Env{Parent: env, Level: env.Level + 1}
	env.Children = append(env.Children, newEnv)
	return newEnv
}

func (env *Env) Add(symbol *Symbol) error {
	if env.Table == nil {
		env.Table = map[string]*Symbol{}
	}

	name := symbol.Name
	found := env.Table[name]
	if found != nil && found.Kind != "proto" {
		return fmt.Errorf("`%s` is already defined", name)
	}

	if symbol.Level == 0 {
		symbol.Level = env.Level
	}

	env.Table[name] = symbol
	return nil
}

func (env *Env) Register(identifier *IdentifierExpression, symbol *Symbol) error {
	symbol.Name = identifier.Name
	err := env.Add(symbol)

	if err == nil {
		identifier.Symbol = symbol
	}

	return err
}

func (env *Env) Get(name string) *Symbol {
	symbol := env.Table[name]

	if symbol != nil {
		return symbol
	}

	if env.Parent != nil {
		return env.Parent.Get(name)
	}

	return nil
}

type Symbol struct {
	Name  string
	Level int
	Kind  string
	Type  SymbolType
	Offset int
}

func (symbol *Symbol) IsVariable() bool {
	return symbol.Kind == "var" || symbol.Kind == "parm"
}

type SemanticError struct {
	error
	Pos token.Pos
	Err error
}

func (e SemanticError) Error() string {
	return e.Err.Error()
}

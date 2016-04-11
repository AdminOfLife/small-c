package main

import (
	"fmt"

	"io/ioutil"
	"os"

	"github.com/k0kubun/pp"
)

func main() {
	data, _ := ioutil.ReadAll(os.Stdin)
	src := string(data)
	statements, err := Parse(src)
	if err != nil {
		fmt.Println(err)
		return
	}

	for i, statement := range statements {
		statements[i] = Walk(statement)
	}

	prelude, _ := Parse("void print(int i);\n")
	statements = append(prelude, statements...)

	env := &Env{}
	errs := Analyze(statements, env)
	if len(errs) > 0 {
		for _, err := range errs {
			switch e := err.(type) {
			case SemanticError:
				lineNumber, columnNumber := posToLineInfo(src, int(e.Pos))
				err = fmt.Errorf("%d:%d: %v", lineNumber, columnNumber, e.Err)

			default:
			}

			fmt.Fprintln(os.Stderr, err)
		}

		os.Exit(1)
	}

	pp.Println(statements, env)
}

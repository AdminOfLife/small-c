main: parser
	go build

parser:
	go tool yacc -o parser.go parser.go.y

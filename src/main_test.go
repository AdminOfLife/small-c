package main

import (
	"io/ioutil"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
)

func TestSimulateExample(t *testing.T) {
	examples := [](struct {
		Filename string
		Output   string
	}){
		{"example/sum.sc", "1"},
		{"example/sum_for.sc", "45"},
		{"example/many_args.sc", "6"},
		{"example/factorial.sc", "24"},
		{"example/fib.sc", "89"},
		{"example/global_var.sc", "11"},
		{"example/if_test.sc", ""},
		{"example/pointer_test.sc", "1"},
		{"example/optimize_constant.sc", "1"},
		{"example/bubble_sort.sc", "12345678"},
		{"example/quick_sort.sc", "12345678"},
		{"example/putchar.sc", "hello world"},
		{"example/gcd.sc", "21"},
		{"example/prime.sc", "2 3 5 7 11 13 17 19 23 29 "},
		{"example/emoji.sc", "45"},
		{"example/fizzbuzz.sc", "1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz 16 17 Fizz 19 Buzz Fizz 22 23 Fizz Buzz 26 Fizz 28 29 FizzBuzz "},
	}

	for _, example := range examples {
		sourceFilename := example.Filename
		filename := regexp.MustCompile("\\.sc$").ReplaceAllString(sourceFilename, ".s")

		{
			err := compileAndSave(sourceFilename)

			if err != nil {
				t.Errorf("%v: %v", sourceFilename, err)
				continue
			}
		}

		output, err := runSpim(filename)
		if err != nil {
			t.Error(err)
			continue
		}

		expected := example.Output

		if output != expected {
			t.Errorf("`%v`: expect `%v`, got `%v`", filename, expected, output)
		}
	}
}

func TestSampleOk(t *testing.T) {
	sampleFiles, _ := filepath.Glob("sample/ok*.sc")
	for _, sampleFile := range sampleFiles {
		testOk(t, sampleFile)
	}
}

func TestSampleNg(t *testing.T) {
	sampleFiles, _ := filepath.Glob("sample/ng*.sc")
	for _, filename := range sampleFiles {
		err := compileAndSave(filename)
		if err == nil {
			t.Errorf("%v: expect error, got ok", filename)
		}
	}
}

func TestBasic(t *testing.T) {
	filenames, _ := filepath.Glob("test/basic/*.sc")
	for _, filename := range filenames {
		testOk(t, filename)
	}
}

func TestAdvanced(t *testing.T) {
	filenames, _ := filepath.Glob("test/advanced/*.sc")
	for _, filename := range filenames {
		testOk(t, filename)
	}
}

func TestErr(t *testing.T) {
	filenames, _ := filepath.Glob("test/err/*.sc")
	for _, filename := range filenames {
		err := compileAndSave(filename)
		if err == nil {
			t.Errorf("%v: expect error, got ok", filename)
		}
	}
}

func compileAndSave(filename string) error {
	src, err := ioutil.ReadFile(filename)
	if err != nil {
		return err
	}

	code, errs := CompileSource(string(src), true)
	for _, err := range errs {
		return err
	}

	dest := regexp.MustCompile("\\.sc$").ReplaceAllString(filename, ".s")
	err = ioutil.WriteFile(dest, []byte(code), 0777)
	if err != nil {
		return err
	}

	return nil
}

func runSpim(filename string) (string, error) {
	byteOut, err := exec.Command("spim", "-file", filename).Output()
	if err != nil {
		return "", err
	}

	lines := strings.Split(string(byteOut), "\n")
	output := lines[len(lines)-1]

	return output, nil
}

func testOk(t *testing.T, sourceFilename string) {
	filename := regexp.MustCompile("\\.sc$").ReplaceAllString(sourceFilename, ".s")

	{
		err := compileAndSave(sourceFilename)

		if err != nil {
			t.Errorf("%v: %v", sourceFilename, err)
			return
		}

		output, err := runSpim(filename)
		if err != nil {
			t.Error(err)
			return
		}

		expected := "1"
		if output != expected {
			t.Errorf("`%v`: expect `%v`, got `%v`", filename, expected, output)
		}
	}
}

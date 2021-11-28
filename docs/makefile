.PHONY: clean

all:
	mkdir -p build
	pdflatex -output-directory=build docs.tex

watch:
	zathura build/docs.pdf &
	ls *.tex | entr make

clean:
	rm ./build/*

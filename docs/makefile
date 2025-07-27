.PHONY: clean watch

TARGETS = docs

LATEX = xelatex -shell-escape
BIBTEX  = bibtex

all:  $(TARGETS)

$(TARGETS):
	$(LATEX) $@
	-$(BIBTEX) $@
	$(LATEX) $@
	$(LATEX) $@
	$(LATEX) $@

debug:
	-grep Warning *.log

clean:
	rm -f *.aux *.bbl *.blg *.log *.dvi *.bak *~ $(TARGETS:%=%.pdf)

watch:
	ls *.tex | entr make

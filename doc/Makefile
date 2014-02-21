# type "make doc" command in Unix to create summary.pdf file 
doc:
	pdflatex summary
	pdflatex summary
	bibtex summary
	pdflatex summary
	pdflatex summary
	pdflatex summary

clean:
	rm -rf *.ps *.log *.dvi *.aux *.*% *.lof *.lop *.lot *.toc *.idx *.ilg *.ind *.bbl *.blg *.tex~ *.out *.asv *~

cleaner: clean
	rm -rf *.pdf *.tex *.bib *.xls *.txt *.xlsx *.csv
	rm -rf html

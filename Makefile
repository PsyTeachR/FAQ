default :
	Rscript -e "utils::browseURL(bookdown::render_book('index.Rmd'))"

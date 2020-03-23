
# Knitting and RMarkdown Files

## Every time I knit, I get a message that packages are missing, and it won't knit.

Probably what's happening is that it tries but fails to install the necessary packages. Mark down the names of the packages that it says you need and try to install them from the command line. For example, if it says you need **`digest`** then type this into the console:


```r
install.packages("digest")
```

and see what happens. Note any error messages. Check [the section on packages](add-on-packages.html) for help with specific error messages.

*October 24, 2019. -DB*

## How do I get nicely formatted R code into a Word document?

You might want to include your R code as an appendix in a document. If you just cut and paste it in, the formatting will look terrible. So here is a trick that allows you to get nicely formatted R code into Word.

First step: open a new R Markdown file which you will paste the code into. For the output format, select Word.

![](images/rmarkdown-word-code-1.png)

Second step: paste the code into a block with chunk options `eval=FALSE, echo=TRUE`.

````
```{r verb, eval = FALSE, echo=TRUE}
## this is my code
library("tidyverse")

dat <- read_csv("blah.csv") %>%
  group_by(subj_id) %>%
  summarise(m = mean(RT))
```
````

Third step: compile to Word. You can now copy and paste the formatted code into your document.

![](images/rmarkdown-word-code-2.png)


# Knitting and RMarkdown Files

## Every time I knit, I get a message that packages are missing, and it won't knit.

Probably what's happening is that it tries but fails to install the necessary packages. Mark down the names of the packages that it says you need and try to install them from the command line. For example, if it says you need **`digest`** then type this into the console:


```r
install.packages("digest")
```

and see what happens. Note any error messages. Check [the section on packages](add-on-packages.html) for help with specific error messages.

*October 24, 2019. -DB*

# psyTeachR styles and functions
# do not edit!!!!!

library(tidyverse)

# default knitr options
knitr::opts_chunk$set(
  echo       = TRUE,
  results    = "hold",
  out.width = '100%',
  fig.width  = 8, 
  fig.height = 5, 
  fig.align = 'center',
  fig.cap='**CAPTION THIS FIGURE!!**'
)

# make docs directory and include .nojekyll file for github
if (!dir.exists('docs')) dir.create('docs')
file.create('docs/.nojekyll')

## set global theme options for figures
theme_set(theme_bw())

## set class for a chunk using class="className"
knitr::knit_hooks$set(class = function(before, options, envir) {
  if (before) {
    sprintf("<div class = '%s'>", options$class)
  } else {
    "</div>"
  }
})

## verbatim code chunks
knitr::knit_hooks$set(verbatim = function(before, options, envir) {
  if (before) {
    sprintf("<div class='verbatim'><code>&#96;&#96;&#96;{%s}</code>", options$verbatim)
  } else {
    "<code>&#96;&#96;&#96;</code></div>"
  }
})

## verbatim inline R in backticks
backtick <- function(code) {
  # removes inline math coding when you use >1 $ in a line
  code <- gsub("\\$", "\\\\$", code) 
  paste0("<code>&#096;", code, "&#096;</code>")
}


## palette with psyTeachR logo colour
psyteachr_colours <- function(vals = 1:6) {
  ptrc <- c(
    "pink" = "#983E82",
    "orange" = "#E2A458",
    "yellow" = "#F5DC70",
    "green" = "#59935B",
    "blue" = "#467AAC",
    "purple" = "#61589C"
  )
  
  unname(ptrc[vals])
}
psyteachr_colors <- psyteachr_colours

## link to glossary with shortdef on hover
#' Display glossary entry
#'
#' @param term The glossary term to link to, can contain spaces
#' @param display The display (if different than the term)
#' @param def The short definition to display on hover and in the glossary table; if NULL, this will be looked up from https://psyteachr.github.io/glossary/
#' @param link whether to include a link to https://psyteachr.github.io/glossary/
#' @param add_to_table whether to add to the table created by glossary_table()
#'
#' @return string with the link and hover text
#' @export
#'
#' @examples
#' glossary("alpha")
#' glossary("argument", "Arguments")
#' glossary("PSYCH1001", shortdef = "Your class", link = FALSE)
#' 
glossary <- function(term, display = NULL, def = NULL, link = TRUE, add_to_table = TRUE) {
  lcterm <- gsub(" ", "-", tolower(term), fixed = TRUE)
  if (is.null(display)) display <- term
  first_letter <- substr(lcterm, 1, 1)
  url <- paste0("https://psyteachr.github.io/glossary/", first_letter)
  if (is.null(def) || def == "") {
    # look up short definition from glossary site
    hash <- paste0("#", lcterm, ".level2")
    tabledef <- tryCatch({
      the_html <- xml2::read_html(url)
      the_node <- rvest::html_node(the_html, hash)
      if (is.na(the_node)) stop("No glossary entry for ", lcterm)
      the_dfn <- rvest::html_node(the_node, "dfn")
      the_text <- rvest::html_text(the_dfn)
      the_def <- gsub("\'", "&#39;", the_text)
      if (is.na(the_def)) stop("No glossary shortdef for ", lcterm)
      the_def
    },
    error = function(e) { 
      warning(e, call. = FALSE)
      return("")
    })
    
    if (is.null(def)) def <- tabledef
  } else {
    tabledef <- def
  }
  
  ## add to global glossary for this book
  if (add_to_table) {
    env <- .GlobalEnv
    if (!exists(".myglossary", envir = env)) {
      assign(".myglossary", list(), envir = env)
    }
    .myglossary[lcterm] <<- tabledef
  }
  
  if (link) {
    # make a link that opens the definition webpage in a new window
    paste0("<a class='glossary' target='_blank' title='", def, 
           "' href='", url, "#", lcterm, "'>", display, "</a>")
  } else {
    # just add the tooltip and don't link to the definition webpage
    paste0("<a class='glossary' title='", def, "'>", display, "</a>")
  }
}


#' Reset glossary table
#' 
#' Resets the list .myglossary in the parent environment that collects glossary entries for the table
#'
#' @return NULL
#' @export
#'
#' @examples
#' reset_glossary()
#' 
reset_glossary <- function() {
  env <- .GlobalEnv
  assign(".myglossary", list(), envir = env)
}

#' Display glossary table
#'
#' @param link whether to include a link to https://psyteachr.github.io/glossary/
#' @param as_kable if the output should be a kable table or a data table
#'
#' @return kable table or data table
#' @export
#'
#' @examples
#' glossary("alpha")
#' glossary("beta")
#' glossary_table()
glossary_table <- function(link = TRUE, as_kable = TRUE) {
  env <- .GlobalEnv
  if (!exists(".myglossary", envir = env)) {
    assign(".myglossary", list(), envir = env)
  }
  glossary <- .myglossary
  if (is.null(glossary)) glossary <- list()
  
  term <- names(glossary)
  if (link) {
    link_term <- paste0("<a class='glossary' target='_blank' ",
                        "href='https://psyteachr.github.io/glossary/",
                        substr(term, 1, 1), "#", term, "'>",
                        gsub(".", " ", term, fixed = 1), "</a>")
  } else {
    link_term <- term
  }
  
  the_list <- data.frame(
    term = link_term,
    definition = unlist(glossary)
  )
  
  if (as_kable) {
    knitr::kable(the_list[order(term),], escape = FALSE, row.names = FALSE)
  } else {
    the_list[order(term),]
  }
}


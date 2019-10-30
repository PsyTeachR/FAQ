
# Data Wrangling

## Importing data from multiple files

The following code allows you to read in a whole bunch of files from a directory `datadir` all at once into a big table.


```r
# "\\.csv$" = find all files ending with csv or CSV
todo <- tibble(filename = dir("datadir", "\\.[Cc][Ss][Vv]$"))

all_data <- todo %>%
  mutate(imported = read_csv(filename)) %>%
  unnest(imported)
```

If there is preprocessing you need to do on each file before reading it in, you can write your own function and call that in place of `read_csv()`.

*October 30, 2019. -DB*

## Detecting "runs" in a sequence

Let's say you have a table like below, and you want to find the start and end frames where you have a run of `Z` amidst a, b, c, d.  Here is code that sets up this kind of situation. Don't worry if you don't understand this code; just run it to create the example data in `runsdata`, and have a look at that table.


```r
library("knitr")

create_run_vec <- function() {
  ## create a random string of letters with two runs
  c(rep(sample(letters[1:4]), sample(2:4, 4, TRUE)),
               rep("Z", 3),
               rep(sample(letters[1:4]), sample(2:4, 4, TRUE)),
               rep("Z", 3),
               rep(sample(letters[1:4], 2), sample(2:4, 2, TRUE)))
}

## 5 subjects, 3 trials each
runsdata <- tibble(
  subject = rep(1:5, each = 3),
  trial = rep(1:3, 5),
  stimulus = rerun(15, create_run_vec())) %>%
  unnest(stimulus) %>%
  group_by(subject, trial) %>%
  ungroup() %>%
  select(subject, trial, stimulus)
```

Let's say you want to find the start and stop frames where `Z` appears in `stimulus`, and do this independently for each combination of `subject` and `trial`.  Here's how `stimulus` looks for subject 1 and trial 1.


```
##  [1] "d" "d" "d" "d" "a" "a" "a" "c" "c" "c" "c" "b" "b" "Z" "Z" "Z" "d"
## [18] "d" "d" "c" "c" "c" "a" "a" "a" "b" "b" "b" "Z" "Z" "Z" "a" "a" "b"
## [35] "b"
```

So here you can see that the first run of Zs is from frame 14 to 16, 31 and the second is from 29 to 31. We want to write a function that processes the data for each trial and results in a table like this:


```
## # A tibble: 2 x 5
##   subject trial   run start_frame end_frame
##     <dbl> <dbl> <int>       <int>     <int>
## 1       1     1     1          14        16
## 2       1     1     2          29        31
```

The first thing to do is to add a logical vector to your tibble whose value is `TRUE` when the target value (e.g., `Z`) is present in the sequence, false otherwise.


```r
runsdata_tgt <- runsdata %>%
  mutate(is_target = (stimulus == "Z"))

runsdata_tgt
```

```
## # A tibble: 521 x 4
##    subject trial stimulus is_target
##      <int> <int> <chr>    <lgl>    
##  1       1     1 d        FALSE    
##  2       1     1 d        FALSE    
##  3       1     1 d        FALSE    
##  4       1     1 d        FALSE    
##  5       1     1 a        FALSE    
##  6       1     1 a        FALSE    
##  7       1     1 a        FALSE    
##  8       1     1 c        FALSE    
##  9       1     1 c        FALSE    
## 10       1     1 c        FALSE    
## # … with 511 more rows
```

We want to iterate over subjects and trials. We'll start by creating a tibble with columns `is_target` nested into a column called `subtbl`.


```r
runs_nest <- runsdata_tgt %>%
  select(-stimulus) %>% # don't need it anymore
  nest(subtbl = c(is_target))
```

We want to iterate over the little subtables stored within `subtbl` in each row of the table, passing the table to a function that will find the runs and return another table, which we'll store in new column. Let's write a function to detect the runs. That function will need the function `rle()` (Run-Length Encoding) from base R. We'll run that on the logical vector we created (`is_target`). Before creating the function, let's see what `rle()` does on the values in `is_target` for subject 1, trial 1.


```r
s1t1 <- runsdata_tgt %>% filter(subject == 1L, trial == 1L) %>% pull(is_target)

s1t1

rle(s1t1)
```

```
##  [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
## [12] FALSE FALSE  TRUE  TRUE  TRUE FALSE FALSE FALSE FALSE FALSE FALSE
## [23] FALSE FALSE FALSE FALSE FALSE FALSE  TRUE  TRUE  TRUE FALSE FALSE
## [34] FALSE FALSE
## Run Length Encoding
##   lengths: int [1:5] 13 3 12 3 4
##   values : logi [1:5] FALSE TRUE FALSE TRUE FALSE
```

If that doesn't make sense, look at the help for `rle()` (type `?rle` in the console). Now we're ready to write our function, `detect_runs()`.


```r
detect_runs <- function(x) {  
  if (!is.logical(x[[1]])) stop("'x' must be a tibble whose first column is of type 'logical'")
  runs <- rle(x[[1]])
  run_start_fr <- c(1L, cumsum(runs$lengths[-length(runs$lengths)]) + 1L)
  run_end_fr <- run_start_fr + (runs$lengths - 1L)
  
  tgt_start <- run_start_fr[runs$values]
  tgt_end <- run_end_fr[runs$value]
  tibble(run = seq_along(tgt_start),
         start_fr = tgt_start,
         end_fr = tgt_end)
}
```

We can test the function on `s1t1` just to make sure it works.


```r
detect_runs(tibble(lvec = s1t1))
```

```
## # A tibble: 2 x 3
##     run start_fr end_fr
##   <int>    <int>  <int>
## 1     1       14     16
## 2     2       29     31
```

OK, now we're ready to run the function.


```r
result <- runs_nest %>%
  mutate(runstbl = map(subtbl, detect_runs))

result
```

```
## # A tibble: 15 x 4
##    subject trial         subtbl runstbl         
##      <int> <int> <list<df[,1]>> <list>          
##  1       1     1       [35 × 1] <tibble [2 × 3]>
##  2       1     2       [35 × 1] <tibble [2 × 3]>
##  3       1     3       [38 × 1] <tibble [2 × 3]>
##  4       2     1       [34 × 1] <tibble [2 × 3]>
##  5       2     2       [32 × 1] <tibble [2 × 3]>
##  6       2     3       [38 × 1] <tibble [2 × 3]>
##  7       3     1       [33 × 1] <tibble [2 × 3]>
##  8       3     2       [35 × 1] <tibble [2 × 3]>
##  9       3     3       [34 × 1] <tibble [2 × 3]>
## 10       4     1       [35 × 1] <tibble [2 × 3]>
## 11       4     2       [36 × 1] <tibble [2 × 3]>
## 12       4     3       [32 × 1] <tibble [2 × 3]>
## 13       5     1       [34 × 1] <tibble [2 × 3]>
## 14       5     2       [33 × 1] <tibble [2 × 3]>
## 15       5     3       [37 × 1] <tibble [2 × 3]>
```

Now we just have to unnest and we're done!


```r
result %>%
  select(-subtbl) %>%
  unnest(runstbl)
```

```
## # A tibble: 30 x 5
##    subject trial   run start_fr end_fr
##      <int> <int> <int>    <int>  <int>
##  1       1     1     1       14     16
##  2       1     1     2       29     31
##  3       1     2     1       14     16
##  4       1     2     2       27     29
##  5       1     3     1       13     15
##  6       1     3     2       28     30
##  7       2     1     1       11     13
##  8       2     1     2       26     28
##  9       2     2     1       11     13
## 10       2     2     2       25     27
## # … with 20 more rows
```

*October 30, 2019. -DB*

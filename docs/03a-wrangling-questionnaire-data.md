# Wrangling Questionnaire Data

## How to I convert string values to numeric values?

A very common situation is that you want to convert string values ("Almost Always", "Frequently") into numeric values (5, 4, etc) so that we can calculate a score.

The solution I present here will use something called a "lookup table" that matches string values to numbers.

First, let's assume the following (made-up) questionnaire asks four questions about hygiene. When you bathe, how often do you:

1. Wash your legs?
2. Wash behind your ears?
3. Wash between your toes?
4. Shampoo your hair?

Let's assume that answers are on a scale made up of the values "Never", "Sometimes", "Frequently", "Always", which we want to assign scores of 0, 1, 2, and 3 respectively.

Here is some (also made-up) data from five participants, stored in a tibble named `dat`.




|subj_id |wash_legs  |wash_ears  |wash_toes  |shampoo    |
|:-------|:----------|:----------|:----------|:----------|
|S01     |Sometimes  |Never      |Never      |Frequently |
|S02     |Sometimes  |Frequently |Frequently |Always     |
|S03     |Never      |Never      |Never      |Frequently |
|S04     |Always     |Always     |Sometimes  |Always     |
|S05     |Frequently |Sometimes  |Never      |Sometimes  |

(If you want to make `dat` so you can follow along with the example by running the code in R, click the button below.)


<div class='webex-solution'><button>show me the R code to create the table 'dat'</button>



```r
library("tidyverse")

dat <- tribble(
  ~subj_id, ~wash_legs,   ~wash_ears,   ~wash_toes,   ~shampoo,
  "S01",    "Sometimes",  "Never",      "Never",      "Frequently",
  "S02",    "Sometimes",  "Frequently", "Frequently", "Always",
  "S03",    "Never",      "Never",      "Never",      "Frequently",
  "S04",    "Always",     "Always",     "Sometimes",  "Always",
  "S05",    "Frequently", "Sometimes",  "Never",      "Sometimes")
```


</div>


This data is in *wide* format: there is a single row for each participant with data for each question forming the columns. What we are going to do first is to convert this data from wide to long using `pivot_longer()`. (You'll see why in a minute.)


```r
dat_long <- dat %>%
  pivot_longer(cols = wash_legs:shampoo,
               names_to = "question", values_to = "response")
```

Take a look at `dat_long`.


|subj_id |question  |response   |
|:-------|:---------|:----------|
|S01     |wash_legs |Sometimes  |
|S01     |wash_ears |Never      |
|S01     |wash_toes |Never      |
|S01     |shampoo   |Frequently |
|S02     |wash_legs |Sometimes  |
|S02     |wash_ears |Frequently |
|S02     |wash_toes |Frequently |
|S02     |shampoo   |Always     |
|S03     |wash_legs |Never      |
|S03     |wash_ears |Never      |
|S03     |wash_toes |Never      |
|S03     |shampoo   |Frequently |
|S04     |wash_legs |Always     |
|S04     |wash_ears |Always     |
|S04     |wash_toes |Sometimes  |
|S04     |shampoo   |Always     |
|S05     |wash_legs |Frequently |
|S05     |wash_ears |Sometimes  |
|S05     |wash_toes |Never      |
|S05     |shampoo   |Sometimes  |

Now we only have *one* variable we need to convert to numeric values (`response`) instead of the original four. There is an easy solution: we create a "lookup table" mapping the string values to the numeric values like so.

But first let's check what the unique string values are in the data. Our lookup table must match these *exactly* or the approach won't work.


```r
dat_long %>%
  distinct(response) %>%
  pull()
```

```
## [1] "Sometimes"  "Never"      "Frequently" "Always"
```
This step is important because sometimes these fields can have special characters that you don't normally when you print out a table. The `distinct() %>% pull()` pattern will give you those values in a way that makes them visible. For instance, a student once had values in the data like this:

```
[1] "Somewhat\nInfrequently" "Somewhat\nFrequently"   "Very\nInfrequently"
[4] "Almost\nNever"          "Very\nFrequently"       "Almost\nAlways"
```
and the lookup table was constantly failing because the lookup table they created did not have the `\n` in the middle of each string. *Computers are very literal!*

OK now we're ready to create our lookup table where we match these four values to numbers.


```r
lookup <- tribble(
  ~response, ~score,
  "Never",      0,
  "Sometimes",  1,
  "Frequently", 2,
  "always",     3)
```

As the final step, we `inner_join()` the original table `dat_long` to `lookup` on the variable `response`.


```r
joined <- inner_join(dat_long, lookup, by = "response")
```
**IMPORTANT**: You should check to make sure that the join worked as intended. The values in the lookup table must *exactly* match the values in the `response` column of `dat_long`. It is easy to make a typo in the lookup table, and those values will be lost. An easy test is to make sure that the number of rows in `joined` matches the number of rows in `dat_long`.


```r
stopifnot(nrow(joined) == nrow(dat_long))
```

The function `stopifnot()` will make our script fail if the stated condition (that both tables have the same number of rows) is not satisfied.

Uh oh. Running it gives `Error: nrow(joined) == nrow(dat_long) is not TRUE`. The test failed, because I deliberately included a typo in the lookup table. Can you see it?


<div class='webex-solution'><button>what is it?</button>


`always` should be `Always`. Capitalization matters!


</div>


So let's fix our lookup table and then we should be good to go. Here is the full code for this demonstration:


```r
dat_long <- dat %>%
  pivot_longer(cols = wash_legs:shampoo,
               names_to = "question", values_to = "response")

## check for hidden values
dat_long %>%
  distinct(response) %>%
  pull()

lookup <- tribble(
  ~response, ~score,
  "Never",      0,
  "Sometimes",  1,
  "Frequently", 2,
  "Always",     3)

joined <- inner_join(dat_long, lookup, by = "response")

## test whether the number of rows match
stopifnot(nrow(joined) == nrow(dat_long))
```
You could then use 


```r
joined %>%
  group_by(subj_id) %>%
  summarise(hygiene = sum(score))
```
to calculate a score for each subject.

*August 18, 2021. -DB*

## How do I reverse score a subset of items on my questionnaire?



We will be working with a made-up scale with six items which measures how much respondents appreciate dogs. People respond to each of the six items on a 5 point likert scale, where 1=strongly disagree, 2=somewhat disagree, 3=neutral, 4=somewhat agree, 5=strongly agree.


Table: (\#tab:dog-scale)The Dog Appreciation Scale

|item                             |reverse_score |
|:--------------------------------|:-------------|
|I like dogs                      |FALSE         |
|Dogs are fun                     |FALSE         |
|Cats are better than dogs        |TRUE          |
|Dogs are helpful                 |FALSE         |
|Dogs are too noisy               |TRUE          |
|Dogs are too much responsibility |TRUE          |

Here is some made-up questionnaire data with 6 items and 3 subjects, contained in the tibble named `das`. We want to reverse score the items "Cats are better than dogs", "Dogs are too noisy", and "Dogs are too much responsibility" before summing up the total for each subject.


```
## # A tibble: 18 x 3
##    subj_id item                             score
##    <chr>   <chr>                            <dbl>
##  1 S01     I like dogs                          5
##  2 S01     Dogs are fun                         5
##  3 S01     Cats are better than dogs            1
##  4 S01     Dogs are helpful                     4
##  5 S01     Dogs are too noisy                   2
##  6 S01     Dogs are too much responsibility     2
##  7 S02     I like dogs                          3
##  8 S02     Dogs are fun                         4
##  9 S02     Cats are better than dogs            2
## 10 S02     Dogs are helpful                     4
## 11 S02     Dogs are too noisy                   3
## 12 S02     Dogs are too much responsibility     5
## 13 S03     I like dogs                          1
## 14 S03     Dogs are fun                         3
## 15 S03     Cats are better than dogs            5
## 16 S03     Dogs are helpful                     2
## 17 S03     Dogs are too noisy                   4
## 18 S03     Dogs are too much responsibility     5
```


<div class='webex-solution'><button>show me the code to create the table 'das'</button>



```r
library("tidyverse")

das <- tribble(
  ~subj_id, ~item, ~score,
  "S01", "I like dogs",                      5,
  "S01", "Dogs are fun",                     5,
  "S01", "Cats are better than dogs",        1,
  "S01", "Dogs are helpful",                 4,
  "S01", "Dogs are too noisy",               2,
  "S01", "Dogs are too much responsibility", 2,
  "S02", "I like dogs",                      3,
  "S02", "Dogs are fun",                     4,
  "S02", "Cats are better than dogs",        2,
  "S02", "Dogs are helpful",                 4,
  "S02", "Dogs are too noisy",               3,
  "S02", "Dogs are too much responsibility", 5,
  "S03", "I like dogs",                      1,
  "S03", "Dogs are fun",                     3,
  "S03", "Cats are better than dogs",        5,
  "S03", "Dogs are helpful",                 2,
  "S03", "Dogs are too noisy",               4,
  "S03", "Dogs are too much responsibility", 5)
```


</div>


First, we assume that you have your data in long format, like the table above. If you don't, then please see the materials on reshaping from wide to long, such as [this section from the MSC book](https://psyteachr.github.io/msc-data-skills/tidyr.html#pivot_longer).

We are going to use a programming trick that we'll call "the N-plus-one-minus-X trick" to score the items that need to be reverse coded. This trick will work whenever you have a scale with N scale points that goes in integer steps from 1 to N (e.g., 1, 2, 3, 4, 5). You subtract Xs (each observed score) from N+1 to get the reversed value.

*newscore = (number_of_scale_points + 1) - oldscore*

So if you have a 5 point scale, it is:

*newscore = 6 - oldscore*

and a 7 point scale is

*newscore = 8 - oldscore*.

You can see this works using the following code:


```r
oldscores <- 1:5
newscores <- 6 - oldscores

rbind(oldscores, newscores)
```

```
##           [,1] [,2] [,3] [,4] [,5]
## oldscores    1    2    3    4    5
## newscores    5    4    3    2    1
```

**Note: If your scale goes from 0 to N, then use N - X rather than (N + 1) - X to reverse score.**

So we can see already that we need something like:


```r
das %>%
  mutate(newscore = 6 - score)
```

but *only* for those items that need to be reverse scored. This is where `if_else()` comes in. Or, better said, where `if_else()` comes `%in%` (if you can pardon a bit of R humor).


```r
das_coded <- das %>%
  mutate(newscore = if_else(item %in% c("Cats are better than dogs",
                                        "Dogs are too noisy",
                                        "Dogs are too much responsibilitiy"),
                            6 - score,
                            score))
```

The code above adds a new variable `newscore` which is the result of the `if_else()` command and stores the resulting table in `das_coded`. This command has the following syntax:

`if_else(condition, value_if_true, value_if_false)`.

So, if the current value of item is found within the vector of options (that's what the `%in%` operator does), the first expression evaluates to `TRUE`, and `6-score` is returned; if the first expression evaluates to `FALSE`, then `score` is returned.

But whenever you recode or score a variable, you should *ALWAYS* check that your code is correct, because typos are likely. The best way to do this is to run a little test in the console. You can just print out the data from `das_coded`, or if you have a lot of data, use `distinct()` to look at check the distinct values observed in the data.


```r
das_coded %>%
  distinct(item, score, newscore) %>%
  print(n = +Inf) ## this makes sure *all* rows are printed, not just the first 20
```

```
## # A tibble: 16 x 3
##    item                             score newscore
##    <chr>                            <dbl>    <dbl>
##  1 I like dogs                          5        5
##  2 Dogs are fun                         5        5
##  3 Cats are better than dogs            1        5
##  4 Dogs are helpful                     4        4
##  5 Dogs are too noisy                   2        4
##  6 Dogs are too much responsibility     2        2
##  7 I like dogs                          3        3
##  8 Dogs are fun                         4        4
##  9 Cats are better than dogs            2        4
## 10 Dogs are too noisy                   3        3
## 11 Dogs are too much responsibility     5        5
## 12 I like dogs                          1        1
## 13 Dogs are fun                         3        3
## 14 Cats are better than dogs            5        1
## 15 Dogs are helpful                     2        2
## 16 Dogs are too noisy                   4        2
```

Here we can see that "Cats are better than dogs" and "Dogs are too noisy" have been successfully reverse scored. We can also see that the items that should be forward scored, e.g., "I like dogs", are indeed forward scored (the scores don't change).

But our reverse scoring of "Dogs are too much responsibility" has failed. Can you see the problem in our code (hint: typo).


<div class='webex-solution'><button>no, I can't see the problem</button>


`responsibility` is mistyped as `responsibilitiy`


</div>


So the correct code is:


```r
das_coded <- das %>%
  mutate(newscore = if_else(item %in% c("Cats are better than dogs",
                                        "Dogs are too noisy",
                                        "Dogs are too much responsibility"),
                            6 - score,
                            score))
```


```r
das_coded %>%
  distinct(item, score, newscore) %>%
  print(n = +Inf) ## this makes sure *all* rows are printed, not just the first 20
```

```
## # A tibble: 16 x 3
##    item                             score newscore
##    <chr>                            <dbl>    <dbl>
##  1 I like dogs                          5        5
##  2 Dogs are fun                         5        5
##  3 Cats are better than dogs            1        5
##  4 Dogs are helpful                     4        4
##  5 Dogs are too noisy                   2        4
##  6 Dogs are too much responsibility     2        4
##  7 I like dogs                          3        3
##  8 Dogs are fun                         4        4
##  9 Cats are better than dogs            2        4
## 10 Dogs are too noisy                   3        3
## 11 Dogs are too much responsibility     5        1
## 12 I like dogs                          1        1
## 13 Dogs are fun                         3        3
## 14 Cats are better than dogs            5        1
## 15 Dogs are helpful                     2        2
## 16 Dogs are too noisy                   4        2
```

We've done it! Now we can proceed to analyze our data further.

*January 2021. -DB*

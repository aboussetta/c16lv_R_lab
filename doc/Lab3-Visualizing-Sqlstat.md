# Episode 3 - SQLSTAT Visualizations

## Overview

SQL "statistics" views (v$sqlstats, dba_hist_sqlstat) contain **aggregated "system-wide"** performance data for your database.
They are great tools for performance, load and trend analysis, for example, answering questions like:

*Do I have unstable SQLs?*

## Style note

You may see a slightly different display style while executing the following ggplot examples (due to your environment settings).
If you want visual style to be exactly as in this document, define “theme elements”:

```R
mytheme <- theme_minimal() +theme (
      axis.line=element_blank(),
      axis.text.x=element_blank(),
      axis.text.y=element_blank(),
      axis.title.x=element_blank(),
      axis.title.y=element_blank(),
      panel.background=element_blank(),
      panel.grid.minor=element_blank()
)
```

And then add **+mytheme** at the end of each ggplot command, i.e.:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS)) +geom_point() +mytheme
```


##i Load necessary packages

```R
library(ggplot2)
library(plyr)
library(sqldf)
library(scales)
library(stringr)
```

## Get the data

```R
d <- read.csv('data/c16lv_example_sqlstat2.csv', stringsAsFactors=F)
```

If you are interested in the actual SQL that grabbed this data, here it is: http://intermediatesql.com/wp-content/uploads/2014/02/rlab_get_sql_stat.sql_.txt  

## Clean the data

Before making a graph, you need to eyeball your data and, more often than not, clean and massage it for better graphing.

First of all, check what you have:

```R
str(d)

'data.frame':   174604 obs. of  27 variables:
 $ TS                      : chr  "2013-08-25 08:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" ...
 $ SQL_ID                  : chr  "g5a46cnz09948" "vk4q6hr39s57g" "d0ku4grrv4575" "yy17gdxs08574" ...
 $ FETCHES                 : chr  "37804" "0" "12803" "11112" ...
 $ SORTS                   : chr  "0" "0" "0" "0" ...
 $ EXECUTIONS              : chr  "37804" "10346" "12803" "11112" ...
 $ PARSE_CALLS             : chr  "13708" "1315" "7966" "3931" ...
 $ DISK_READS              : chr  "0" "10459" "0" "304" ...
 $ BUFFER_GETS             : chr  "0" "466539" "66131" "33742" ...
 $ ROWS_PROCESSED          : chr  "37804" "10346" "12803" "406" ...
 $ CPU_TIME                : chr  "3059552" "4099356" "671899" "384945" ...
 $ ELAPSED_TIME            : chr  "11402732" "59958791" "743968" "2114141" ...
 $ IOWAIT                  : chr  "0" "49926497" "0" "1709069" ...
 $ CLWAIT                  : chr  "0" "0" "0" "0" ...
 $ APWAIT                  : chr  "0" "0" "0" "0" ...
 $ CCWAIT                  : chr  "0" "0" "0" "0" ...
 $ DIRECT_WRITES           : chr  "0" "0" "0" "0" ...
 $ PLSEXEC_TIME            : chr  "0" "590720" "0" "0" ...
 $ JAVEXEC_TIME            : chr  "0" "0" "0" "0" ...
 $ IO_OFFLOAD_ELIG_BYTES   : chr  "0" "0" "0" "0" ...
 $ IO_INTERCONNECT_BYTES   : chr  "0" "85590016" "0" "2490368" ...
 $ PHYSICAL_READ_REQUESTS  : chr  "0" "10448" "0" "304" ...
 $ PHYSICAL_READ_BYTES     : chr  "0" "85590016" "0" "2490368" ...
 $ PHYSICAL_WRITE_REQUESTS : chr  "0" "0" "0" "0" ...
 $ PHYSICAL_WRITE_BYTES    : chr  "0" "0" "0" "0" ...
 $ OPTIMIZED_PHYSICAL_READS: chr  "0" "0" "0" "0" ...
 $ CELL_UNCOMPRESSED_BYTES : chr  "0" "0" "0" "0" ...
 $ IO_OFFLOAD_RETURN_BYTES : chr  "0" "0" "0" "0" ...
```

Let's adjust data types, clean the data and convert dates to UTC:

```R
# Remove non-conforming dates
d <- d[str_length(d$TS) == 19,]

# Convert to 'R date' data type
d$TS <- as.POSIXct(d$TS, "UTC")
```

Notice that all *SQL performance metrics* (such as EXECUTIONS or BUFFER_GETS) were loaded as *characters*. Let’s convert them to numbers:

```R
for (x in (setdiff(names(d), c('TS', 'SQL_ID')))) {
  d[[x]] <- as.numeric(d[[x]])
}

# And now, review the data again:
str(d)

'data.frame':   174601 obs. of  27 variables:
 $ TS                      : POSIXct, format: "2013-08-25 08:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" ...
 $ SQL_ID                  : chr  "g5a46cnz09948" "vk4q6hr39s57g" "d0ku4grrv4575" "yy17gdxs08574" ...
 $ FETCHES                 : num  37804 0 12803 11112 3209 ...
 $ SORTS                   : num  0 0 0 0 0 ...
 $ EXECUTIONS              : num  37804 10346 12803 11112 3209 ...
 $ PARSE_CALLS             : num  13708 1315 7966 3931 3209 ...
 $ DISK_READS              : num  0 10459 0 304 0 ...
 $ BUFFER_GETS             : num  0 466539 66131 33742 17689 ...
 $ ROWS_PROCESSED          : num  37804 10346 12803 406 3209 ...
 $ CPU_TIME                : num  3059552 4099356 671899 384945 191969 ...
 $ ELAPSED_TIME            : num  11402732 59958791 743968 2114141 199172 ...
 $ IOWAIT                  : num  0 49926497 0 1709069 0 ...
 $ CLWAIT                  : num  0 0 0 0 0 0 0 0 0 0 ...
 $ APWAIT                  : num  0 0 0 0 0 0 0 0 0 0 ...
 $ CCWAIT                  : num  0 0 0 0 0 0 0 0 0 0 ...
 $ DIRECT_WRITES           : num  0 0 0 0 0 0 0 0 0 0 ...
 $ PLSEXEC_TIME            : num  0 590720 0 0 0 ...
 $ JAVEXEC_TIME            : num  0 0 0 0 0 0 0 0 0 0 ...
 $ IO_OFFLOAD_ELIG_BYTES   : num  0 0 0 0 0 0 0 0 0 0 ...
 $ IO_INTERCONNECT_BYTES   : num  0 85590016 0 2490368 0 ...
 $ PHYSICAL_READ_REQUESTS  : num  0 10448 0 304 0 ...
 $ PHYSICAL_READ_BYTES     : num  0 85590016 0 2490368 0 ...
 $ PHYSICAL_WRITE_REQUESTS : num  0 0 0 0 0 0 0 0 0 0 ...
 $ PHYSICAL_WRITE_BYTES    : num  0 0 0 0 0 0 0 0 0 0 ...
 $ OPTIMIZED_PHYSICAL_READS: num  0 0 0 0 0 0 0 0 0 0 ...
 $ CELL_UNCOMPRESSED_BYTES : num  0 0 0 0 0 0 0 0 0 0 ...
 $ IO_OFFLOAD_RETURN_BYTES : num  0 0 0 0 0 0 0 0 0 0 ...
```

## Visualize

### Prepare the data (a.k.a. do 'statistical analysis')

Let's do some data analysis on our SQls. 

I.e. let's determine if we have SQLs that are wildly varying in "buffer gets per execution" over timei (that is: sometimes they read *a few blocks*, while other times *a whole bunch of blocks*). Such SQLs may represent a problem if you are measuring individual query times and raise alert for *slow queries*. 

While transofrmations in R can be down with SQL (with **sqldf** package), I’m going to use other tools to show that not only SQL can do that. 

First of all, let's clean the data:

```R
# Do not pay attention to SQLs that are not executed a lot or not reading a lot
d1 <- d[d$EXECUTIONS >100 & d$BUFFER_GETS >1000, ]

# Calculate gets per execution
d1$GETS_PER_EXEC <- d1$BUFFER_GETS/d1$EXECUTIONS

# Remove NA values ("non existing data", similar to NULL in ORACLE)
d1 <- d1[!is.na(d1$GETS_PER_EXEC), ]

str(d1)
'data.frame':    101319 obs. of  28 variables:
 $ TS                      : POSIXct, format: "2013-08-25 08:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" ...
 $ SQL_ID                  : chr  "vk4q6hr39s57g" "d0ku4grrv4575" "yy17gdxs08574" "pnrc3mgu21mzz" ...
 $ FETCHES                 : num  0 12803 11112 3209 0 ...
 $ SORTS                   : num  0 0 0 0 0 ...
 $ EXECUTIONS              : num  10346 12803 11112 3209 36900 ...
 $ PARSE_CALLS             : num  1315 7966 3931 3209 35950 ...
 $ DISK_READS              : num  10459 0 304 0 12698 ...
 $ BUFFER_GETS             : num  466539 66131 33742 17689 3427622 ...
 $ ROWS_PROCESSED          : num  10346 12803 406 3209 36899 ...
 $ CPU_TIME                : num  4099356 671899 384945 191969 46071996 ...
 $ ELAPSED_TIME            : num  6.00e+07 7.44e+05 2.11e+06 1.99e+05 1.47e+08 ...
 $ IOWAIT                  : num  49926497 0 1709069 0 65680167 ...
 $ CLWAIT                  : num  0 0 0 0 0 0 0 0 0 0 ...
 $ APWAIT                  : num  0 0 0 0 0 0 0 0 0 0 ...
 $ CCWAIT                  : num  0 0 0 0 0 0 0 0 0 0 ...
 $ DIRECT_WRITES           : num  0 0 0 0 0 0 0 0 0 0 ...
 $ PLSEXEC_TIME            : num  590720 0 0 0 4161211 ...
 $ JAVEXEC_TIME            : num  0 0 0 0 0 0 0 0 0 0 ...
 $ IO_OFFLOAD_ELIG_BYTES   : num  0 0 0 0 0 0 0 0 0 0 ...
 $ IO_INTERCONNECT_BYTES   : num  85590016 0 2490368 0 0 ...
 $ PHYSICAL_READ_REQUESTS  : num  10448 0 304 0 0 ...
 $ PHYSICAL_READ_BYTES     : num  85590016 0 2490368 0 0 ...
 $ PHYSICAL_WRITE_REQUESTS : num  0 0 0 0 0 0 0 0 0 0 ...
 $ PHYSICAL_WRITE_BYTES    : num  0 0 0 0 0 0 0 0 0 0 ...
 $ OPTIMIZED_PHYSICAL_READS: num  0 0 0 0 0 0 0 0 0 0 ...
 $ CELL_UNCOMPRESSED_BYTES : num  0 0 0 0 0 0 0 0 0 0 ...
 $ IO_OFFLOAD_RETURN_BYTES : num  0 0 0 0 0 0 0 0 0 0 ...
 $ GETS_PER_EXEC           : num  45.09 5.17 3.04 5.51 92.89 ...
```

Now let's calculate a standard deviation for (a vector of) "buffer gets per execution" for each SQL. 

**Standard deviation** is a measure of how much data varies against the average.

We will use **ddply()** function from **plyr** package for that. It breaks data into groups (by SQL_ID), calculates standard deviation per group and then combines the data back, assigning per-group deviation to the new column: SD. 

Think: analytic functions in ORACLE SQL.

```R
d1 <- ddply(d1, c("SQL_ID"), transform, SD=sd(GETS_PER_EXEC, na.rm=TRUE))
```

We got the results, but we still have a problem: we have LOTS of unique SQLs in the data set. If we graph them all, we'll likely get a very messy (and completely useless) graph.

```R
> unique(d1$SQL_ID)
  [1] "01g33zp5h7qvb" "07ya85za8zj7u" "09ks1272pzt2c" "0bmgb5jc9hyyg" "0g949bwd9dd6s" "0gx19xyydn154" "0pvr2v9tr1k99" "0xy52965r1nd6" "0ycrgbfz8q295" "0yj833tmf0u5h"
 [11] "10bs50k618098" "115kckxrfwqw9" "18xx8rs20uxg1" "1ayy8xghu1430" "1bzp54rk42btv" "1k2k7vq63xh71" "1kzg75gcudxvz" "1na6b36tcw46w" "1wxb4a962dtcn" "1xytg8ahr0bgc"
 [21] "1zkh8d5durukc" "1zs83zmz44520" "22r50k8mdzg4k" "24b02cp32q4zc" "25h4dv9wtw4r7" "2710dnqb0kda4" "28uq1r5tr7u7a" "294san9kvyzm2" "2cfs5p8px44u0" "2cucav9fbx3cx"
 [31] "2f4tf2h3t2gh7" "2n2c38d385kdd" "2njx778ctwy0q" "2pmm4ky2qs7pj" "2rac2ub2m5cz8" "2uwuc7zhtuj9f" "302y014fj1fmg" "33y9c8z19cwh5" "348mdnqhqcf8m" "36b44f7a0z7v7"
 [41] "37g2fp87sd6wk" "37uk26ww6xtbs" "39sa30gwxt7c1" "3jng0a09awns5" "3rp0025mmu205" "3xgt00z5qsqyr" "3z9f459u4fb3u" "44zhdjb0cbj3w" "491wfpccfd1rk" "4a181f2nd9g7f"
 [51] "4g8j9tgy4rwy8" "4npw4qxadd9qw" "4ru37ngy5awxq" "4svb9snt4ncch" "4u4add52690ta" "4z4049cpptzzs" "517z3nb4qjzhw" "527w2ghgq19qh" "5n4y2j8fw14jq" "5r548gtm5c6ns"
 [61] "5s6cfw2pb4qns" "5sb1g7uyfs93p" "5vkqa7kushrtt" "601t9930kz6yc" "63b23fra5b8rx" "697j76943a320" "6a8q423fstfcr" "6an53dk7avk4p" "6cdj64z9p6c5c" "6csq3vdhxtdqw"
 [71] "6hr22a294q396" "6upq0jp68cwbt" "6zbfb1z5uvngc" "72g46f0rypu1v" "73qpa29f0bmq8" "7gpq48pasy99h" "7k0v0q9k5trs6" "7mn2c9tu3udr8" "7tfk34w3zjg8u" "7u4mac5d0q3fc"
 [81] "7v8pbt4kb3h8r" "7zqkf9fw7qm9a" "882wdd61t885w" "8ahn83nwdmgnk" "8dg45tuu98bd0" "8krcd3fss6udc" "8ntd0y8xq3xfd" "8zt912hzpns7n" "92ysb916urk3x" "93n4fsz4m9vfp"
 [91] "9at65urw3vfhj" "9cbm4x6x3m3z0" "9ru83x976jtqs" "9ugacrq1k4gy9" "9ur3c7a4b96jy" "9y7u0xn6swrnj" "a1bmdhfbhkumj" "a3mvc1fav43xx" "a4mu867n8415x" "a7ka83taw59c1"
...
```

Let's filter our data set, leaving only 8 heaviest SQLs.

First of all, convert SQL_ID to a 'factor' (our data is 'discrete' and factors make working with it easier):

```R
d1$SQL_ID <- as.factor(d1$SQL_ID)

> str(d1$SQL_ID)
 Factor w/ 322 levels "01g33zp5h7qvb",..: 1 1 1 1 1 1 1 1 1 1 ...
```

Now, let's select the first 8 SQLs by "buffer gets per exec" deviation so that are plot is not overwhelmed with data.
We will assing results to a new column: TOP_SQLS in our data frame
Notice the use of 'user defined' get_top_n() functions from 'plot.R'

```R
d1$TOP_SQLS <- get_top_n('SQL_ID', 'SD', top_n=8, data=d1)

# How many SQL_IDs are in our data set 'now' ?
levels(d1$TOP_SQLS)

[1] "tff6bbwan4jqq" "wmrpbrd8mm88a" "kts18nwzj82hk" "tvjkbtkswgjc3" "7gpq48pasy99h" "g5wp6qf3uu12p" "ddqma9ku89b00"
[8] "6cdj64z9p6c5c" "OTHERS"
```

Cool, now we only are dealing with 9 distinct SQLs and we are ready to make our first graph:

### The Boxplot

```R
ggplot(d1, aes(x=TOP_SQLS, y=GETS_PER_EXEC, fill=TOP_SQLS)) + geom_boxplot()
```

![Boxplot - SQL gets per exec](/images/lab3-boxplot-gets-per-exec.png)

Boxplot shows the data in terms of percentiles with *percentiles: 25-75* are shown as a colored box, while 'dots' show *outliers*.

Let's beatify our graph a bit.

First of all, let's reorder SQL_ID factor levels by values of GETS_PER_EXEC, so that our boxplots are displayed
in the order from the smallest to the biggest GETS_PER_EXEC.

```R
d1$TOP_SQLS <- reorder(d1$TOP_SQLS, d1$GETS_PER_EXEC, FUN=max)

# Prepare “beautified” graph:
p <- ggplot(d1, aes(x=TOP_SQLS, y=GETS_PER_EXEC, fill=TOP_SQLS)) 
p <- p +geom_boxplot() 
p <- p +scale_y_continuous(labels=comma) +theme_minimal() 
p <- p +ylab("Gets per execution") 
p <- p +ggtitle("Most wildly varying SQLs by gets/per/execution")
p <- p +coord_flip()

# And visualize
p
```

![Boxplot - SQL gets per exec / Ordered](/images/lab3-boxplot-gets-per-exec-ordered.png)

### The Violin

**Violin plot** is another cool plot to try.

It's very similar to a boxplot but also shows *"the shape"* (or: *density*) of data distribution.

To transform the latest plot to a violin plot, just replace **geom_boxplot()** with **geom_violin()**:

```R
ggplot(d1, aes(x=TOP_SQLS, y=GETS_PER_EXEC, fill=TOP_SQLS)) + geom_violin() + scale_y_continuous(labels=comma) +theme_minimal() +ylab("Gets per execution") +ggtitle("Most wildly varying SQLs by gets/per/execution") +coord_flip()
```

![Violin plot](/images/lab3-violin-plot.png)

That doesn't look like much, but let's zoom for better picture for a specific SQL:

```R
# Drop measurements with 'empty' (a.k.a: NA) data
d2 <- d1[complete.cases(d1) ,]
d2 <- d2[d2$TOP_SQLS == "OTHERS",]

p <- ggplot(d2, aes(x=TOP_SQLS, y=GETS_PER_EXEC, fill=TOP_SQLS)) + geom_violin()
p <- p + scale_y_continuous(labels=comma, limits=c(0, 2000)) 
p <- p + theme_minimal() +ylab("Gets per execution") 
p <- p +ggtitle("Buffer gets/per/execution variation for 'OTHERS'") +coord_flip()

p
```

![Violin plot Zoomed](/images/lab3-violin-plot-zoomed.png)

### Histograms and Density Curves

Violins are pretty, but in my mind a better way to explore data shape is to use histograms or density curves directly.

Hint: 

1. A **Histogram** is a bucketed raw data (a bunch of bars, each of which represents the frequency of data within that bar).
2. A **Density curve** is a mathematical approximation of data frequency distribution (histogram bars *smoothed* into a line).

Let's do some histograms:

```R
# Prepare
p <- ggplot(d1, aes(x=GETS_PER_EXEC, fill=TOP_SQLS)) + geom_histogram() 
p <- p +scale_x_continuous(labels=comma) +scale_y_continuous(labels=comma) 
p <- p +theme_minimal() + ylab('Density') +xlab('Buffer gets per execution') 
p <- p +ggtitle ('Buffer gets per execution density')
p <- p + facet_grid(TOP_SQLS ~ ., scales="free_y")

# And visualize
p
```

![Histogram](/images/lab3-histogram.png)

And density curves:

```R
# Prepare
p <- ggplot(d1, aes(x=GETS_PER_EXEC, fill=TOP_SQLS)) + geom_density() 
p <- p +scale_x_continuous(labels=comma) +scale_y_continuous(labels=comma) 
p <- p +theme_minimal() + ylab('Density') +xlab('Buffer gets per execution') 
p <- p +ggtitle ('Buffer gets per execution density')
p <- p + facet_grid(TOP_SQLS ~ ., scales="free_y")

# And visualize
p
```

![Density Curve](/images/lab3-density-curve.png)

### Make a conclusion

Finally, let's use our visualizations for SQL performance analysis.

Looking at the graphs from above, it is fairly clear that we have both: **stable SQLs** that always read the same number of blocks (i.esql_id='ddqma9ku89b00') as well as **highly unstable** ones (i.e. sql_id='tff6bbwan4jqq' has 3 separate read "peaks", which probably is related to 3 separate use cases). 

Bottom line, if you are planning to measure strict performance deviations for sql_id='tff6bbwan4jqq', it probably makes sense to separate it into 3 distinct SQLs.


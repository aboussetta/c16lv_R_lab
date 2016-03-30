# Episode 1 - Visualizing ASH

## Overview

## Style note

You may see a slightly different display style while executing ggplot examples, due to environment settings.
If you want visual style to follow the document, define these “theme elements”:

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

## Load necessary packages

```R
library(ggplot2)
library(plyr)
library(sqldf)
library(scales)
```

## Load the data

```R
d <- read.csv('data/c16lv_example_ash.csv', stringsAsFactors=F)
```

If you are interested in the actual SQL that grabbed this data from ASH tables, here it is: http://intermediatesql.com/wp-content/uploads/2014/02/rlab_get_dsh.sql_.txt 

## Clean the data

Before making a graph, you need to eyeball your data and, more often than not, clean and massage it for better graphing.

First of all, check what you have:

```R
str(d)

'data.frame':   17075 obs. of  10 variables:
 $ TS              : chr  "2013-09-01 06:39:00" "2013-09-01 03:35:00" "2013-09-01 03:31:00" "2013-09-01 03:25:00" ...
 $ WAIT_CLASS      : chr  "ON CPU" "ON CPU" "ON CPU" "ON CPU" ...
 $ EVENT           : chr  "ON CPU" "ON CPU" "ON CPU" "ON CPU" ...
 $ READ_OR_WRITE   : chr  "READ" "READ" "READ" "READ" ...
 $ BLOCKING_SESSION: chr  "" "" "" "" ...
 $ MACHINE         : chr  "app1-host" "app1-host" "app1-host" "app1-host" ...
 $ MODULE          : chr  "Module4" "Module4" "Module4" "Module4" ...
 $ IN_STAGE        : chr  "SQL EXEC" "SQL EXEC" "SQL EXEC" "SQL EXEC" ...
 $ SQL_ID          : chr  "mnyy6bt9fgmm5" "mnyy6bt9fgmm5" "mnyy6bt9fgmm5" "mnyy6bt9fgmm5" ...
 $ N               : int  1 1 1 1 1 1 6 6 6 6 ...
```

One thing to notice is that TS, although clearly a “date column” was loaded as with a “character” type. This may create problems for us when we graph, so let’s adjust its data type:

```R
# Convert to 'R date' data type
d$TS <- as.POSIXct(d$TS, "UTC")

# And now, review the data again
str(d)
```

Another problem is subtle, but nevertheless, very critical.

R likes continuous data for any “continuous” visualizations, such as time series “area graphs” or “bar graphs”.  “Continuous” in this sense means that every *category* (i.e. WAIT_CLASS) should have data points defined for all time snapshots. 

As ASH data is sampled, it might not be *continuous enough* and more often than not have “gaps” in it. 

I.e. there might have been sessions waiting for Concurrency at 23:00:00, 23:00:10 and 23:00:30, but not at 23:00:20. 
This creates **a ‘gap’** in data and gaps are bad for graphing.

If we attempt to graph the (gappy) data right now, the results will look pretty bad:

```R
ggplot(d, aes(x=TS, y=N, fill=WAIT_CLASS)) + geom_area()
```

![Gappy data](/images/lab1-gappy-data.png)

The fix for ths problem is usually to “aggregate” data broadly enough, so that ggplot becomes less confused. 

Let's do exactly that (luckily, R supports SQL!):

```R
d1 <- sqldf("select TS, WAIT_CLASS, sum(N) as N from d group by TS, WAIT_CLASS")
d1$TS <- as.POSIXct(d1$TS, "UTC")
```

Latest change (hopefully) removed gaps, so we should be able to start visualizing our data.

## Graph the data - Manually

Let’s create some basic plots:

Area graph:

```R
ggplot(d1, aes(x=TS, y=N, fill=WAIT_CLASS)) + geom_area()
```

![Wait Class by time](/images/lab1-area-wait_class.png)

Bar graph:

```R
ggplot(d1, aes(x=TS, y=N, fill=WAIT_CLASS)) + geom_bar(stat="identity")
```

![Wait Class by time - Bar](/images/lab1-bar-wait_class.png)

Line graph:

```R
ggplot(d1, aes(x=TS, y=N, color=WAIT_CLASS)) + geom_line()
```

![Wait Class by time - Line](/images/lab1-line-wait_class.png)

## Make graphs prettier

These plots are already cool :smile:, but let's make them even better.

First, let's convert WAIT_CLASS to a factor, so that we can play with label ordering

```R
d1$WAIT_CLASS <- as.factor(d1$WAIT_CLASS)
```

Reorder labels by the number of active sessions:

```R
d1$WAIT_CLASS <- reorder(d1$WAIT_CLASS, d1$N, FUN=sum)
```

And finally, create an improved graph with better colors, labels etc (notice, how we can "construct" visual elements in multiple steps and add them on together):

```R
# Prepare the graph
p <- ggplot(d1, aes(x=TS, y=N, fill=WAIT_CLASS, order=desc(WAIT_CLASS))) 
p <- p +geom_area(stat="identity") 
p <- p +xlab("Time") +ylab("Active Sessions")
p <- p +ggtitle("Active sessions by wait class") + theme_minimal() 
p <- p +scale_fill_brewer(palette="Spectral") 
p <- p +scale_y_continuous(labels=comma)

# And print it
p
```

![Wait Class by time - Prettified](/images/lab1-prettified.png)

## Plot "scripting"

Running manual visualization commands may become tedious, especially if you need to do data cleaning or other complex transformations.
Fortunately, R is a full scale scripting language, so you can automate most repetitive tasks easily.

I included a few examples in this lab to show how you can do that.

First of all, load the *source file*.

```R
source('src/plot.R')
```

and review **times()** (a.k.a. "time series") function, which we will use to plot the data:

```R
# Just show the parameters
str(times)

# Show the full code
times
```

Let’s explore the data further with **times()**.

```R
times('EVENT')
```

![EVENTs over time](/images/lab1-times-event.png)

```R
times('SQL_ID')
```

![SQL_IDs over time](/images/lab1-times-sqlid.png)

```R
times('IN_STAGE')
```

![STAGEs over time](/images/lab1-times-instage.png)

```R
times('MODULE')
```

![MODULEs over time](/images/lab1-times-module.png)

```R
times('MODULE', 'line')
```

![MODULEs over time](/images/lab1-times-module-line.png)

```R
times('BLOCKING_SESSION')
```

![MODULEs over time](/images/lab1-times-blocking-session.png)


It is clear that the problem is related to **Module1**, sessions are waiting for **SOFT PARSING**, there is no single SQL responsible and there are only a handful of blocking sessions (which is good, since we can focus on them)

I think, you agree that the problem can be seen pretty clearly now. This is very similar to Enterprise Manager does, by the way.

## Exercises

Feel free to continue exploration.

### Look at other columns in the data frame and graph them

```R
str(d)

times(another column)
```

### Try different colors

**times()** saves previous visualization in "p" variable, so you can "reuse" previous graph and add new elements on top of it:

```R
times('BLOCKING_SESSION')

p

p + scale_fill_brewer(palette="Accent")

p + scale_fill_brewer(palette="Set1")
```

You can reuse it and just add additional elements times('BLOCKING_SESSION') p + scale_fill_brewer(palette="Accent") p + scale_fill_brewer(palette="Set1")

Standard ggplot palettes can be found here: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/ 

### Try, percentage wise graphs: 

```R
times('EVENT', pct=TRUE)

times('BLOCKING_SESSION', pct=TRUE)
```

### Try facets:

With “real scales”: 

```R
# Initiate graph object
p <- ggplot(d1, aes(x=TS, y=N, fill=WAIT_CLASS, order=desc(WAIT_CLASS))) 
p <- p +geom_bar(stat="identity") 
p <- p +xlab("Time") +ylab("Active Sessions") 
p <- p +ggtitle("Active sessions by wait class") + theme_minimal() 
p <- p +scale_fill_brewer(palette="Spectral") 
p <- p +scale_y_continuous(labels=comma) 

# Check it out
p

# Add now add facets
p + facet_wrap(~ WAIT_CLASS)
```

Or, you can do it with **times()** (and 're-calibrated' scales)

```R
times('WAIT_CLASS', facet=T)
```

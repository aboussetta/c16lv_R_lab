# Episode 2 - ARCLOG Heat Maps

# Overview

**Heat maps** are quintessential **cool visualizations**. They are typically used in (i.e. load) "trend analysis" and, 
in case of ORACLE databases are great at answering questions, such as: 

*When should I schedule my backups?*

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

## Load necessary packages

```R
library(ggplot2)
library(plyr)
library(sqldf)
library(scales)
library(stringr)
```

## Get the data

```R
d <- read.csv('data/c16lv_example_arc.csv', head=T, stringsAsFactors=FALSE)
```

If you are interested in the actual SQL that grabbed this data from ORACLE, here it is: http://intermediatesql.com/wp-content/uploads/2014/02/rlab_get_arc.sql_.txt 

## Clean the data

Before making a graph, you need to eyeball your data and, more often than not, clean and massage it for better plotting.

First of all, check what you have:

```R
str(d)

'data.frame':   653 obs. of  3 variables:
 $ TS    : chr  "2013-07-30 03:00:00" "2013-07-30 04:00:00" "2013-07-30 05:00:00" "2013-07-30 06:00:00" ...
 $ N     : int  13 19 20 12 77 9 23 6 9 9 ...
 $ MBYTES: num  9741 14291 15049 9070 67061 ...
```

Let's adjust data types and clean the data:

```R
# Remove non-conforming dates
d <- d[str_length(d$TS) == 19,]

# Convert timestamp to 'R date' data type
d$TS <- as.POSIXct(d$TS, "UTC")
```

And, review the data again:

```R
str(d)

'data.frame':   653 obs. of  3 variables:
 $ TS    : POSIXct, format: "2013-07-30 03:00:00" "2013-07-30 04:00:00" ...
 $ N     : int  13 19 20 12 77 9 23 6 9 9 ...
 $ MBYTES: num  9741 14291 15049 9070 67061 ...
```

## Visualize

Let's make the simplest ARC log plot: **MBytes by Time**

```R
ggplot(d, aes(x=TS, y=MBYTES)) + geom_line()
```

![ARC Mbytes by Time](/images/lab2-mbytes-by-time.png)

That's a bit simplistic! Let's beatify our graph a bit.

I.e. we can color lines according to what day of the week it is:

```R
d$WEEKDAY <- ifelse(strftime(d$TS, "%a") %in% c('Sun', 'Sat'), 'Weekend', 'Weekday')

#Prepare the graph
p <- ggplot(d, aes(x=TS, y=MBYTES, color=WEEKDAY, group=1)) 
p <- p+ geom_line() +geom_point() 
p <- p +scale_color_manual(values=c("YellowGreen", "OrangeRed")) 
p <- p +theme_minimal() + xlab('Time') + ylab('Arclogs per hour (Mbytes)') 
p <- p +ggtitle("ARC logs by day") +theme(legend.title=element_blank())

# And show it
p
```

![ARC Mbytes by Time/Weekday](/images/lab2-mbytes-by-time-by-weekday.png)

That's better, but we are still not done. Let's convert this graph into a heat map.

```R
# Adjust the data
d$HOUR <- strftime(d$TS, "%H")
d$DAY <- strftime(d$TS, "%m-%d %a")

# Create a heat map
p <- ggplot(d, aes(x=HOUR, y=DAY, fill=MBYTES)) + geom_tile() + scale_fill_gradient(low="white", high="salmon", labels = comma) + theme_minimal() + ggtitle("ARC logs heat map")

# And show it
p
```

![ARC Mbytes Heatmap](/images/lab2-mbytes-by-time-heatmap.png)

## Exercises

Feel free to experiment further with data layouts, colors etc, i.e.

### Add colors

```R
p + scale_fill_gradient(low="yellow", high="blue", labels = comma) 
```

### Change the scale

```R
d1 <- d
d1$DAY <- strftime(d$TS, "%a")

p <- ggplot(d1, aes(x=HOUR, y=DAY, fill=MBYTES)) + geom_tile() + scale_fill_gradient(low="white", high="salmon", labels = comma) + theme_minimal() + ggtitle("ARC logs heat map")

p
```

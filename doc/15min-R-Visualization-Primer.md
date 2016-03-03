## Install R

Download and install R from http://www.r-project.org

## Install R packages

```R
install.packages("sqldf")    
install.packages("ggplot2")
install.packages("plyr")
install.packages("stringr")
install.packages("scales") 
```

## Load packages

```R
library(sqldf)
library(ggplot2)
library(plyr)
library(stringr)
library(scales) 
```

## Load C16LV R “lab” functions

```R
source('src/plot.R') 
```

## Load test data

```R 
d <- read.csv('data/c16lv_example_sqlstat.csv')
```
 
## Review data

```R
str(d)
 
'data.frame':   3216 obs. of  6 variables:
 $ TS         : chr  "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" ...
 $ SQL_ID     : chr  "0g949bwd9dd6s" "1zs83zmz44520" "72g46f0rypu1v" "7gpq48pasy99h" ...
 $ BUFFER_GETS: int  32790320 14179140 30702119 14361289 35670269 15784234 15572781 13152995 47037896 82135102 ...
 $ DISK_READS : int  0 50223 92721 14 3353016 363 21 303 0 766121 ...
 $ EXECUTIONS : int  1358884 149767 12205 411 723 635955 635225 262426 8297 2633287 ...
 $ PARSE_CALLS: int  1119212 145798 4342 163 644 12180 11131 22767 8297 15263 ...
```

## Convert types

```R
d$TS <- as.POSIXct(d$TS)
 
str(d)
'data.frame':   3216 obs. of  6 variables:
 $ TS         : POSIXct, format: "2013-08-25 07:00:00" "2013-08-25 07:00:00" ...
 $ SQL_ID     : Factor w/ 20 levels "0g949bwd9dd6s",..: 1 2 3 4 5 6 7 8 9 10 ...
 $ BUFFER_GETS: int  32790320 14179140 30702119 14361289 35670269 15784234 15572781 13152995 47037896 82135102 ...
 $ DISK_READS : int  0 50223 92721 14 3353016 363 21 303 0 766121 ...
 $ EXECUTIONS : int  1358884 149767 12205 411 723 635955 635225 262426 8297 2633287 ...
 $ PARSE_CALLS: int  1119212 145798 4342 163 644 12180 11131 22767 8297 15263
```

## Visualize disk reads over time
 
```R
ggplot(d, aes(x=TS, y=DISK_READS)) + geom_point()
```
 
## Colorize by SQL_ID
 
```R
ggplot(d, aes(x=TS, y=DISK_READS, color=SQL_ID)) + geom_point()
```
 
## Size points by the number of EXECUTIONS
 
```R
ggplot(d, aes(x=TS, y=DISK_READS, color=SQL_ID, size=EXECUTIONS)) + geom_point()
```
 
## Beautify

```R
p <- last_plot()
 
p + theme_minimal() + xlab('Time') + scale_y_continuous(labels=comma) + ggtitle('Disk read by executions') + scale_color_brewer(palette='Spectral')
```

## Try summary graphs

```R
ggplot(d, aes(x=SQL_ID, y=BUFFER_GETS/EXECUTIONS, fill=SQL_ID)) + geom_boxplot() + coord_flip()
```
 
## Try correlation graphs
 
```R
ggplot(d, aes(x=PARSE_CALLS, y=EXECUTIONS, color=SQL_ID)) + geom_point()
```
 
## Try pre-packaged graphing functions
 
```R
# times as in "time series"
times('SQL_ID', y='EXECUTIONS')
```
 
## Adjust the number of displayed categories
 
```R
times('SQL_ID', y='EXECUTIONS', top_n=2)
```
 
## Change colors
 
```R
p + scale_fill_brewer(palette='Spectral')
```
 
## Change plot type
 
```R
times('SQL_ID', y='EXECUTIONS', geom="line")
```
 
## Try "percentage" graph
 
```R
times('SQL_ID', y='EXECUTIONS', pct=TRUE)
```
 
## Add Facets
 
```R
times('SQL_ID', y='EXECUTIONS', facet=TRUE)
```
 
## Add “highlight” box

Set “highlight interval”:

```R
I_MIN <- as.POSIXct('2013-08-27 00:30:00')
I_MAX <- as.POSIXct('2013-08-27 12:30:00')
```

And, Visualize:

```R
times('SQL_ID', y='EXECUTIONS', color="yellowgreen", facet=TRUE) + hbox(color="red")
```

## Correlate to event

I.e. look for unusual spikes during “interesting” time interval.

Define “interesting” time interval:

```R 
I_MIN <- as.POSIXct('2013-08-27 23:30:00')
I_MAX <- as.POSIXct('2013-08-28 00:30:00')
```

And, Visualize:

```R
times('SQL_ID', y='DISK_READS', color="lightblue", facet=TRUE, find_spikes=T) + hbox(color="red")
```

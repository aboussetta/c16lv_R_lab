# Graphing basics

**ggplot2** is a data visualization package for R (statistical programming) language. Created by Hadley Wickham in 2005, ggplot2 is an implementation of Leland Wilkinson's Grammar of Graphics—a general scheme for data visualization which breaks up graphs into semantic components such as scales and layers.

## Executing examples:

If you want to execute examples as you go along, please, load and prepare the data and methods.

```R
library(ggplot2)
library(scales)

setwd('lab unpack location')

d <- read.csv('data/c16lv_example_sqlstat.csv')
d$TS <- as.POSIXct(d$TS)
```

The display style of examples may be slightly different than what is in this document.
If you want the style to be exactly the same, define these “theme elements”:

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

And then add them at the end of each ggplot command, i.e.:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS)) +geom_point() +mytheme
```

![Example 1](/images/example1.png)

# Basic ggplot syntax

```R
ggplot(d, aes()) +geom +”prettifications”
```

where:

| | |
| d | a “data frame” with data to graph |
|---|---|
| aes() | “Aesthetics”, or mappings of data elements to a visual plain, such as X/Y location, size, color etc |
| geom() | Plot type, such as “bar”, “area” or “line” |
| “Prettifications” | Various things that make graphs “prettier”, such as colors, scales or labels

# What is a data frame?

A **data frame** is a quintessential data container in R. It has rows and columns and, for all intents and purposes, it looks just like **a database table**.

Data frames are usually loaded from files or file like objects, such as:

```R
d <- read.csv('data/c16lv_example_sqlstat.csv')
```

They can be also “loaded” directly from databases, i.e.:

```R
library(ROracle)

odrv <- dbDriver("Oracle") 
conn <- dbConnect(odrv, user, passwd, tns)
 d <- dbGetQuery(conn, sql, binds)
```

# What is aes() or “visual aesthetics” ?

**ggplot** needs to know how to map the data from your data frame to a “visual plain” so that it can display it.
This mapping usually involves linking data frame columns to visual attributes, such as X or Y position.

I.e. if you want you graph to display BUFFER_GETS over time, the mapping function will look like:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS)) +geom_point()
```

![Example 2](/images/example2.png)

Display positions are not the only visual attributes that can be mapped.

You can also adjust color (or fill), i.e., which will create a separately colored graph for each SQL_ID in your data frame:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS, color=SQL_ID)) +geom_point()
```

![Example 3](/images/example3.png)

Adjust size of graph elements, based on, say, number of EXECUTIONS:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS, color=SQL_ID, size=EXECUTIONS)) + geom_point()
```

![Example 4](/images/example4.png)

And a few other attributes, such as line type, point shape etc

# What are geoms?

**Geoms** are, basically different graph types, such as:

* Line
* Bar
* Area
* Tile
* Histogram
* Etc

**Geoms** have a somewhat complex relationship with **aesthetics**.

On the one hand, you can usually use different geoms with the same aesthetics, to produce different graphs, i.e. here is a point graph:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS, color=SQL_ID)) + geom_point()
```

![Point graph](/images/example3.png)

And an area graph for exactly the same data:

```R
ggplot(d, aes(x=TS, y=BUFFER_GETS, fill=SQL_ID)) + geom_area()
```

![Area graph](/images/area_graph.png)

On the other hand, some geom types, require specific mappings due to the nature of the graphs.

I.e. since **histograms** are calculating data “frequencies”, they are one-dimensional by design and their **aes()** function only accepts X and not Y, i.e.:

```R
ggplot(d, aes(x=BUFFER_GETS)) + geom_histogram()
```

![Histogram](/images/histogram.png)

# Plot types

A few plot types are especially useful for performance monitoring. They are:

* Time series plots
* Summary plots
* Correlation plots

## Time series plots

**Time series** plots display changes *over time* and, at least one of their X/Y attributes is **time**, i.e.:

```R
ggplot(d, aes(x=TS, y=EXECUTIONS, color=SQL_ID)) + geom_line()
```

![Time Series Plot](/images/time_series.png)

## Summary plots

**Summary** plots display *the shape of the data* by a particular dimension.

**Histograms** are a good example, which display frequency of occurrence of, say, EXECUTIONS:

```R
ggplot(d, aes(x=EXECUTIONS)) + geom_histogram()
```

![Summary Plots: Histogram](/images/summary_histogram.png)

**Boxplot** is another good example.

```R
ggplot(d, aes(x=SQL_ID, y=EXECUTIONS, fill=SQL_ID)) + geom_boxplot()
```

![Summary Plots: Boxplot](/images/summary_boxplot.png)

## Correlation plots

**Correlation** plots explore dependencies or correlations between 2 "things" and are usually implemented as point graphs.

I.e. to see a dependency between EXECUTIONS and PARSE_CALLS, execute:

```R
ggplot(d, aes(x=PARSE_CALLS, y=EXECUTIONS, color=SQL_ID)) + geom_point()
```

![Correlation Plots](/images/correlation.png)

# Ggplot commands for different geoms

## Point

**Relevant mappings: X, Y, color, shape, size**

```R
ggplot(d, aes(x=TS, y=EXECUTIONS, color=SQL_ID)) + geom_point()
```

![Point Plot](/images/plot_point.png)

## Line

**Relevant mappings: X, Y, color, linetype**

```R
ggplot(d, aes(x=TS, y=EXECUTIONS, color=SQL_ID, linetype=SQL_ID)) + geom_line()
```

![Line Plot](/images/plot_line.png)

## Horizontal and vertical lines

**Relevant mappings: xintercept, yintercept, size, color, linetype**

```R
p <- ggplot(d, aes(x=TS, y=EXECUTIONS, color=SQL_ID, linetype=SQL_ID)) + geom_line()

p + geom_vline(xintercept=as.numeric(as.POSIXct('2013-08-29 00:00:00')), size=1, linetype=4, color='red')
```

![Vertical lines](/images/plot_vertical_line.png)

## Bar

**Important:**

1. Prefer “fill” aesthetics to “color”
2. By default, use stat=”identity”
3. Sensitive to “gaps” – might produce “intermittent white lines” with "missing" data points

**Relevant mappings: X, Y, fill**

```R
ggplot(d, aes(x=TS, y=EXECUTIONS, fill=SQL_ID)) + geom_bar(stat="identity")
```

![Bar Plot](/images/plot_bar.png)

## Area

**Important:**

1. Prefer “fill” aesthetics to “color”
2. Even more sensitive to “gaps” than bar graph

**Relevant mappings: X, Y, fill**

```R
ggplot(d, aes(x=TS, y=EXECUTIONS, fill=SQL_ID)) + geom_area()
```

![Area Plot](/images/plot_area.png)

## Tile (heatmap)

**Tile** plot is, basically, **a “heat map"**. A typical (and *cliche*) way tile plots are used is a 2-dimensional "ARC log heat map" time series graph, presented below.

**Relevant mappings: X, Y, fill**

```R
d$HOUR <- strftime(d$TS, '%H')
d$DAY <- strftime(d$TS, '%m-%d %a')

ggplot(d, aes(x=HOUR, y=DAY, fill=BUFFER_GETS)) + geom_tile() +theme_minimal() + scale_fill_gradient(low="white", high="red")
```

![Tile Plot](/images/plot_tile.png)

## Histogram

**Relevant mappings: X, fill**

```R
ggplot(d, aes(x=DISK_READS)) + geom_histogram()
```

![Histogram Plot](/images/plot_histogram.png)

## Boxplot

**Relevant mappings: X, Y, fill**

```R
ggplot(d, aes(x=SQL_ID, y=DISK_READS, fill=SQL_ID)) + geom_boxplot() + coord_flip()
```

![Boxplot](/images/plot_boxplot.png)

## Violin

**Relevant mappings: X, Y, fill**

```R
d1 <- d[d$SQL_ID %in% c('rn7hbx3xgbv0z', 'cjrrg729xjxs0'), ]
ggplot(d1, aes(x=SQL_ID, y=DISK_READS, fill=SQL_ID)) + geom_violin() +theme_minimal()
```

![Violin plot](/images/plot_violin.png)

## Facets

**Facets** allow you to break a graph apart into multiple “sub graphs”.

I.e. here is a combined plot:

```R
ggplot(d, aes(x=TS, y=DISK_READS, fill=SQL_ID)) + geom_area()
```

![Facets: Combined](/images/facets_combined.png)

And here is the same plot broken down:

```R
ggplot(d, aes(x=TS, y=DISK_READS, fill=SQL_ID)) + geom_area() + facet_wrap(~ SQL_ID)
```

![Facets: Apart](/images/facets_apart.png)

# Plot “beautifications”

## Colors

Supported by **scale_<what>_<how>()** helper functions,

Where **<what>** can be:

* size
* fill
* color
* Etc

While **<how>** is:

* manual
* discrete
* gradient
* brewer (for predefined colors)
* Etc

I.e. **scale_color_brewer()**, **scale_fill_manual()** etc

```R
ggplot(d1, aes(x=TS, y=DISK_READS, fill=SQL_ID)) + geom_area() + scale_fill_manual(values=c('grey', 'gold'))
```

![Prettifications: Colors](/images/prettyf_colors.png)

```R
ggplot(d1, aes(x=TS, y=DISK_READS, fill=SQL_ID)) + geom_area() + scale_fill_brewer(palette='Accent')
```

![Prettifications: Colors - Brewer palette](/images/prettyf_brewer.png)

Predefined “color brewer” palettes: http://www.cookbook-r.com/Graphs/Colors_(ggplot2)/#rcolorbrewer-palette-chart

## Axis labels

Defined by multiple different functions.

The most basic ones are:
* xlab() – X axis label
* ylab() – Y axis label
* ggtitle()    - Graph title

I.e.

```R
p <- ggplot(d1, aes(x=TS, y=DISK_READS, fill=SQL_ID)) + geom_area() + theme_minimal()

p +xlab('Time') +ylab('Disk reads') +ggtitle('Disk reads over time')
```

![Prettifications: Colors - Axis](/images/prettyf_axis.png)

## Themes

**Themes** are used to "group" visualization of multiple plot elements, such as “drawing panel”, borders, tick marks, labels etc

There are several predefined themes, such as:

* theme_bw()
* theme_minimal()
* theme_gray()

And you can also, modify individual theme attributes a la carte, i.e.

```R
+theme(axis.text.x=element_blank())
```

See more here: http://docs.ggplot2.org/current/theme.html

# Install and Configure R

## Install R

Download and install R from http://www.r-project.org

Then, install and load CRAN packages, i.e.:

## Install and load required 3rd party (CRAN) packages

Install:
 
```R
install.packages("sqldf")    
install.packages("ggplot2")
install.packages("plyr") 
```

Load:
 

```R
library(sqldf)
library(ggplot2)
library(plyr) 
```

## Set recommended options:
 
```R
# Do NOT convert strings to factors
options(stringsAsFactors = FALSE)
 
# Do not save row names along with data
options(row.names = FALSE)
 
# Prefer 999,999 number notation to "scientific"
options(scipen=999) 
```

## How to get help

Help for 'unique' function:

```R 
? unique
```

Help for anything that has 'unique' in its name:
 
```R 
?? unique
```

# Load and unload data

Set current directory:
 
```R
> setwd('<your root>/c16lv_R_lab')
```

Read from local CSV file:

```R 
> d <- read.csv('data/c16lv_example_sqlstat.csv')
```

Or remote CSV file over HTTP:

```R 
> d <- read.csv(' http://intermediatesql.com/wp-content/uploads/2014/02/r_example_sql_stat.csv')
```

Write to CSV:

```R 
> write.csv(d, 'out/example.csv', row.names=F)
```
 
# Explore data

Once the data is loaded into R, it is typically held in **data frames**.  

 Data frames are objects with rows and columns, where all columns have the same data type and all rows have the same exact columns.
 
If you are a database professional, for all intents and purposes, **data frames** are **tables**.

Let’s explore data in our data frame.

### Describe data frame structure:
 
```R 
> str(d)

'data.frame':   3216 obs. of  6 variables:
 $ TS         : chr  "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" ...
 $ SQL_ID     : chr  "0g949bwd9dd6s" "1zs83zmz44520" "72g46f0rypu1v" "7gpq48pasy99h" ...
 $ BUFFER_GETS: int  32790320 14179140 30702119 14361289 35670269 15784234 15572781 13152995 47037896 82135102 ...
 $ DISK_READS : int  0 50223 92721 14 3353016 363 21 303 0 766121 ...
 $ EXECUTIONS : int  1358884 149767 12205 411 723 635955 635225 262426 8297 2633287 ...
 $ PARSE_CALLS: int  1119212 145798 4342 163 644 12180 11131 22767 8297 15263 ...
```

This is similar to **sqlplus DESCRIBE** command.

### Check sizes

```R
> dim(d)

[1] 3216    6
```

That's: 17075 rows and 6 columns.

Alternatively, you can use **nrow()** and **ncol()**:

```R 
> nrow(d)
 
[1] 3216
> ncol(d)
 
[1] 6
```

### View data statistics

```R 
> summary(d)
      TS               SQL_ID           BUFFER_GETS          DISK_READS    
 Length:3216        Length:3216        Min.   :     3860   Min.   :      0 
 Class :character   Class :character   1st Qu.: 14827324   1st Qu.:      2 
 Mode  :character   Mode  :character   Median : 18653634   Median :   2715 
                                       Mean   : 27385253   Mean   : 125146 
                                       3rd Qu.: 37345358   3rd Qu.:  43186 
                                       Max.   :101812928   Max.   :5524043 
   EXECUTIONS       PARSE_CALLS    
 Min.   :     23   Min.   :      0 
 1st Qu.:   2188   1st Qu.:    551 
 Median : 233686   Median :   6608 
 Mean   : 505967   Mean   :  83117 
 3rd Qu.: 733281   3rd Qu.:  22425 
 Max.   :3318075   Max.   :1489156
```

### Eyeball the actual data

Head:

```R 
> head(d)
                   TS        SQL_ID BUFFER_GETS DISK_READS EXECUTIONS PARSE_CALLS
1 2013-08-25 07:00:00 0g949bwd9dd6s    32790320          0    1358884     1119212
2 2013-08-25 07:00:00 1zs83zmz44520    14179140      50223     149767      145798
3 2013-08-25 07:00:00 72g46f0rypu1v    30702119      92721      12205        4342
4 2013-08-25 07:00:00 7gpq48pasy99h    14361289         14        411         163
5 2013-08-25 07:00:00 8ahn83nwdmgnk    35670269    3353016        723         644
6 2013-08-25 07:00:00 93n4fsz4m9vfp    15784234        363     635955       12180
```

Tail:

```R 
> tail(d)
                      TS        SQL_ID BUFFER_GETS DISK_READS EXECUTIONS PARSE_CALLS
3211 2013-09-01 06:00:00 kts18nwzj82hk     9502851        805        770         708
3212 2013-09-01 06:00:00 r15qdw8rj30dz     6739442        135     248868      161753
3213 2013-09-01 06:00:00 rn7hbx3xgbv0z    16788150      75094     266604      102318
3214 2013-09-01 06:00:00 sfsg35rcc3zhf    52310759       9301    2059410       12332
3215 2013-09-01 06:00:00 tff6bbwan4jqq    10793053          0        637         619
3216 2013-09-01 06:00:00 wmrpbrd8mm88a     9685175          0        582         329
```

or, random sample of 10 rows (out of the first 1000):

```R 
> d[sample(1:1000, 10),]
                     TS        SQL_ID BUFFER_GETS DISK_READS EXECUTIONS PARSE_CALLS
104 2013-08-25 12:00:00 cjrrg729xjxs0    17157426       5434     783811          26
624 2013-08-26 16:00:00 7gpq48pasy99h    15084302          0        431         178
390 2013-08-26 03:00:00 rn7hbx3xgbv0z    17263826     114212     245621       85967
990 2013-08-27 11:00:00 btyy6mn9fgmm5    74853074          0      13186       13186
304 2013-08-25 23:00:00 93n4fsz4m9vfp    13924934        343     559319        7914
746 2013-08-26 22:00:00 ddqma9ku89b00    42391006      18649      74014        5059
988 2013-08-27 11:00:00 9y7u0xn6swrnj    21639111         13     887158       14118
941 2013-08-27 08:00:00 sfsg35rcc3zhf    50581063      14598    2349506       17951
27  2013-08-25 08:00:00 b1um5awusr3bk    12951105        182     253900       18122
887 2013-08-27 06:00:00 0g949bwd9dd6s    37689769          0    1561097     1298394
```

### Other useful commands

Check unique values:

```R 
> unique(d$SQL_ID)
 [1] "0g949bwd9dd6s" "1zs83zmz44520" "72g46f0rypu1v" "7gpq48pasy99h" "8ahn83nwdmgnk"
 [6] "93n4fsz4m9vfp" "9y7u0xn6swrnj" "b1um5awusr3bk" "btyy6mn9fgmm5" "c9f4g1t9cz5bv"
[11] "cjrrg729xjxs0" "ddqma9ku89b00" "gf9x09u2f9xwn" "kts18nwzj82hk" "r15qdw8rj30dz"
[16] "rn7hbx3xgbv0z" "sfsg35rcc3zhf" "tff6bbwan4jqq" "wmrpbrd8mm88a" "g5wp6qf3uu12p"
 
> length(unique(d$SQL_ID))
[1] 20
```

Break down number of records by unique values, similar to what this SQL does:  

```sql
SELECT sql_id, count(1) … GROUP BY sql_id
```

```R 
> table(d$SQL_ID)
 
0g949bwd9dd6s 1zs83zmz44520 72g46f0rypu1v 7gpq48pasy99h 8ahn83nwdmgnk 93n4fsz4m9vfp
          166           166           166           166           157           166
9y7u0xn6swrnj b1um5awusr3bk btyy6mn9fgmm5 c9f4g1t9cz5bv cjrrg729xjxs0 ddqma9ku89b00
          166           166           166           166           166           166
g5wp6qf3uu12p gf9x09u2f9xwn kts18nwzj82hk r15qdw8rj30dz rn7hbx3xgbv0z sfsg35rcc3zhf
           81           166           156           166           166           166
tff6bbwan4jqq wmrpbrd8mm88a
          166           166
```

Break continuous range into discrete buckets and check the number of records in each bucket:

```R 
> table(cut(d$DISK_READS, c(-1, 100, 1000, +Inf), c('0-100', '101-1000', '1001+' )))
 
   0-100 101-1000    1001+
    1189      324     1703
```

# Select rows and columns

## SELECT specific columns

Basic syntax:

```R
dataframe$column

i.e.:
d$TS
d$BUFFER_GETS
```

For example:
 
```R 
> head(d$TS)
[1] "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00"
[5] "2013-08-25 07:00:00" "2013-08-25 07:00:00"
```

```R 
> head(d$BUFFER_GETS)
[1] 32790320 14179140 30702119 14361289 35670269 15784234
```

## SELECT specific rows

Since R keeps data in "tables" (aka: **data frames**), you can run various “SELECT” commands to extract only the data that you are interested in.

While you can actually run SELECTs directly with **sqldf** package, it is often easier to use native R syntax to filter data frames.

### Select data by row and column “indexes”

You can select rows and columns by simply supplying their names or numbers, i.e.:
 
```R 
> d[1:2, 1:2]
                   TS        SQL_ID
1 2013-08-25 07:00:00 0g949bwd9dd6s
2 2013-08-25 07:00:00 1zs83zmz44520
```
 
or:
 
```R 
> d[c(1, 3, 5), c('SQL_ID', 'DISK_READS')]
         SQL_ID DISK_READS
1 0g949bwd9dd6s          0
3 72g46f0rypu1v      92721    
5 8ahn83nwdmgnk    3353016
```

Here is a basic syntax for your reference:

```R
dataframe[row numbers, column numbers or names]
```

R has a number of helper functions that return row numbers of "qualifying rows", i.e. :
 
```R 
> grep('08-25 09:00', d$TS)
 [1] 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57
```

You can use such functions to select only the matching rows out of the data frame, i.e.:
 
```R 
> d[grep('08-25 09:00', d$TS), ]
                    TS        SQL_ID BUFFER_GETS DISK_READS EXECUTIONS PARSE_CALLS
39 2013-08-25 09:00:00 0g949bwd9dd6s    34247187          1    1419210     1135397
40 2013-08-25 09:00:00 1zs83zmz44520    16011019      56247     171483      166755
41 2013-08-25 09:00:00 72g46f0rypu1v    35012230      64988      14003        4700
42 2013-08-25 09:00:00 7gpq48pasy99h    14617830          0        421         165
43 2013-08-25 09:00:00 8ahn83nwdmgnk      297271      27025        180         161
44 2013-08-25 09:00:00 93n4fsz4m9vfp    18105974        314     724136        8460
45 2013-08-25 09:00:00 9y7u0xn6swrnj    17334925          4     709025        7779
46 2013-08-25 09:00:00 b1um5awusr3bk    13088568        210     242144       20206
47 2013-08-25 09:00:00 btyy6mn9fgmm5    54938992          0       9688        9688
48 2013-08-25 09:00:00 c9f4g1t9cz5bv    76068631     702803    2592594       11541
49 2013-08-25 09:00:00 cjrrg729xjxs0    16845406       7874     769131          20
50 2013-08-25 09:00:00 ddqma9ku89b00    32882227       5791      72081        5108
51 2013-08-25 09:00:00 gf9x09u2f9xwn    16116878      13611     694909          20
52 2013-08-25 09:00:00 kts18nwzj82hk    17833152        497       1220        1074
53 2013-08-25 09:00:00 r15qdw8rj30dz    16881065          2     687497      391844
54 2013-08-25 09:00:00 rn7hbx3xgbv0z    23166426     135721     335240      112651
55 2013-08-25 09:00:00 sfsg35rcc3zhf    63241332       6355    2537803       11641
56 2013-08-25 09:00:00 tff6bbwan4jqq    36095411          2        719         708
57 2013-08-25 09:00:00 wmrpbrd8mm88a    28879093          0        578         316
```

### Select data by logical conditions

An alternative way to select rows out of the data frame is to supply a boolean vector with TRUE/FALSE values for each row. Filter expression will then only select the rows with TRUE value.

Basic syntax:

```R
dataframe[Vector with TRUE/FALSE for ALL rows, ]
```

Creating such vectors for R data frames is very easy. Since R "vectorizes" all operations and all R columns are "vectors", all that you need to do is create a *logical condition* involving data frame column (or multiple columns).

I.e. let's create a logical vector that marks rows as TRUE if d$SQL_ID == "0g949bwd9dd6s"
 
```R
> head(d$SQL_ID == "0g949bwd9dd6s")
[1]  TRUE FALSE FALSE FALSE FALSE FALSE
```

We can then use it as a row filter for our data frame:

```R
> str(d[d$SQL_ID == "0g949bwd9dd6s",])
'data.frame':   166 obs. of  6 variables:
 $ TS         : chr  "2013-08-25 07:00:00" "2013-08-25 08:00:00" "2013-08-25 09:00:00" "2013-08-25 10:00:00" ...
 $ SQL_ID     : chr  "0g949bwd9dd6s" "0g949bwd9dd6s" "0g949bwd9dd6s" "0g949bwd9dd6s" ...
 $ BUFFER_GETS: int  32790320 31893963 34247187 36099615 32186129 32827368 31351898 31720772 33245323 31658243 ...
 $ DISK_READS : int  0 0 1 1 1 1 0 0 0 0 ...
 $ EXECUTIONS : int  1358884 1321622 1419210 1496018 1333627 1360047 1298919 1314241 1377501 1311668 ...
 $ PARSE_CALLS: int  1119212 1068094 1135397 1261070 1082267 1116737 1043372 1079851 1119664
```

Filter expressions can use multiple logical conditions with **and: &**, **or: |** or **not: !**:

```R
> str(d[d$SQL_ID == "0g949bwd9dd6s" & d$DISK_READS > 1000,])
'data.frame':   6 obs. of  6 variables:
 $ TS         : POSIXct, format: "2013-08-28 00:00:00" "2013-08-29 15:00:00" "2013-08-29 16:00:00" "2013-08-29 18:00:00" ...
 $ SQL_ID     : Factor w/ 20 levels "0g949bwd9dd6s",..: 1 1 1 1 1 1
 $ BUFFER_GETS: int  32810828 16112730 16078292 7438690 11941736 16914554
 $ DISK_READS : int  35556 1080 1383 2381 2448 4122
 $ EXECUTIONS : int  1359651 667323 665864 308125 494615 702230
 $ PARSE_CALLS: int  1153568 570025 555658 200153 398419 609287
```

You can also test for set membership (i.e. WHERE column IN (...)):

```R 
> str(d[d$SQL_ID %in% c("0g949bwd9dd6s", "1zs83zmz44520"),])
'data.frame':   332 obs. of  6 variables:
 $ TS         : chr  "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 08:00:00" "2013-08-25 08:00:00" ...
 $ SQL_ID     : chr  "0g949bwd9dd6s" "1zs83zmz44520" "0g949bwd9dd6s" "1zs83zmz44520" ...
 $ BUFFER_GETS: int  32790320 14179140 31893963 14851582 34247187 16011019 36099615 16756115 32186129 16296850 ...
 $ DISK_READS : int  0 50223 0 54501 1 56247 1 57684 1 56629 ...
 $ EXECUTIONS : int  1358884 149767 1321622 159262 1419210 171483 1496018 179338 1333627 174307 ...
 $ PARSE_CALLS: int  1119212 145798 1068094 154977 1135397 166755 1261070 174300 1082267 1694
```

## Selecting data by SQL

Finally, you can simply use SQL to select data with **sqldf** package (thanks, Google!).

```R 
> library(sqldf)
 
> dd <- sqldf("select SQL_ID, sum(DISK_READS) as DISK_READS from d group by SQL_ID order by DISK_READS desc limit 5")
> dd
         SQL_ID DISK_READS
1 8ahn83nwdmgnk  226899445
2 c9f4g1t9cz5bv  114362097
3 rn7hbx3xgbv0z   20563160
4 72g46f0rypu1v   12999354
5 1zs83zmz44520    9844173
```

# R data types and type conversions

## Basic R data types

In general, "basic" R data types should look familiar to you. I.e. R recognizes numbers, strings and dates, although you should probably familiarize yourself with their "R" names.

Data types can be determined by class() command, i.e.:

```R 
> class(1)
[1] "numeric"
 
> class('1')
[1] "character"
 
> class(TRUE)
[1] "logical"
```

Each data type usually provides **as.<type>()** function for type conversion and **is.<type>()** function to determine if value is of this type.

i.e.:

```R 
> a <- as.character(1)
> a
[1] "1"
 
> b <- as.numeric('22')
> b
[1] 22
> is.numeric(b)
[1] TRUE
```

The notable exception from this rule are date/time types, i.e.: **Date** or **POSIXct**, which have as.() functions, but not is.():

```R 
> a <- as.Date('2011-01-01')
> a <- as.Date('2011-01-51')
Error in charToDate(x) :
  character string is not in a standard unambiguous format
> is.Date('2011-01-51')
Error: could not find function "is.Date"
```

A few basic R data types are represented in the table below:

| Data type | R data type name | Examples | Comments |
|---|---|---|---|
| Integers | integer | 1, 100 | Might not *fit* large numbers - use 'numeric' instead |
| (Floating point) numbers | numeric | 1, 100.45 | Can 'support' both 'integers' and 'floating point numbers' |
| Character strings | character | 'READ' | |
| (**R special**) "Character strings with predefined set of values" aka: Factors | factor | 'READ', levels: {'READ', 'WRITE'} | Represent 'categorical' data |
| Dates | Date | as.Date('2011-01-01') | No is.Date() |
| Timestamps | POSIXct | as.POSIXct('2011-01-01 03:00:00') | No is.POSIXct() |

Keep in mind, this type list is not exhaustive, there are more basic types, plus you can also create your own types.
But it probably covers everything you can expect while dealing with data visualizations.

One interesting thing about R is that all data types are "vectors". I.e. even basic data types,
such as "character" or "numeric", which in other languages are considered "scalar"
(or "single values"), are "one element vectors" in R.

This leads to some interesting language behavior:

```R 
> 1
[1] 1
 
> 1[1]
[1] 1
 
> is.vector(1)
[1] TRUE
```

All R operations expect "vectors" as operands, which simplifies many operations, i.e.:

```R 
> a <- sample(1:10)
> a
 [1]  9  7  1  2  4  6  8  5  3 10
> b <- sample(1:10)
> b
 [1]  9 10  2  6  1  4  8  3  5  7
> a+b
 [1] 18 17  3  8  5 10 16  8  8 17
```

or:

```R 
> d$PARSE_CALLS_PER_EXEC <- d$PARSE_CALLS / d$EXECUTIONS
 
> str(d)
'data.frame':   3216 obs. of  7 variables:
 $ TS                  : chr  "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" "2013-08-25 07:00:00" ...
 $ SQL_ID              : chr  "0g949bwd9dd6s" "1zs83zmz44520" "72g46f0rypu1v" "7gpq48pasy99h" ...
 $ BUFFER_GETS         : int  32790320 14179140 30702119 14361289 35670269 15784234 15572781 13152995 47037896 82135102 ...
 $ DISK_READS          : int  0 50223 92721 14 3353016 363 21 303 0 766121 ...
 $ EXECUTIONS          : int  1358884 149767 12205 411 723 635955 635225 262426 8297 2633287 ...
 $ PARSE_CALLS         : int  1119212 145798 4342 163 644 12180 11131 22767 8297 15263 ...
 $ PARSE_CALLS_PER_EXEC: num  0.824 0.973 0.356 0.397 0.891 ...
```

## Representing "empty" data

R recognizes 2 "special" cases for empty data.

1. **NULL**, which is reserved for **undefined** data (i.e. we do not know what data value is)
2. **NA**, which describes **missing** data (i.e. we do not have a value)

This is different from a database world, where you typically only have **NULLs**, but this distinction is important
for statistical analysis (for which R was originally designed).  

Practically speaking, NULLs are simply ignored during calculations, i.e.:

```R 
> data.nulls <- c(1, 2, 3, 4, NULL, 5)
> sum(data.nulls)
[1] 15
```

While NAs stop calculations cold and require special handling.

I.e. **sum(data_that_contains_NA)** is always: **NA**:

```R 
> data.nas <- c(1, 2, 3, 4, NA, 5)
> sum(data.nas)
[1] NA
```

You have to exclude NAs to get the results:

```R 
> sum(data.nas[! is.na(data.nas)])
[1] 15
```

R has a number of helpful functions (or function parameters) that can either discard NULLs/NAs from your data or, at least, chck for them.

I.e.:

```R
is.null(v)
is.na(d$TS)
complete.cases(d) # Only select data frame rows where all columns are defined
```

## Factors

**Factor** is special basic data types in R that describes discrete or categorical data.

Long story short, factors are character strings with the added twist that they only allow specific set of values that are predefined in advance.

A couple of things to remember about factors.

1. Factor keeps a list of 'allowed' values that are called **levels**.
 
```R 
> d[1,]$SQL_ID
[1] 0g949bwd9dd6s
20 Levels: 0g949bwd9dd6s 1zs83zmz44520 72g46f0rypu1v ... wmrpbrd8mm88a
```

In addition to storing level names, factors also remember some basic data statistics, such as the number of values for each level:
 
```R 
> summary(d$SQL_ID)
0g949bwd9dd6s 1zs83zmz44520 72g46f0rypu1v 7gpq48pasy99h 8ahn83nwdmgnk
          165           166           166           166           157
93n4fsz4m9vfp 9y7u0xn6swrnj b1um5awusr3bk btyy6mn9fgmm5 c9f4g1t9cz5bv
          166           166           166           166           166
cjrrg729xjxs0 ddqma9ku89b00 g5wp6qf3uu12p gf9x09u2f9xwn kts18nwzj82hk
          166           166            81           166           156
r15qdw8rj30dz rn7hbx3xgbv0z sfsg35rcc3zhf tff6bbwan4jqq wmrpbrd8mm88a
          166           166           166           166           166
         NA's
            1
```

Compare to characters:
 
```R 
> summary(as.character(d$SQL_ID))
   Length     Class      Mode
     3216 character character
```

Factor levels can be ordered by values:
 
```R 
> levels(d$SQL_ID)
 [1] "0g949bwd9dd6s" "1zs83zmz44520" "72g46f0rypu1v" "7gpq48pasy99h"
 [5] "8ahn83nwdmgnk" "93n4fsz4m9vfp" "9y7u0xn6swrnj" "b1um5awusr3bk"
 [9] "btyy6mn9fgmm5" "c9f4g1t9cz5bv" "cjrrg729xjxs0" "ddqma9ku89b00"
[13] "g5wp6qf3uu12p" "gf9x09u2f9xwn" "kts18nwzj82hk" "r15qdw8rj30dz"
[17] "rn7hbx3xgbv0z" "sfsg35rcc3zhf" "tff6bbwan4jqq" "wmrpbrd8mm88a"
 
> d$SQL_ID <- reorder(d$SQL_ID, d$DISK_READS)
> levels(d$SQL_ID)
 [1] "wmrpbrd8mm88a" "btyy6mn9fgmm5" "9y7u0xn6swrnj" "g5wp6qf3uu12p"
 [5] "0g949bwd9dd6s" "r15qdw8rj30dz" "tff6bbwan4jqq" "b1um5awusr3bk"
 [9] "7gpq48pasy99h" "93n4fsz4m9vfp" "cjrrg729xjxs0" "sfsg35rcc3zhf"
[13] "ddqma9ku89b00" "kts18nwzj82hk" "gf9x09u2f9xwn" "1zs83zmz44520"
[17] "72g46f0rypu1v" "rn7hbx3xgbv0z" "c9f4g1t9cz5bv" "8ahn83nwdmgnk"
```

This, in particular, allows to order category labels in plots and makes for nicer graphs.

# How to modify data in R

The quintessential R command is an assignment operator, which looks like:

```R
<-
```

i.e.:

```R
a <- 1
```

You can also use "traditional" **=** assignment operator:

```R
a = 1
```

 But, let’s be honest, it does not look as cool :smile:
 
The important thing to remember is that R operations are vectorized, that is, operations are applied to each element of a vector. 

  I.e., this command:

```R
  d$DISK_READS <- d$DISK_READS / 2
```

will divide each individual value of DISK_READS column by 2.

## How to copy or save data

### Copy (save) the entire data frame:
 
```R 
> d1 <- d
```

Or only a single column:
 
```R  
> buffer_gets <- d$BUFFER_GETS
```

Despite its simplicity, this is one of the most useful commands for data exploration.

Make a practice to always save the data before changing it, so that you have an easy rollback.

## How do delete a column
 
```R 
> d$LOGICAL_READS <- NULL
```

## Other simple data modifications
 
```R 
> d$BUFFER_GETS_PER_EXEC <- d$BUFFER_GETS/d$EXECUTIONS
 
> d$BUFFER_GETS_PCT <- round(d$BUFFER_GETS/sum(as.numeric(d$BUFFER_GETS))*100, 2)
 
> d$DISK_READS_CATEGORY <- ifelse(d$DISK_READS >= 1000, 'LARGE', 'SMALL')
```

## "Analytic" functions

**ddply** command in **plyr** package allows to run commands on R data frames that are similar to ORACLE analytic functions, such as:

```sql
 sum(...) over (partition by ...)
```

I.e.:

```R 
> library(plyr)

> d1 <- ddply(d, c('SQL_ID'), transform, SUM_BGETS=sum(as.numeric(BUFFER_GETS)))
> str(d1)
'data.frame':   3216 obs. of  8 variables:
 $ TS                  : Factor w/ 166 levels "2013-08-25 07:00:00",..: 1 2 3 4 5 6 7 8 9 10 ...
 $ SQL_ID              : Factor w/ 20 levels "wmrpbrd8mm88a",..: 1 1 1 1 1 1 1 1 1 1
 $ BUFFER_GETS         : int  28287755 28635589 28879093 29370124 28768218 29111154 28463498 28537860 28560731 27855981 ...
 $ DISK_READS          : int  0 1 0 0 0 1 0 0 0 0 ...
 $ EXECUTIONS          : int  567 572 578 586 575 572 573 569 573 559 ...
 $ PARSE_CALLS         : int  294 306 316 344 323 334 325 328 329 321 ...
 $ BUFFER_GETS_PER_EXEC: num  49890 50062 49964 50120 50032 ...
 $ SUM_BGETS           : num  4.6e+09 4.6e+09 4.6e+09 4.6e+09 4.6e+09 ...
```

## User defined functions

One of the main benefits of R is that it is a full-fledged language and you can script and automate most repetitive operations.

For example, one of the biggest problems with data visualizations is dealing with “noise”. I.e. visualizing a data frame with a lot of
distinct categories can easily make the plot unreadable.

This UDF function solves the “cluttering” problem by only keeping the top N "most relevant" categories and re-categorizing everything else as ‘OTHERS’:

```R 
top_n <- function(group_by, obs, top_n=5, data=d) {
   # Re-categorize 'category' in data frame by limiting the # of distinct categories
   # I.e. re-categorize 'SQL_ID' by 'DISK_READS'
   # Essentially,
   #   1. Order categories by sum('obs')
   #   2. Keep original names for top 'top_n' categories
   #   3. Re-categorize everything else as 'OTHERS'
 
   # Find top categories
   sql <- sprintf('select %s, sum(%s) as S from data group by %s order by S desc limit %d',
     group_by, obs, group_by, top_n)
   top_cats <- sqldf(sql)
   top_cats <- as.character(top_cats[[group_by]])
 
   # Re-categorize with 'OTHERS'
   categories <- as.character(data[[group_by]])
   top_n_cats <- ifelse(categories %in% top_cats, categories, 'OTHERS')
 
   # Convert category to factor
   data [[group_by]] <- factor(top_n_cats)
   data [[group_by]] <- reorder(data [[group_by]], data [[obs]])
 
   return(data)
}
```

Here is how we would use it.

Our original data: 

```R
> summary(d$SQL_ID)
0g949bwd9dd6s 1zs83zmz44520 72g46f0rypu1v 7gpq48pasy99h 8ahn83nwdmgnk
          166           166           166           166           157
93n4fsz4m9vfp 9y7u0xn6swrnj b1um5awusr3bk btyy6mn9fgmm5 c9f4g1t9cz5bv
          166           166           166           166           166
cjrrg729xjxs0 ddqma9ku89b00 g5wp6qf3uu12p gf9x09u2f9xwn kts18nwzj82hk
          166           166            81           166           156
r15qdw8rj30dz rn7hbx3xgbv0z sfsg35rcc3zhf tff6bbwan4jqq wmrpbrd8mm88a
          166           166           166           166           166
```

And modified data after running top_n() function:
 
```R 
> d2 <- top_n('SQL_ID', 'DISK_READS', top_n=5)
 
> summary(d2$SQL_ID)
       OTHERS cjrrg729xjxs0 0g949bwd9dd6s sfsg35rcc3zhf c9f4g1t9cz5bv
         2552           166           166           166           166
```

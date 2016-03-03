require("methods", quietly=TRUE)
require("proto", quietly=TRUE)
require("sqldf", quietly=TRUE)
require("plyr", quietly=TRUE)
require("scales", quietly=TRUE)
require("ggplot2", quietly=TRUE)
require("RColorBrewer", quietly=TRUE)

# ####################################################################
# Global variables
# ####################################################################

# d <- NULL   # Default IN data frame
# dd <- NULL  # Default OUT data frame
# ds <- NULL  # Spike data frame
# p <- NULL   # Default plot
# pf <- NULL   # Default facetized plot

# I_MIN <- NULL # Default "highlight" min time
# I_MAX <- NULL # Default "highlight" max time

# Default image folder and name
DEF_IMG_FOLDER <- "/tmp/p"
DEF_IMG_NAME <- "default"

# DPI
DEF_DPI <- 120

# Color Brewer palette
DEF_PALETTE <- "RdYlBu"

# Default plot size by X (cm)
DEF_SIZE_X <- 36
# Default plot size by Y (cm)
DEF_SIZE_Y <- 16
# Plot size vars
SIZE_X <- NULL
SIZE_Y <- NULL

# Verbose mode
VERBOSE <- F

# if var is NULL, replace it with substitution
nvl <- function(var, subst) { return(ifelse(is.null(var), subst, var)) }

# Check if x is a POSIXct date
is.POSIXct <- function(x) inherits(x, "POSIXct")

# ####################################################################
# Transformation functions
# ####################################################################

# ***************************************************************************************
# Categorize data based on TOP observations and
# TOP_N observation categories will remain "named", while the rest is categorized as 'OTHERS'
#
# Returns: vector/factor for TOP_N categories
# ***************************************************************************************
get_top_n <- function(group_by, obs, top_n=8, data=d) {

  # Validate incoming parameters
  if(!all(c(group_by, obs) %in% names(data))) {
    print(sprintf("%s, %s columns need to exist in data frame", group_by, obs))
    stop(str(data))
  }
  if(! is.character(data[[group_by]]) && ! is.factor(data[[group_by]])) {
    stop(sprintf("GROUP BY column: %s needs to be character or factor", group_by))
  }
  if(! is.numeric(data[[obs]])) {
    stop(sprintf("Observation column: %s needs to be numeric", obs))
  }

  if(is.factor(data[[group_by]])) { data[[group_by]] <- as.character(data[[group_by]] ) }

  # Find top-N items
  sql <- sprintf("select %s, sum(%s) as sn from data where length(%s) > 0 group by %s order by sn desc limit %d",
    group_by, obs, group_by, group_by, top_n)
  top_items <- sqldf(sql)

  # Convert from data.frame to vector
  top_items <- factor(top_items[[group_by]], 
    levels=top_items[order(top_items$sn, decreasing=T), group_by]) 

  # Replace non "top-n" categories with 'OTHERS'
  regular_cats <- data[[group_by]]
  top_n_cats <- sapply(regular_cats, function(j) ifelse(j %in% levels(top_items), j, 'OTHERS'))

  # Sort by (top-n) values with 'OTHERS' always 1st and make into a factor
  top_n_cats <- factor(top_n_cats, levels=c(levels(top_items), 'OTHERS'), ordered=T)

  return(top_n_cats)
}

# ***************************************************************************************
# Categorize data based on TOP observations and
# TOP_N observation categories will remain "named", while the rest is categorized as 'OTHERS'
#
# Returns: data frame with 'group_by' column replaced by top_n
# ***************************************************************************************
mod_top_n <- function(group_by, obs, top_n=8, data=d) {
  data[[group_by]] <- get_top_n(group_by=group_by, obs=obs, top_n=top_n, data=data)

  return(data)
}

# ***************************************************************************************
# Categorize data based on TOP observations and
# TOP_N observation categories will remain "named", while the rest is categorized as 'OTHERS'
#
# Returns: data frame with TOP_N column added
# ***************************************************************************************
add_top_n <- function(group_by, obs, top_n=8, data=d) {
  data$TOP_N <- get_top_n(group_by=group_by, obs=obs, top_n=top_n, data=data)

  return(data)
}

# ***************************************************************************************
# Find "spike score" - how different is the data within (x_min, x_max) interval comparing to overall interval
#
# Returns vector of: {GROUP_BY, score}
# ***************************************************************************************
find_spikes <- function(group_by, time_col='TS', obs='N', xmi=I_MIN, xma=I_MAX, ignore_sign=T, data=d) {
  # Validate incoming parameters
  # If xmi or xma are not set, return NULL
  if(is.null(xmi) || is.null(xma)) {
    print(sprintf("Either xmi or xma are undefined. Returning NULL"))
    return(NULL)
  }
  
  if(!all(c(time_col, group_by, obs) %in% names(data))) {
    print(sprintf("%s, %s columns need to exist in data frame", group_by, obs))
    stop(str(data))
  }
  if(! is.character(data[[group_by]]) && ! is.factor(data[[group_by]])) {
    stop(sprintf("GROUP BY column: %s needs to be character or factor", group_by))
  }
  if(! is.numeric(data[[obs]])) {
    stop(sprintf("Observation column: %s needs to be numeric", obs))
  }
  if(! is.POSIXct(data[[time_col]])) {
    stop(sprintf("Time column: %s needs to be POSIXct", time_col))
  }
  if(!all(is.POSIXct(c(xmi, xma)))) {
    stop(sprintf("xmi and xma need to be both POSIXct"))
  }
  if(xmi < min(data[[time_col]]) || xma > max(data[[time_col]])) {
    stop(sprintf("(xmi: %s, xma: %s) time interval needs to be within: %s, %s for: %s column", xmi, xma, min(data[[time_col]]), 
	  max(data[[time_col]]), time_col))
  }
  
  # Calculate "mean" and "stddev" for the entire time interval
  sql <- sprintf('select %s, avg(%s) as M, stdev(%s) as SD from data where %s NOT between $xmi and $xma group by %s', group_by, obs, obs, time_col, group_by)
  d_all <- fn$sqldf(sql)

  # Calculate "mean" and "stddev" for the "interest" time interval
  sql <- sprintf("select %s, avg(%s) as SM from data where %s between $xmi and $xma group by %s", group_by, obs, time_col, group_by)
  d_int <- fn$sqldf(sql)

  # Find resulting "spike scores", calculated as: mean(d_all)-mean(d_int)/stdev(d_all)
  sql <- sprintf("select a.%s, a.M, a.SD, b.SM, (b.SM-a.M)/a.SD as Z from d_all a join d_int b on a.%s = b.%s", group_by, group_by, group_by)
  d_comb <- sqldf(sql)
  assign("ds", d_comb, envir = .GlobalEnv)

  # Re-order original data frame by "spike rate" and embed SR into category name
  order_f <- ifelse(ignore_sign, 'abs(Z)', 'Z')
  sql <- sprintf("select d.%s, d.%s||' ['||round(%s, 2)||']' as %s, d.%s, round(a.Z, 2) as Z from data d join d_comb a on d.%s = a.%s order by %s desc", time_col, group_by, 'a.Z', group_by, obs, group_by, group_by, order_f)
  data <- sqldf(sql)
  data [[group_by]] <- factor(data[[group_by]])
  data [[group_by]] <- reorder(data[[group_by]], -1*data$Z)

  return(data)
}

# ***************************************************************************************
# Add PCT column based on "obs" variable: obs/sum(obs)*100 for each value of "group_by"
#
# Returns: data frame with PCT column added
# ***************************************************************************************
add_pct <- function(group_by, obs, data=d) {
  # Validate incoming parameters
  if(!all(c(group_by, obs) %in% names(data))) {
    print(sprintf("%s, %s columns need to exist in data frame", group_by, obs))
    stop(str(data))
  }
  if(! is.numeric(data[[obs]])) {
    stop(sprintf("Observation column: %s needs to be numeric", obs))
  }

  data <- ddply(data, group_by, 
    .fun=function(x, obs) transform(x, PCT=get(obs)/sum(get(obs))*100), obs=obs)

  return(data)
}

# ***************************************************************************************
# Add PCT column based on "obs" variable: obs/sum(obs)*100 for each value of "group_by"
#
# Returns: data frame with obs column replaced with PCT data
# ***************************************************************************************
mod_pct <- function(group_by, obs, data=d) {
  data <- add_pct(group_by=group_by, obs=obs, data=data)
  data[[obs]] <- data$PCT
  data$PCT <- NULL

  return(data)
}

# ***************************************************************************************
# Divide a list of columns by a column and return resulting list of "_PER_"+divisor columns
# Typical example: For ('GETS', 'READS', 'ROWS') and 'EXECUTION'
# return ('GETS_PER_EXECUTION', 'READS_PER_EXECUTION', 'ROWS_PER_EXECUTION')
#
# Returns: data frame with only divided columns
# ***************************************************************************************
get_div_by <- function(div_by, col_list=names(data), data=d) {
  div_data <- NULL

  # Validate incoming parameters
  all_cols  <- c(col_list, div_by)
  if(!all(all_cols %in% names(data))) {
    missing_cols <- all_cols[which(! all_cols %in% names(data))]
    print(sprintf("%s column(s) need to exist in data frame", missing_cols))
    stop(str(data))
  }
  if(! is.numeric(data[[div_by]])) {
    stop(sprintf("Divisor column: %s needs to be numeric", div_by))
  }

  # Extract names of all numeric columns, excluding div_by
  num_cols <- names(data[sapply(colnames(data),
    function(x) x %in% col_list && x != div_by && is.numeric(data[,x]))])

  if (length(num_cols) > 0) {
    div_data <- data[, div_by, drop=F]

    for(x in num_cols) {
      div_data[[paste(x, '_PER_', div_by, sep="")]] <- data[[x]] / data[[div_by]]
    }
  } else {
    print("No data qualified for division")
  }

  return(div_data)
}

# ***************************************************************************************
# Divide a list of columns by a column and return resulting list of "_PER_"+divisor columns
# Typical example: For ('GETS', 'READS', 'ROWS') and 'EXECUTION'
# return ('GETS_PER_EXECUTION', 'READS_PER_EXECUTION', 'ROWS_PER_EXECUTION')
#
# Returns: data frame with additional "divided" columns
# ***************************************************************************************
add_div_by <- function(div_by, col_list=names(data), data=d) {
  data <- cbind(data, get_div_by(div_by=div_by, col_list=col_list, data=data))

  return(data)
}

# **************************************************************
# Fill missing data
# For every unique value in "base_col":
#   For every unique "level" in "dimension_col"
#     If base_col/level combination does not exist
#       Create and assign 0 to "obs" column
#
# Typical use case: Clean "area" graphs by making sure that all "timestamps"
# have values for all factor levels
#
# Returns "the same" data frame with missing data points filled
# **************************************************************
fill_missing_categories <- function(base_col, dimension_col, obs='N', data=d) {
  unique_base <- unique(data[[base_col]])
  unique_dim <- unique(data[[dimension_col]])

  new_data <- data.frame(expand.grid(unique_base, unique_dim))
  names(new_data) <- c(base_col, dimension_col)

  new_data <- merge(data, new_data, by=c(base_col, dimension_col), all.y=T)
  if(nrow(new_data[is.na(new_data[[obs]]),]) > 0) {
    new_data[is.na(new_data[[obs]]),][[obs]] <- 0
  }

  return(new_data)
}

# ***************************************************************************************
# When we know that a particulal column is a TS (and its format)
# Clean TS columns and convert them to timestamp (POSIXct)
# ***************************************************************************************
clean_ts_columns <- function(l_ts, expected='\\d\\d\\d\\d-\\d\\d-\\d\\d', orig_tz="UTC",
  to_tz="America/Los_Angeles", data=d) {
  for (c in l_ts) {
    data <- data[grepl('\\d\\d\\d\\d-\\d\\d-\\d\\d', data[[c]]),]
    data[[c]] <- as.POSIXct(format(as.POSIXct(data[[c]], tz=orig_tz), tz=to_tz, usetz=T))
  }

  return(data)
}

# **************************************************************
# Drop empty categories
# "Empty" = all "obs_col" for data$cat_col are either NAs or 0s)
# **************************************************************
drop_empty_categories <- function(cat_col, obs_col, data=d) {
  empty_categories <- character()

  if(! is.factor(data[[cat_col]])) {data[[cat_col]] <- factor(data[[cat_col]]) }

  for(l in levels(data[[cat_col]])) {
    ds <- data[data[[cat_col]] == l,]
    if(0 == nrow(ds) || all(ds[[obs_col]] == 0)) {
      if(VERBOSE) { print(paste("Dropping empty category", l)); }
      empty_categories <- c(empty_categories, l)
    }
  }

  if(0 == length(empty_categories)) {
    ret <- data
  } else {
    ret <- data[! data[[cat_col]] %in% empty_categories,]
    ret[[cat_col]] <- droplevels(ret[[cat_col]])
  }

  return(ret)
}

# ####################################################################
# Visualization functions
# ####################################################################

# **************************************************************
# Prepare exploration: Define categories, set plot type etc
# **************************************************************
prepare_exploration <- function(fill, y, x, pct, to_ts, top_n, orig_tz, to_tz, agg_f, drop_empty, find_spikes, xmi, xma, ignore_spike_sign, data) {

  data <- subset(data, select=c(x, y, fill))
  data <- mod_top_n(group_by=fill, obs=y, top_n=top_n, data=data)
  data <- fill_missing_categories(base_col=x, dimension_col=fill, obs=y, data=data)

  agg_f <- ifelse("avg" == agg_f, "mean", agg_f)

  # Summarize data (group by: x, fill)
  data <- ddply(data, c(x, fill), 
    .fun = function(x, agg_f, y) summarise(x, TMP = get(agg_f)(x[,y])), agg_f=agg_f, y=y)
  names(data) <- c(x, fill, y)
  if (pct) {
    data <- mod_pct(group_by=x, obs=y, data=data);
  }
  
  if(drop_empty) {
    data <- drop_empty_categories(cat_col=fill, obs_col=y, data=data)
  }
  
  if(find_spikes) {
    data <- find_spikes(group_by=fill, time_col=x, obs=y, xmi=xmi, xma=xma, ignore_sign=ignore_spike_sign, data=data)
  }	
    
  data <- clean_ts_columns(l_ts=to_ts, orig_tz=orig_tz, to_tz=to_tz, data=data)
   
  assign("dd", data, envir = .GlobalEnv)

  return(data)
}

# **************************************************************
# Get a list of colors from either RColorBrewer palette or supplied colors
#
# Returns (potentially repeated) vector of colors of size 'size'
# **************************************************************
get_colors <- function(color, size) {
  suppressWarnings(my_colors <- tryCatch({ brewer.pal(n=90, color) }, error=function(e) {return(NULL)}))

  # If not a ColorBrewer palette, it must be direct colors
  if(is.null(my_colors)) { my_colors <- color }

  ret_colors <- rep_len(my_colors, size)

  return(ret_colors)
}

# **************************************************************
# Prepare "minimal" theme
# **************************************************************
theme_min <- function() {
  local_p <- theme_minimal()
  local_p <- local_p + theme(axis.title.x = element_blank(),
                             axis.title.y = element_blank(),
                             axis.text.x  = element_text(angle=45, vjust=0.5)
                            )

  return(local_p)
}

# **************************************************************
# Produce time series graph X=time, Y="observation" Fill="dimension"
# **************************************************************
times <- function (
  fill,                            # Dimension ("fill/color") column
  geom="area",                     # Geom
  x="TS",                          # X axis column
  y="N",                           # Y axis column
  pct=FALSE,                       # Whether to produce pct-wise plot
  facet=FALSE,                     # Whether to facetize ("break apart" by "fill") 
  to_ts=x,                         # List of columns to convert to POSIXct
  orig_tz="UTC",                   # Convert time from this timezone
  to_tz="America/Los_Angeles",     # To this timezone
  top_n=8,                         # Number of categories to display (rest is categorized as: 'OTHERS')
  color=NULL,                      # Color name (or palette name)
  drop_empty=TRUE,                 # Drop empty categories
  title=NULL,                      # Plot title
  guides=T,                        # Whether to display guides
  agg_f="sum",                     # Aggregate function
  find_spikes=F,                     # Whether to find spikes in data
  xmi=I_MIN,                      # Min time for spike interval
  xma=I_MAX,                     # Max time for spike interval
  ignore_spike_sign=T,       # Whether to order spikes by "absolute" value
  data=d                           # Source data frame
) {
  .e <- environment()

  if(!is.data.frame(d)) {
    stop('Data frame required')
  }

  geom <- tolower(geom)
  geom_f <- paste("geom_", geom, sep="")

  if(is.null(x)) { x <- names(data[1]); } # X is 1st column by default
  if(is.null(y)) { y <- names(data[2]); } # Y is 2nd column by default
  if(is.null(fill)) { fill <- names(data[3]); } # Fill is 3rd column by default
  if(is.null(to_ts)) { to_ts <- x; } # "timestamp" column is X by default (this is "time series" after all")

  data <- prepare_exploration(fill=fill, y=y, x=x, pct=pct, to_ts=to_ts, top_n=top_n,
    orig_tz=orig_tz, to_tz=to_tz, agg_f=agg_f, drop_empty=drop_empty,
    find_spikes=find_spikes, xmi=xmi, xma=xma, ignore_spike_sign=ignore_spike_sign,
	data=data)

  levs <- levels(data[[fill]])
  if(VERBOSE) {
    print("Creating time series graph")
    print(summary(data))
    print(levs)
  }

  if(geom %in% c('bar', 'area')) {
    local_p <- ggplot(data, aes(x=get(x), y=get(y), fill=get(fill)), environment=.e)
  } else {
    local_p <- ggplot(data, aes(x=get(x), y=get(y), color=get(fill)), environment=.e)
  }
  local_p <- local_p + get(geom_f)(stat="identity")
  if("line" == geom) {
    local_p <- local_p + geom_point()
  }
  local_p <- local_p + ggtitle(title)
  local_p <- local_p + theme_min()
  local_p <- local_p + scale_x_datetime()
  local_p <- local_p + scale_y_continuous(labels=comma)

  my_colors <- get_colors(nvl(color, DEF_PALETTE), length(levs))
  if ("line" == geom) {
    local_p <- local_p + scale_color_manual(values=my_colors)
  } else {
    local_p <- local_p + scale_fill_manual(values=my_colors)
  }
  if(guides) {
    if(geom %in% c("line", "point")) {
      local_p <- local_p + guides(color=guide_legend(title=fill, reverse=F))
    } else {
      local_p <- local_p + guides(fill=guide_legend(title=fill, reverse=T))
    }
  } else {
    local_p <- local_p + guides(fill=FALSE)
  }

  if(facet) {
    local_p <- facetize(facet_by=fill, plot=local_p)
  } else {
    # Calculate plot size
    SIZE_X <- DEF_SIZE_X
    SIZE_Y <- DEF_SIZE_Y
  }

  assign("p", local_p, envir = .GlobalEnv)
  assign("SIZE_X", SIZE_X, envir = .GlobalEnv)
  assign("SIZE_Y", SIZE_Y, envir = .GlobalEnv)

  return(local_p)
}

# **************************************************************
# Produce time series "box"
# X=time (i.e. hour), Y=time (i.e. day of week) Fill="observation"
# **************************************************************
timebox <- function (
  x="TS",                          # "Timestamp" column
  y="N",                           # "Observation" column
  orig_tz="UTC",                   # Convert time from this timezone
  to_tz="America/Los_Angeles",     # To this timezone
  color="salmon",                  # Color name (or palette name)
  drop_empty=TRUE,                 # Drop empty categories
  title=NULL,                      # Plot title
  agg_f="sum",                     # Aggregate function
  data=d                           # Source data frame
) {
  x_format="%H"                   # X axis format ("Hours" by default)
  y_format="%a"                   # Y axis format ("Days" by default)
    .e <- environment()

  if(!is.data.frame(d)) {
    stop('Data frame required')
  }

  if(is.null(x)) { x <- names(data[1]); } # X is 1st column by default
  if(is.null(y)) { y <- names(data[2]); } # Y is 2nd column by default

  # Prepare exploration for timebox
  data <- subset(data, select=c(x, y))
  agg_f <- ifelse("avg" == agg_f, "mean", agg_f)
  # Summarize data (group by: x)
  data <- ddply(data, c(x),
    .fun = function(x, agg_f, y) summarise(x, TMP = get(agg_f)(x[,y])), agg_f=agg_f, y=y)
  names(data) <- c(x, y)
  data <- clean_ts_columns(l_ts=x, orig_tz=orig_tz, to_tz=to_tz, data=data)

  # Create x/y formatted timebox
  data$XF <- strftime(data[[x]], x_format, tz=to_tz)
  data$YF <- factor(strftime(data[[x]], y_format, tz=to_tz), levels=rev(c('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')))
  assign("dd", data, envir = .GlobalEnv)

  if(VERBOSE) {
    print(sprintf("Creating timebox graph: %s by %s", x_format, y_format))
    print(summary(data))
  }

  local_p <- ggplot(data, aes(x=XF, y=YF, fill=get(y)), environment=.e) + geom_tile()
  local_p <- local_p + ggtitle(title)
  local_p <- local_p + theme_min()
  local_p <- local_p + scale_fill_gradient(low="white", high=color, labels = comma) 
  local_p <- local_p + guides(fill=guide_legend(title=y))

  # Calculate plot size
  SIZE_X <- DEF_SIZE_X
  SIZE_Y <- DEF_SIZE_Y

  assign("p", local_p, envir = .GlobalEnv)
  assign("SIZE_X", SIZE_X, envir = .GlobalEnv)
  assign("SIZE_Y", SIZE_Y, envir = .GlobalEnv)

  return(local_p)
}

# **************************************************************
# Break data into Facets
# **************************************************************
facetize <- function(facet_by=NULL, plot=p, ncol=4, scales="free") {
  .e <- environment()

  if(VERBOSE) {
    print(sprintf("Breaking into facets by: %s", facet_by))
  }

  if(! facet_by %in% names(dd)) {
    print(sprintf("%s column needs to exist in data frame 'dd'", facet_by))
    stop(str(dd))
  }
  if(! is.factor(dd[[facet_by]])) {
    print(sprintf("dd$%s column needs to be a factor", facet_by))
    stop(str(dd))
  }

  local_p <- plot
  local_p <- local_p + theme(legend.position="none")
  local_p <- local_p + theme(strip.text.y = element_text(angle=0),
    axis.text.x = element_text(angle=45), strip.background = element_rect(fill="#87CEEB"))
  local_p <- local_p + facet_wrap(as.formula(paste("~", facet_by)), ncol=ncol, scales=scales)

  # Recalculate plot size
  SIZE_X <- DEF_SIZE_X
  SIZE_Y <- (as.integer(length(levels(dd[[facet_by]]))/ncol)+1) * (DEF_SIZE_Y/2)

  assign("pf", local_p, envir = .GlobalEnv)
  assign("SIZE_X", SIZE_X, envir = .GlobalEnv)
  assign("SIZE_Y", SIZE_Y, envir = .GlobalEnv)

  return(local_p)
}

# **************************************************************
# Create highlight box on time series X scale
# **************************************************************
hbox <- function(xmi=I_MIN, xma=I_MAX, color="red", plot=p) {
  if(VERBOSE) {
    print(sprintf("Adding time box min=%s, max=%s", xmi, xma))
  }

  local_p <- annotate("rect", xmin=xmi, xmax=xma, ymin=-Inf, ymax=Inf, fill=color, alpha=.2)

  return(local_p)
}

# **************************************************************
# Save *last* graph locally
# **************************************************************
save_local <- function(name=DEF_IMG_NAME, plot=last_plot(), type='png', dir=DEF_IMG_FOLDER, dpi=DEF_DPI) {
  file_name=paste(dir, "/", name, ".", type, sep="")

  # Create directory if it does not exist
  dir.create(dir, showWarnings = FALSE)

  # Then save file in specified format
  if(type %in% c("png", "jpeg")) {
    ggsave(file_name, plot=plot, dpi=dpi, width=SIZE_X, height=SIZE_Y, units="cm", limitsize=F)
  } else if ("pdf" == type) {
    ggsave(file_name, plot=plot, width=SIZE_X, height=SIZE_Y, units="cm", limitsize=F)
  } else {
    stop(paste("Unsupported file format: ", type))
  }

  if(VERBOSE) { print(sprintf("Saved as: %s Size: %d:%d cm", file_name, SIZE_X, SIZE_Y)); }

  return(file_name)
}

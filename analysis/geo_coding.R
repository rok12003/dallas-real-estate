### Pulling Geo Data & Joining ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
library(tsibble)
library(lubridate)

## Spatial imports:
library(tidycensus)
library(tigris)

# Data Pulling & Wrangling:
## Loading in dataframes from ts analysis:
load("data/processed_dfs/validation_data.RData")
dallas_ts <- readRDS("data/processed_dfs/dallas_ts.rds")

## Personal Census API key:
census_api_key(Sys.getenv("CENSUS_API_KEY"))

## Downloading TIGER/Line shapefiles for Dallas zips:
dallas_shape_files <- zctas(
  cb = FALSE
  
  ### I know this is stupid, but 2010 is literally the only year where
  ### shapefiles for Dallas, TX are avail:
  , year = '2010'
  , state = "TX")

## Filter out zips that aren't relevant:
### Dallas zips:
dallas_zips <- as.character(unique(dallas_ts$RegionName))

### Filtering shape file:
dallas_shape_files <- dallas_shape_files |> 
  filter(ZCTA5CE10 %in% unique(dallas_ts$RegionName))

## The JOINS!
### Thinning out the df(s):
dallas_ts_skinny <- dallas_ts |> 
  select(RegionName, Date, Price) |> 
  mutate(Date = as.Date(yearmonth(Date), frac = 0))

validation_df_skinny <- validation_df |>
  select(-Price, -diff) |>
  mutate(Date = as.Date(yearmonth(Date), frac = 0))

### Combining b/c fuck it we ball:
combined_ts <- bind_rows(dallas_ts_skinny, validation_df_skinny)

### The Big Gameeee:
shiny_df <- dallas_shape_files |>
  left_join(combined_ts, by = c("ZCTA5CE10" = "RegionName"))

## Save as an df for later use:
save(shiny_df, file = "data/processed_dfs/shiny_df.RData")

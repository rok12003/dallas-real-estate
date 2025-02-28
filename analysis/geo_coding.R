### Pulling Geo Data & Joining ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
library(tsibble)
library(lubridate)

## Gotta go fast:
library(data.table)
library(arrow)

## Spatial imports:
library(tidycensus)
library(tigris)
library(sf)

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

### Thinning it out:
shiny_df <- shiny_df |>
  select(ZCTA5CE10, Date, Price, .mean, geometry)

### We gotta optimize so we don't crash the cloud:
#### Rounding numeric cols:
shiny_df <- shiny_df |>
  mutate(across(where(is.numeric), ~round(., 0)))

#### Converting zip codes to a factor to save memory:
shiny_df <- shiny_df |>
  mutate(ZCTA5CE10 = as.factor(ZCTA5CE10))

### Simplifying geometries:
shiny_df <- shiny_df %>%
  st_simplify(dTolerance = 50)

### Saving as an RDS file:
saveRDS(shiny_df, "interactive_map/shiny_df.rds", compress = "xz")

### Pulling Geo Data ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
library(tsibble)
library(lubridate)
library(arrow)

## Spatial imports:
library(tidycensus)
library(tigris)
library(sf)

# Data Pulling & Wrangling:
## Loading in dallas data:
dallas <- readRDS("data/processed_dfs/dallas_with_forecast.rds")

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
dallas_zips <- unique(dallas$RegionName)

### Filtering shape file:
dallas_shape_files <- dallas_shape_files |> 
  filter(ZCTA5CE10 %in% unique(dallas$RegionName))

## The JOINS!
### Converting from year-month format:
dallas <- dallas |>
  mutate(Date = as.Date(yearmonth(Date), frac = 0))

### The Big Gameeee:
shiny_df <- dallas_shape_files |>
  left_join(dallas, by = c("ZCTA5CE10" = "RegionName"))

### Thinning it out:
shiny_df <- shiny_df |>
  select(ZCTA5CE10, Date, Price, geometry) |>
  mutate(Price = round(Price, 0))

### We gotta optimize so we don't crash the cloud:
### Simplifying geometries:
shiny_df <- shiny_df |>
  st_simplify(dTolerance = 50)

### Creating Regional Average df:
regional_avg <- shiny_df |>
  group_by(Date) |>
  summarise(Price = mean(Price, na.rm = TRUE), .groups = "drop")

### Rounding price in regional df:
regional_avg <- regional_avg |>
  mutate(Price = round(Price, 0))

### Saving as an RDS file:
saveRDS(shiny_df, "interactive_map/shiny_df.rds", compress = "xz")
saveRDS(regional_avg, "interactive_map/regional_avg.rds", compress = "xz")

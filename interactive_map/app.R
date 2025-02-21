### Shiny App ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
libary(ggplot2)

## Shiny imports:
library(shiny)
library(bslib)

## Spatial imports:
library(tidycensus)
library(tigris)
library(tmap)
library(sf)

## Loading in dataframes from ts analysis:
load("data/validation_data.RData")
dallas_ts <- readRDS("data/dallas_ts.rds")

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

### Filtering:
dallas_shape_files <- dallas_shape_files |> 
  filter(ZCTA5CE10 %in% dallas_zips)





# ui.R
# server.R
# Bringing it all together
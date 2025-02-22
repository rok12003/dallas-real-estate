### Shiny App ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)
library(ggplot2)

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
  filter(ZCTA5CE10 %in% unique(dallas_ts$RegionName))

# Data Viz Time
## Creating base tmap Dallas Map to work with:
tmap_mode("view") +
  tm_basemap("OpenStreetMap") +
  tm_shape(dallas_shape_files) +
  
  ### Formatting & data stuff:
  tm_polygons(
    alpha = 0.5,
    palette = "viridis",
    border.col = "navy",
    border.alpha = 0.5, 
    id = "ZCTA5CE10",
    popup.vars = c(
      "Zip Code" = "ZCTA5CE10"
    )
  ) +
  
  ### Layout:
  tm_layout(
    title = "Single-Family Home Prices by Zip Code in the Dallas-Ft. Worth MSA",
    title.position = c("center", "center")
  ) +
  
  ### Setting the view & zoom:
  tm_view(
    set.view = c(-96.8, 32.8, 8),
    set.zoom.limits = c(7, 13)
  )




# ui.R
# server.R
# Bringing it all together
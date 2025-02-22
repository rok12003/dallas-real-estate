### Shiny App ###

# Setting things up:
## General imports:
library(tidyverse)
library(dplyr)

## Shiny imports:
library(shiny)
library(bslib)

## Viz imports:
library(ggplot2)
library(tmap)
library(sf)

## Loading in our beautiful dataset:
load("data/shiny_df.RData")

# ui.R

# server.R
# Bringing it all together

# Data Viz Time
## Creating base tmap Dallas Map to work with:
tmap_mode("view") +
  tm_basemap("OpenStreetMap") +
  tm_shape(dallas_spatial_with_prices) +
  
  ### Formatting & data stuff:
  tm_polygons(
    col = "Price",
    palette = "inferno",
    alpha = 0.5,
    border.col = "black",
    border.alpha = 0.5,
    title = "Housing Prices ($)",
    style = "jenks",
    n = 8,
    popup.vars = c(
      "Zip Code" = "ZCTA5CE10",
      "Average Price" = "Price"
    )
  ) +
  
  ### Layout:
  tm_layout(
    title = "Single-Family Home Prices by Zip Code in the Dallas-Ft. Worth MSA",
    title.position = c("center", "top")
  ) +
  
  ### Setting the view & zoom:
  tm_view(
    set.view = c(-96.8, 32.8, 8),
    set.zoom.limits = c(7, 13)
  )

# Setting things up:
## Importing libraries:
library(tidyverse)
library(tidygeocoder)
library(tmap)
library(sf)

## Set working directory:
setwd("/Users/rohitkandala/Desktop/archive/random_shit/tx_nanna")

# Importing data:
## USA Housing Data from Zillow:
housing_data <- read_csv("data/zillow_data.csv")

## Filtering to Dallas MSA:
dallas_housing <- housing_data |>
  filter(Metro == "Dallas-Fort Worth-Arlington, TX")

# Data Manipulation:
## Housing Data:
### Pivoting Zillow file long:
dallas_housing_long <- dallas_housing |>
  pivot_longer(
    cols = starts_with("20"),
    names_to = "Date",
    values_to = "Price"
  )

### Converting 'date' column to Date format;
dallas_housing_long$date <- as.Date(dallas_housing_long$Date
                                    , format = "%Y-%m-%d")

### Only taking most recent valuation:
most_recent_date <- max(dallas_housing_long$date)
dallas_housing_long <- dallas_housing_long |> 
  filter(date == most_recent_date) |>
  filter(grepl("^\\d{5}$", Zip))

## Zip Code Nonsense:
### Filtering to only have Zip, City, and Price in housing data:
dallas_housing_skim <- dallas_housing_long |>
  select(RegionName, City, Price)

### Getting coordinates by zip code: 
dallas_housing_geocoded <- dallas_housing_skim |>
  mutate(FullAddress = paste0(RegionName, ", USA")) |>
  geocode(address = FullAddress, method = "osm", lat = latitude, long = longitude, 
          min_time = 0.5)

### Filtering out where there's nulls in rows:
dallas_housing_geocoded <- na.omit(dallas_housing_geocoded)

### Converting to spatial object:
dallas_housing_spatial <- dallas_housing_geocoded |> 
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# Data Viz:
tmap_mode("view") + 
  tm_basemap("OpenStreetMap") + 
  tm_shape(dallas_housing_spatial) + 
  tm_symbols(
    col = "Price", 
    palette = "YlGnBu", 
    style = "quantile", 
    breaks = quantile(dallas_housing_spatial$Price, probs = 0:7 / 7), 
    size = 0.5, 
    shape = 21, 
    border.lwd = 1, 
    border.col = "black", 
    popup.vars = c(
      "Zip Code" = "RegionName", 
      "City" = "City",
      "Price" = "Price"
    )
  )

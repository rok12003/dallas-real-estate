### Time Series Analysis ###

# Setting things up:
## Library imports:
### General imports:
library(tidyverse)
library(dplyr)

### Time Series imports:
library(tsibble)
library(lubridate)
library(fable)
library(zoo)
library(feasts)

## Importing dataset:
## USA Housing Data from Zillow:
housing_data <- read_csv("data/initial_data/zillow_data_december_update.csv")

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
dallas_housing_long$Date <- as.Date(paste0(
  dallas_housing_long$Date, "-01"), format = "%Y-%m-%d")

### Just taking the last five years of data starting w/ Jan 2020:
dallas_housing_long_five <- dallas_housing_long |>
  filter(Date > '2019-12-31' & Date <= '2024-11-30')

### Saving dallas housing df(s) as csvs for later use:
if (!file.exists("data/dallas_csvs/dallas_housing.csv")) write.csv(
  dallas_housing, "data/dallas_csvs/dallas_housing.csv", row.names = FALSE)  
if (!file.exists("data/dallas_csvs/dallas_housing_long.csv")) write.csv(
  dallas_housing_long, "data/dallas_csvs/dallas_housing_long.csv", row.names = FALSE)
if (!file.exists("data/dallas_csvs/dallas_housing_long_five.csv")) write.csv(
  dallas_housing_long, "data/dallas_csvs/dallas_housing_long_five.csv", row.names = FALSE)  

# Time Series Fun:
## Creating a time series object for each zip code for each price point
dallas_ts <- dallas_housing_long_five |> 
  mutate(Date = yearmonth(Date)) |>  
  as_tsibble(index = Date, key = RegionName)  

## We have two missing price points so filling those in:
dallas_ts <- dallas_ts |>
  group_by(RegionName) |>
  mutate(Price = na.approx(Price, na.rm = FALSE)) |>
  ungroup()

## Thinning out dallas_ts for the vars we need:
dallas_ts <- dallas_ts |>
  select(RegionName, Date, Price)

# ARIMA modeling:
## Fitting a simple ARIMA model onto the ts object:
arima_model <- dallas_ts |>
  model(ARIMA(Price))

## Forecast the next 12 months:
dallas_forecast_simple <- arima_model |> 
  forecast(h = "12 months")
  
## Pruning the dallas_forecast object:
dallas_forecast_simple <- dallas_forecast_simple |>
  as_tibble() |>
  select(-.model, -Price) |>
  
  ### I'm renaming here b/c it'll help with the join:
  rename(Price = .mean) 

## Converting dallas_ts to tibble:
dallas_tibble <- dallas_ts |>
  as_tibble()
  
## Joining the forecast to the existing dataframe:
dallas_with_forecast <- bind_rows(dallas_tibble, dallas_forecast_simple)

# Saving objects for geographical matching file:
saveRDS(dallas_with_forecast, "data/processed_dfs/dallas_with_forecast.rds")

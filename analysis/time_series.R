# Setting things up:
## Importing libraries:
library(tidyverse)

## Importing dataset:
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

### Saving dallas housing df(s) as csvs for later use:
write.csv(dallas_housing, "data/dallas_housing.csv")
write.csv(dallas_housing_long, "data/dallas_housing_long.csv")




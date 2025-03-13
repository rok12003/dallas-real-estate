### Looking at Zip(s) ###

# Setting things up:
## Library imports:
### General imports:
library(tidyverse)
library(dplyr)
library(scales)
library(lubridate)
library(knitr)

### Viz:
library(ggplot2)
library(gganimate)
library(magick)

### Creating a vector of northern area zips a 30 min drive from Frisco center:
northern_zips <- c("75033", "75034", "75035", "75036", "75056", "75057"
                         , "75065", "75067", "75068", "75069", "75070", "75071"
                         , "75072", "75074", "75075", "75078", "75080", "75081"
                         , "75082", "75093", "75094", "76208", "76210", "76227"
                         , "75028", "75032", "75001", "75002", "75006", "75007"
                         , "75010", "75013", "75023", "75252", "75254")

### Loading in our production data w/o heavy geom columns:
shiny_df <- readRDS("interactive_map/shiny_df.rds") |>
  select(-geometry)
shiny_df_northern <- shiny_df |>
  filter(ZCTA5CE10 %in% northern_zips)

regional_avg <- readRDS("interactive_map/regional_avg.rds") |>
  select(-geometry) |>
  as_tibble()

# Price Distribution:
## Histograms of Price Ranges by Bin:
### Dallas MSA Animated Histogram:
dallas_hist <- ggplot(data = shiny_df, aes(x = Price)) +
  geom_histogram(binwidth = 50000, fill = "blue", alpha = 0.7, color = "black") +
  
  #### Mean for each grouping:
  geom_vline(data = shiny_df |> 
               group_by(Date) |> 
               summarise(MeanPrice = mean(Price, na.rm = TRUE), .groups = "drop"),
             aes(xintercept = MeanPrice), 
             color = "red", linetype = "dashed", linewidth = 1) +
  labs(title = "House Price Distribution: {closest_state}", x = "Price", y = "Frequency") +
  theme_minimal() +
  scale_x_continuous(labels = scales::comma) +
  transition_states(factor(Date, ordered = TRUE), transition_length = 1
                    , state_length = 1)

### Making it into a gif:
anim <- animate(dallas_hist, renderer = magick_renderer(), fps = 2, duration = 20
                , width = 800, height = 600)
anim_save("pngs/dallas_hist.gif", animation = anim)

### Northern Suburbs Histogram:
dallas_hist_north <- ggplot(data = shiny_df_northern, aes(x = Price)) +
  geom_histogram(binwidth = 50000, fill = "blue", alpha = 0.7, color = "black") +
  
  #### Mean for each grouping:
  geom_vline(data = shiny_df_northern |> 
               group_by(Date) |> 
               summarise(MeanPrice = mean(Price, na.rm = TRUE), .groups = "drop"),
             aes(xintercept = MeanPrice), 
             color = "red", linetype = "dashed", linewidth = 1) +
  labs(title = "House Price Distribution: {closest_state}", x = "Price", y = "Frequency") +
  theme_minimal() +
  scale_x_continuous(labels = scales::comma) +
  transition_states(factor(Date, ordered = TRUE), transition_length = 1
                    , state_length = 1)

### Making it into a gif:
anim <- animate(dallas_hist_north, renderer = magick_renderer(), fps = 2
                , duration = 20, width = 800, height = 600)
anim_save("pngs/dallas_hist_north.gif", animation = anim)

# High growth vs. low-growth areas:
## Function that creates a table measuring Growth/Loss 2020 vs. 2022 vs. 2024:
big_movers <- function(data, growth = TRUE, number, sort_by) {
  
  ### Extracting year from Date and summarizing:
  annual_avg <- data |> 
    mutate(
      Year = year(Date),
      Month = month(Date)
    ) |> 
    filter((Year == 2020 & Month == 1) | (Year == 2022 & Month == 1) | (Year == 2024 & Month == 11)) |> 
    group_by(ZCTA5CE10, Year) |> 
    summarise(AveragePrice = mean(Price, na.rm = TRUE), .groups = "drop") |> 
    arrange(ZCTA5CE10, Year)
  
  ### Calculate change from 2020 to 2024:
  change_table <- annual_avg |> 
    pivot_wider(names_from = Year, values_from = AveragePrice) |> 
    filter(!is.na(`2020`) & !is.na(`2022`) & !is.na(`2024`)) |> 
    mutate(
      Change_2020_to_2022 = ((`2022` - `2020`) / `2020`) * 100,
      Change_2022_to_2024 = ((`2024` - `2022`) / `2022`) * 100,
      Change_2020_to_2024 = ((`2024` - `2020`) / `2020`) * 100
    ) |> 
    select(ZCTA5CE10, `2020`, `2022`, `2024`, Change_2020_to_2022
           , Change_2022_to_2024, Change_2020_to_2024)
  
  ### Sorting based on the growth parameter:
  if (growth) {
    
    #### Positive growth:
    change_table <- change_table |>  
      arrange(desc(.data[[sort_by]])) |>  
      head(number)
    
  } else {
    #### Negative growth:
    change_table <- change_table |>  
      arrange(.data[[sort_by]]) |>  
      head(number)
  }
  
  ### Returning whatever table:
  return(kable(change_table, 
               format = "markdown", 
               col.names = c("ZIP Code", "Price (2020)", "Price (2022)", "Price (2024)", 
                             "Change 2020-2022 (%)", "Change 2022-2024 (%)", "Change 2020-2024 (%)"),
               digits = 2))
}

### Dallas MSA YOY Top 10 High Growth Zips:
big_movers(shiny_df, growth = TRUE, 10, "Change_2020_to_2024")
big_movers(shiny_df, growth = TRUE, 10, "Change_2022_to_2024")

### Dallas MSA YOY Top 10 Low Growth Zips:
big_movers(shiny_df, growth = FALSE, 10, "Change_2020_to_2024")
big_movers(shiny_df, growth = FALSE, 10, "Change_2022_to_2024")

### Northern Suburbs YOY Top 10 High Growth Zips:
big_movers(shiny_df_northern, growth = TRUE, 10, "Change_2020_to_2024")
big_movers(shiny_df_northern, growth = TRUE, 10, "Change_2022_to_2024")

### Northern Suburbs MSA YOY Top 10 High Growth Zips:
big_movers(shiny_df_northern, growth = FALSE, 10, "Change_2020_to_2024")
big_movers(shiny_df_northern, growth = FALSE, 10, "Change_2022_to_2024")

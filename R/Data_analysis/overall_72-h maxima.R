library(data.table)
library(dplyr)
library(purrr)
library(ggplot2)

# List of station IDs
station_ids <- c(41049, 41044, 41047, 41043)

# Base directory containing subdirectories for each station
base_directory_path <- "Desktop"

# Function to calculate 72-hour maxima
calculate_maxima <- function(data, period_hours) {
  data %>%
    arrange(datetime) %>%
    mutate(period_start = as.POSIXct(floor(as.numeric(difftime(datetime, min(datetime), units = "hours")) / period_hours) * period_hours * 3600, origin = min(datetime))) %>%
    group_by(period_start) %>%
    summarize(max_WVHT = max(WVHT, na.rm = TRUE), .groups = 'drop')
}

# Function to process individual files
process_data_file <- function(file_path) {
  data <- fread(file_path)
  setnames(data, "#YY", "YY")
  
  data[, datetime := as.POSIXct(paste(YY, MM, DD, hh, mm), format = "%Y %m %d %H %M")]
  data <- data[!is.na(datetime), ]
  data[, WVHT := as.numeric(WVHT)]
  data <- data[!is.na(WVHT) & WVHT != 99.00, ]
  
  calculate_maxima(data, 72)
}

# Loop through each station ID
for (station_id in station_ids) {
  directory_path <- file.path(base_directory_path, paste0("#", station_id))  # Construct the path to the directory
  
  # List all files for processing
  file_paths <- list.files(directory_path, pattern = "\\.txt$", full.names = TRUE)
  
  # Process all files for the station and combine results
  all_maxima <- map_df(file_paths, process_data_file)
  
  # Transform the combined data
  data_transformed <- all_maxima %>%
    mutate(period_start = as.Date(period_start)) %>%
    rename(max_WHT = max_WVHT) %>%
    select(period_start, max_WHT)
  
  # Save the combined results to a CSV file
  output_filename <- file.path(paste("data_", station_id, ".csv", sep = ""))
  write.csv(data_transformed, file = output_filename, row.names = FALSE)
  
  print(paste("Data processed and saved for station", station_id))
}


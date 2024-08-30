# Load necessary libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(purrr)

# Define the directory containing your files
directory_path <- "Desktop/#41049"  

# List all files for processing
file_paths <- list.files(directory_path, pattern = "\\.txt$", full.names = TRUE)

# Function to calculate 72-hour maxima
calculate_maxima <- function(data, period_hours) {
  data <- data %>%
    arrange(datetime) %>%
    mutate(period_start = as.POSIXct(floor(as.numeric(difftime(datetime, min(datetime), units = "hours")) / period_hours) * period_hours * 3600, origin = min(datetime))) %>%
    group_by(period_start) %>%
    summarize(max_WVHT = max(WVHT, na.rm = TRUE)) %>%
    ungroup()
  return(data)
}

# Function to process individual files
process_data_file <- function(file_path) {
  # Load the data
  data <- fread(file_path)
  setnames(data, "#YY", "YY")
  
  # Assuming the data includes datetime and WVHT columns correctly formatted
  data[, datetime := as.POSIXct(paste(YY, MM, DD, hh, mm), format = "%Y %m %d %H %M")]
  data <- data[!is.na(datetime), ]
  data[, WVHT := as.numeric(WVHT)]
  
  # Remove unwanted data points
  data <- data[!is.na(WVHT) & WVHT != 99.00, ]
  
  # Calculate and return 72-hour maxima
  return(calculate_maxima(data, 72))
}

# Process all files and combine results
all_maxima <- map_df(file_paths, process_data_file)

# Transform the combined data
data_transformed <- all_maxima %>%
  mutate(period_start = as.Date(period_start)) %>%
  rename(max_WHT = max_WVHT) %>%  # Rename max_WVHT to max_WHT for consistency
  select(period_start, max_WHT)

# Print the resulting data frame
print(data_transformed)

# Assuming your dataframe is named `data_transformed`
# Convert period_start to numeric values (as days since the first date)
data_transformed$period_start_numeric <- as.numeric(as.Date(data_transformed$period_start))

# Normalize the period_start_numeric column
min_date <- min(data_transformed$period_start_numeric)
max_date <- max(data_transformed$period_start_numeric)

data_transformed$scaled_time <- (data_transformed$period_start_numeric - min_date) / (max_date - min_date) * 10

# Remove the temporary numeric column
data_transformed <- data_transformed %>% select(-period_start_numeric)


# Optionally, save the combined results to a CSV file
write.csv(data_transformed, file = "combined_data.csv", row.names = FALSE)

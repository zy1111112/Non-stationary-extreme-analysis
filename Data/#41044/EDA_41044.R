# Loading necessary libraries
library(data.table)
library(dplyr)
library(ggplot2)
library(purrr)

# Define the directory containing your files
directory_path <- "#41044"  

# List all files for processing
file_paths <- list.files(directory_path, pattern = "\\.txt$", full.names = TRUE)
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
  
  # Return processed data
  return(data)
}

# Process each file and store the results
results_list <- lapply(file_paths, process_data_file)

# Combine all yearly results into one data.table
combined_results <- rbindlist(results_list)

origional_data_41044 <- combined_results

# Plot for Station 41044
plot(origional_data_41044$datetime, origional_data_41044$WVHT, type = "l", col = "green", 
     xlab = "Year", ylab = "Wave Height (WVHT)", 
     main = "Station 41044")





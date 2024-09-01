library(WaveletComp)
library(dplyr)
library(zoo)
library(ggplot2)

# This is for Station 41049, change the file for different stations
# Load data
my.data <- read.csv("data_41049.csv")

# Convert 'period_start' to POSIXct
my.data$period_start <- as.POSIXct(my.data$period_start)


# Calculate lag-1 autocorrelation
lag_1_acf <- acf(my.data$max_WHT, plot = FALSE)$acf[2]
print(lag_1_acf)

# Run the wavelet analysis
result <- analyze.wavelet(
  my.data,
  my.series = 2,  # 'max_WHT' is the second column in `my.data`
  loess.span = 0,
  dt = 1/121,  # Assuming each period is regular and equally spaced
  dj = 1/100,
  lowerPeriod = 0.05,
  upperPeriod = 5,
  make.pval = TRUE,
  method = "AR",
  params = 0.6,
  n.sim = 100,
  date.format = NULL,
  date.tz = NULL,
  verbose = TRUE
)

# Inspect the result
wt.image(result, periodlab = "Periods (years)",
         legend.params = list(lab = "wavelet power levels"),
         label.time.axis = TRUE, 
         spec.time.axis = list(at = seq(1, 1200, by = 120),
                               labels = seq(2014, 2023, by = 1)),
         timelab = "Time (year)", 
         main = "Wavelet Power Spectrum of #41044")

# Preparing the data
data_frame <- data.frame(
  Period = result$Period,
  Power = result$Power.avg,
  PValue = result$Power.avg.pval
)

# Determine significance based on p-value threshold
threshold <- 0.05
data_frame$Significant <- data_frame$PValue <= threshold

# Filtering only significant data points
significant_data <- subset(data_frame, Significant)


# Plot of average wavelet power:
ggplot() +
  geom_line(data = data_frame, aes(x = Period, y = Power), color = "black") +  # Plotting the power as a black line
  geom_point(data = significant_data, aes(x = Period, y = Power, color = "Significant"), size = 2) +
  scale_x_log10(breaks = c(0.0625, 0.125, 0.25, 0.5, 1, 2, 4),
                labels = c("0.0625", "0.125", "0.25", "0.5", "1", "2", "4")) +  # Logarithmic x-axis with custom labels
  scale_color_manual(values = c("red"), labels = c("p < 0.05")) +  # Color scale for significance
  labs(
    title = "Global Wavelet Power Spectrum with 5% significance level of #41044",
    x = "Period (years)",
    y = "Global Wavelet Power",
    color = "Significance"  # Legend title
  ) +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),  # No major grid
    panel.grid.minor = element_blank(),  # No minor grid
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 1),  # Black border around the plot
    legend.position = "top",  # Legend at the top
    legend.justification = "right",  # Right-aligned legend
    axis.text.x = element_text(size = 20),  # Increase x-axis text size
    axis.text.y = element_text(size = 20),  # Increase y-axis text size
    axis.title.x = element_text(size = 20),  # Increase x-axis title size
    axis.title.y = element_text(size = 20),  # Increase y-axis title size
    plot.title = element_text(size = 18),  # Increase plot title size
    plot.subtitle = element_text(size = 16),  # Optional: increase subtitle size if you have one
    legend.text = element_text(size = 14)  # Increase legend text size
  )


# Reconstructoin of the time series
reconstruct_data <- reconstruct(result)
write.csv(reconstruct_data$series, file= "reconstruct_data.csv")
reconstruction <- data.frame(
  Time = my.data$period_start,
  Reconstruction = reconstruct_data$series
)
reconstruction$Time <- as.Date(reconstruction$Time, format = "%Y-%m-%d")

ggplot(data = reconstruction, aes(x = Time)) +
  geom_point(aes(y = Reconstruction.max_WHT), color = "black", size = 2) +
  geom_line(aes(y = Reconstruction.max_WHT.r), color = "red", size = 1) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +  # Ensures x-axis has annual breaks
  labs(
    title = "Reconstruction Analysis over Time",
    x = "Time (year)",
    y = "Reconstruction Value"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(size = 20),  # Customizes x-axis text size and angle
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    axis.title.y = element_text(size = 20),
    plot.title = element_text(size = 20)
  )

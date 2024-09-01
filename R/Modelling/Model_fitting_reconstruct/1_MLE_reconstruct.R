# Load the extRemes package
library(extRemes)

# Read the dataset
data <- read.csv("data_41049.csv")

# Define the frequency for the trigonometric terms
omega <- 2 * pi

## a = 1, b = MLE
# Pre-adjust the data to include the fixed effect of reconstruct
data$adjusted_max_WHT <- data$max_WHT - data$reconstruct

# Define the number of harmonics
Pu <- 1 # in location parameter
Pa <- 1 # in scale parameter 

# Generate harmonic components for location and scale
for (i in 1:max(Pu, Pa)) {
  if (i <= Pu) {
    data[[paste0("mu", 2*i-1)]] <- cos(i * omega * data$scaled_time)
    data[[paste0("mu", 2*i)]] <- sin(i * omega * data$scaled_time)
  }
  if (i <= Pa) {
    data[[paste0("phi", 2*i-1)]] <- cos(i * omega * data$scaled_time)
    data[[paste0("phi", 2*i)]] <- sin(i * omega * data$scaled_time)
  }
}

# Define the location formula including the 'reconstruct' term
location_formula <- if (Pu > 0) {
  as.formula(paste("~", paste(c(paste0("mu", 1:(2*Pu))), collapse = " + ")))
} else {
  ~ 1  # Include 'reconstruct' as the only covariate if Pu = 0
}

# Define the scale formula, optionally including harmonics
scale_formula <- if (Pa > 0) {
  as.formula(paste("~ reconstruct +", paste(c(paste0("phi", 1:(2*Pa))), collapse = " + ")))
} else {
  ~ reconstruct  # Use a constant scale if Pa = 0
}

# Fit the non-stationary GEV model using the adjusted data
fit <- fevd(adjusted_max_WHT, data, #location.fun = location_formula, 
            scale.fun = scale_formula,threshold = data$threshold - data$reconstruct, 
            type = "PP", shape.fun = ~1, use.phi = TRUE,
            time.units = "121/year")

# Print the summary and diagnostic plots
fit_summary <- summary(fit)
print(fit_summary)
plot(fit)

# Load the extRemes package
library(extRemes)

# Identify exceedance times
exceedance_indices <- which(data$max_WHT > data$threshold)
exceedance_times <- data$scaled_time[exceedance_indices]
exceedance_reconstruction <- data$reconstruct[exceedance_indices]

# Access the estimated parameters from the fitted model
fit_results <- fit_1_0_yes$results

# Extract the parameter estimates (coefficients) from the results
coefficients <- fit_results$par

# Define the frequency for the trigonometric terms
omega <- 2 * pi

# Extract the coefficients related to mu, sigma, and xi
mu0 <- coefficients["mu0"]
mu1 <- coefficients["mu1"]
mu2 <- coefficients["mu2"]
a <- coefficients["mu3"]

phi0 <- coefficients["phi0"]
b <- coefficients["phi1"]

xi <- coefficients["shape"]

# Calculate mu(t) at exceedance times
mu_t <- mu0 + mu1 * cos(omega * exceedance_times) + mu2 * sin(omega * exceedance_times) + 
  a * exceedance_reconstruction

# Calculate sigma(t) at exceedance times
sigma_t <- exp(phi0 + b * exceedance_reconstruction)

# Extract the corresponding threshold values at exceedance times
threshold <- data$threshold[exceedance_indices]

# Define the exceedance function lambda_u(t)
lambda_u <- function(mu_t, sigma_t, xi_t, u_t) {
  term <- (1 + xi_t * (u_t - mu_t) / sigma_t) 
  
  if (term <= 0 || is.na(term)) {
    return(0)  # Return 0 if the term is invalid
  }
  
  lambda_u_t <- term^(- 1 / xi_t) 
  return(lambda_u_t)
}

# Define the Z-statistic calculation using exceedance times
compute_z_k <- function(exceedance_times, mu_t, sigma_t, xi_t, u_t) {
  z_k <- numeric(length(exceedance_times) - 1)
  
  for (k in 2:length(exceedance_times)) {
    # Calculate lambda_u for the specific values at each exceedance time
    lambda_u_val <- (lambda_u(mu_t[k], sigma_t[k], xi_t, u_t[k]) 
                     + lambda_u(mu_t[k-1], sigma_t[k-1], xi_t, u_t[k-1]) )/2
    
    # Calculate the length of the interval between exceedance times
    interval_length <- exceedance_times[k] - exceedance_times[k-1]
    
    # Calculate Z_k as lambda_u multiplied by the interval length
    z_k[k-1] <- lambda_u_val * interval_length
  }
  
  return(z_k)
}

# Compute Z-statistics for the exceedance times
z_k_values <- compute_z_k(exceedance_times, mu_t, sigma_t, xi, threshold)

# Print the Z-statistics
print(z_k_values)

z_k_values <- z_k_values[z_k_values <= 4]
# Print the Z-statistics
print(z_k_values)

# Ensure Z-statistics are computed as z_k_values
z_k_values <- sort(z_k_values)

# Calculate the number of exceedances
n <- length(z_k_values)

# Calculate the theoretical quantiles for the exponential distribution
p <- (seq(1, n) - 0.5) / n
theoretical_quantiles <- -log(1 - p)

# Create a Q-Q plot
qqplot(theoretical_quantiles, z_k_values, main = "Q-Q Plot of Z-Statistics",
       xlab = "Theoretical Quantiles (Exponential(1))", ylab = "Sample Quantiles (Z-Statistics)")
#abline(0, 1, col = "red", lwd = 2)  # Add a reference line


# Compute y_k, the exceedances over the threshold
y_k <- data$max_WHT[exceedance_indices] - threshold

# Compute W_k
W_k <- (1 / xi) * log(1 + (xi * y_k) / (sigma_t + xi * (threshold - mu_t)))

# Print the W_k values
print(W_k)
W_k <- sort(W_k)

# Create a Q-Q plot
qqplot(theoretical_quantiles, W_k, main = "Q-Q Plot of W-Statistics",
       xlab = "Theoretical Quantiles (Exponential(1))", ylab = "Sample Quantiles (W-Statistics)")
#abline(0, 1, col = "red", lwd = 2)  # Add a reference line

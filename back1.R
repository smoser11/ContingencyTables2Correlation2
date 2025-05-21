# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# -------------------------------
# 1. Define functions (same as before)

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX
		sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	pX <- countsX / sum(countsX)
	pY <- countsY / sum(countsY)
	muX <- sum(x_levels * pX)
	muY <- sum(y_levels * pY)
	sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
	sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
	
	cum_pX <- cumsum(pX)
	cum_pY <- cumsum(pY)
	joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
	
	i <- 1; j <- 1
	cumX_prev <- 0; cumY_prev <- 0
	while (i <= length(x_levels) && j <= length(y_levels)) {
		currX <- cum_pX[i]
		currY <- cum_pY[j]
		joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
		
		if (currX < currY) {
			cumX_prev <- currX; i <- i + 1
		} else if (currX > currY) {
			cumY_prev <- currY; j <- j + 1
		} else {
			cumX_prev <- currX; cumY_prev <- currY; i <- i + 1; j <- j + 1
		}
	}
	
	E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
	r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
	return(r_max)
}

# Function to compute the minimum correlation (anti-comonotonic pairing)
min_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX
		sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# For r_min, pair highest X with lowest Y.
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

# Function to simulate the permutation distribution of Pearson's r
simulate_random_corr <- function(marginalX, marginalY, nsim = 1000, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX
		sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	r_vals <- numeric(nsim)
	for (i in 1:nsim) {
		x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
		y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
		r_vals[i] <- cor(x_perm, y_perm)
	}
	return(r_vals)
}

# -------------------------------
# 2. Define candidate marginal distributions for X and Y.
# We assume 5 categories for both. We'll consider several scenarios.
scenarios <- list(
	Extreme = list(
		marginalX = c(0.7, rep(0.3/4, 4)),
		marginalY = c(rep(0.02, 4), 1 - 0.02*4)
	),
	Uniform = list(
		marginalX = rep(1/5, 5),
		marginalY = rep(1/5, 5)
	),
	Bimodal = list(
		marginalX = c(0.45, 0.05, 0.05, 0.05, 0.4),
		marginalY = c(0.1, 0.1, 0.1, 0.1, 0.6)
	),
	HighlySkewed = list(
		marginalX = c(0.9, rep(0.1/4, 4)),
		marginalY = c(rep(0.01, 4), 1 - 0.01*4)
	),
	Moderate = list(
		marginalX = c(0.4, 0.15, 0.15, 0.15, 0.15),
		marginalY = c(0.15, 0.2, 0.2, 0.2, 0.25)
	)
)

# -------------------------------
# 3. Scan over scenarios (with fixed sample_size and nsim) to compute the range.
sample_size <- 10000
nsim <- 1000

results <- data.frame(Scenario = character(), 
					  r_min = numeric(),
					  r_max = numeric(),
					  theo_range = numeric(),
					  emp_range = numeric(),
					  stringsAsFactors = FALSE)

set.seed(123)  # for reproducibility
for (sc in names(scenarios)) {
	margX <- scenarios[[sc]]$marginalX
	margY <- scenarios[[sc]]$marginalY
	
	rmin <- min_corr_sorted(margX, margY, sample_size = sample_size)
	rmax <- max_corr_sorted(margX, margY, sample_size = sample_size)
	r_sim <- simulate_random_corr(margX, margY, nsim = nsim, sample_size = sample_size)
	
	theo_range <- rmax - rmin
	emp_range <- max(r_sim) - min(r_sim)
	
	results <- rbind(results, data.frame(Scenario = sc, 
										 r_min = rmin,
										 r_max = rmax,
										 theo_range = theo_range,
										 emp_range = emp_range))
}
print(results)

# -------------------------------
# 4. Plot the ranges by scenario.
results_long <- results %>%
	pivot_longer(cols = c("theo_range", "emp_range"), 
				 names_to = "Type", 
				 values_to = "Range")

ggplot(results_long, aes(x = Scenario, y = Range, fill = Type)) +
	geom_bar(stat = "identity", position = "dodge") +
	labs(title = "Range of Pearson's r by Marginal Scenario",
		 y = "Range (r_max - r_min)", x = "Scenario") +
	scale_fill_manual(values = c("theo_range" = "darkblue", "emp_range" = "orange")) +
	theme_minimal()

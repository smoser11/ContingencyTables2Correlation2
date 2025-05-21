# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Functions for computing theoretical bounds and simulating the permutation distribution

# Compute maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	# If marginals sum to ~1, treat them as probabilities; else as counts.
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
			cumX_prev <- currX
			i <- i + 1
		} else if (currX > currY) {
			cumY_prev <- currY
			j <- j + 1
		} else {
			cumX_prev <- currX
			cumY_prev <- currY
			i <- i + 1
			j <- j + 1
		}
	}
	
	E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
	r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
	return(r_max)
}

# Compute minimum correlation (anti-comonotonic pairing)
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
	
	# Pair highest X with lowest Y
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

# Simulate permutation (randomization) distribution of Pearson's r
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

# -----------------------------------------------------------------------------
# 2. Simulation study: Explore how r_min, r_max, and the simulated distribution (r_val)
# vary with marginal distributions and sample size.
#
# We consider two scenarios:
#   - "Extreme": for X, 70% mass on the first category; for Y, very low mass on all but last.
#   - "Uniform": equal probabilities for all categories.
#
# We use 5 categories for each variable in this example and vary sample_size.

# Define scenarios (each with 5 categories)
scenarios <- list(
	Extreme = list(
		marginalX = c(0.7, rep(0.3/4, 4)),
		marginalY = c(rep(0.02, 4), 1 - 0.02*4)
	),
	Uniform = list(
		marginalX = rep(1/5, 5),
		marginalY = rep(1/5, 5)
	)
)

# Sample sizes to explore
sample_sizes <- c(500, 1000, 5000, 10000)

# Initialize storage for summary statistics and simulated r values.
summary_df <- data.frame()
sim_r_df <- data.frame()

# Loop over scenarios and sample sizes.
for (sc in names(scenarios)) {
	pX <- scenarios[[sc]]$marginalX
	pY <- scenarios[[sc]]$marginalY
	for (s in sample_sizes) {
		# Compute theoretical bounds.
		r_min_val <- min_corr_sorted(pX, pY, sample_size = s)
		r_max_val <- max_corr_sorted(pX, pY, sample_size = s)
		# Simulate the permutation distribution.
		r_sim <- simulate_random_corr(pX, pY, nsim = 1000, sample_size = s)
		med_r <- median(r_sim)
		lower_ci <- quantile(r_sim, 0.025)
		upper_ci <- quantile(r_sim, 0.975)
		
		# Save summary statistics.
		summary_df <- rbind(summary_df, data.frame(
			scenario = sc,
			sample_size = s,
			r_min = r_min_val,
			r_max = r_max_val,
			median_r = med_r,
			lower_ci = lower_ci,
			upper_ci = upper_ci
		))
		
		# Save the simulated r values.
		sim_r_df <- rbind(sim_r_df, data.frame(
			scenario = sc,
			sample_size = s,
			r = r_sim
		))
	}
}

# -----------------------------------------------------------------------------
# 3. Plot the results

# (A) Summary plot: For each scenario and sample size, show the median simulated r 
#     with error bars (95% CI) and the theoretical r_min and r_max.
p_summary <- ggplot(summary_df, aes(x = factor(sample_size))) +
	geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, color = "Simulated 95% CI"), width = 0.2) +
	geom_point(aes(y = median_r, color = "Median Simulated r"), size = 3) +
	geom_point(aes(y = r_min, color = "Theoretical r_min"), shape = 17, size = 3) +
	geom_point(aes(y = r_max, color = "Theoretical r_max"), shape = 17, size = 3) +
	facet_wrap(~scenario, scales = "free_y") +
	labs(x = "Sample Size", y = "Pearson's r",
		 title = "Summary of r_min, r_max, and Simulated r Distribution") +
	scale_color_manual(name = "Legend",
					   values = c("Simulated 95% CI" = "blue",
					   		   "Median Simulated r" = "blue",
					   		   "Theoretical r_min" = "red",
					   		   "Theoretical r_max" = "green")) +
	theme_minimal()

# (B) Boxplot of the simulated r distributions by sample size and scenario.
p_box <- ggplot(sim_r_df, aes(x = factor(sample_size), y = r, fill = factor(sample_size))) +
	geom_boxplot() +
	facet_wrap(~scenario, scales = "free_y") +
	labs(x = "Sample Size", y = "Simulated Pearson's r",
		 title = "Boxplot of Simulated r Distributions") +
	theme_minimal() +
	guides(fill = FALSE)

# Print the plots.
print(p_summary)
print(p_box)

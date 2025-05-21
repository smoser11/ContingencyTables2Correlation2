# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Define functions to compute theoretical correlations and simulate r values

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	# If marginals sum to approximately 1, assume probabilities; else assume counts.
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
		if (sum(countsY) != sample_size)
			stop("Total counts for X and Y must be equal.")
	}
	
	# Define ordinal levels (assumed to be 0,1,2,...)
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	# Compute proportions and moments
	pX <- countsX / sum(countsX)
	pY <- countsY / sum(countsY)
	muX <- sum(x_levels * pX)
	muY <- sum(y_levels * pY)
	sigmaX <- sqrt(sum(x_levels^2 * pX) - muX^2)
	sigmaY <- sqrt(sum(y_levels^2 * pY) - muY^2)
	
	# Construct joint distribution using cumulative probabilities (Fréchet–Hoeffding upper bound)
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
	
	# Compute E[XY] based on the joint distribution
	E_XY <- sum(outer(x_levels, y_levels, FUN = "*") * joint)
	
	# Calculate the maximum Pearson correlation
	r_max <- (E_XY - muX * muY) / (sigmaX * sigmaY)
	return(r_max)
}

# Function to compute the minimum correlation (pair X descending with Y ascending)
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
		if (sum(countsY) != sample_size)
			stop("Total counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	# Create full sample vectors based on counts
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Pair highest X with lowest Y to minimize the product
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

# Function to simulate the permutation (randomization) distribution of Pearson's r
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
		if (sum(countsY) != sample_size)
			stop("Total counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX) - 1)
	y_levels <- 0:(length(countsY) - 1)
	
	# Create sample vectors based on counts
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Initialize storage for simulated correlations
	r_vals <- numeric(nsim)
	for (i in 1:nsim) {
		x_perm <- sample(x_vec, size = length(x_vec), replace = FALSE)
		y_perm <- sample(y_vec, size = length(y_vec), replace = FALSE)
		r_vals[i] <- cor(x_perm, y_perm)
	}
	return(r_vals)
}

# -----------------------------------------------------------------------------
# 2. Define functions to plot the results using ggplot2

# Function to plot the empirical distribution of Pearson's r with theoretical bounds and 95% CI
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
										main = "Empirical Distribution of Pearson's r") {
	# Create a data frame for r_vals
	df <- data.frame(r = r_vals)
	
	# Ensure x-axis limits include at least r_min and r_max.
	x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
	x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
	
	# Build a data frame for vertical lines and their labels.
	vlines <- data.frame(
		intercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
		label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
					   levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
	)
	
	# Create the plot.
	p <- ggplot(df, aes(x = r)) +
		geom_histogram(aes(y = ..density..), bins = 30,
					   fill = "lightblue", color = "white", alpha = 0.7) +
		geom_density(color = "darkblue", size = 1) +
		geom_vline(data = vlines, aes(xintercept = intercept, color = label, linetype = label), size = 1) +
		scale_color_manual(name = "Legend", 
						   values = c("Theoretical Min" = "red", 
						   		   "Theoretical Max" = "green", 
						   		   "95% CI Lower" = "purple", 
						   		   "95% CI Upper" = "purple")) +
		scale_linetype_manual(name = "Legend",
							  values = c("Theoretical Min" = "dashed", 
							  		   "Theoretical Max" = "dashed", 
							  		   "95% CI Lower" = "dotted", 
							  		   "95% CI Upper" = "dotted")) +
		labs(title = main,
			 x = "Pearson's r",
			 y = "Density") +
		xlim(x_lower, x_upper) +
		theme_minimal()
	return(p)
}

# Function to plot the marginal distribution as a bar plot using ggplot2
plot_marginal <- function(counts, varname = "X") {
	df <- data.frame(Category = factor(0:(length(counts)-1)),
					 Frequency = counts)
	p <- ggplot(df, aes(x = Category, y = Frequency)) +
		geom_bar(stat = "identity", fill = "skyblue", color = "black", alpha = 0.8) +
		labs(title = paste("Marginal Distribution of", varname),
			 x = paste(varname, "Categories"),
			 y = "Frequency") +
		theme_minimal()
	return(p)
}

# -----------------------------------------------------------------------------
# 3. Demonstration using example data

# Set sample size
sample_size <- 10000

# Define sample marginal distributions as frequencies (counts)
# For X, assume 4 ordinal categories with counts: 1000, 3000, 4000, 2000
marginalX_counts <- c(1000, 3000, 4000, 2000)
# For Y, assume 4 ordinal categories with counts: 2000, 3000, 3000, 2000
marginalY_counts <- c(2000, 3000, 3000, 2000)

# Display the marginal distributions as tables in the console
cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(marginalX_counts)-1),
				 Frequency = marginalX_counts))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(marginalY_counts)-1),
				 Frequency = marginalY_counts))

# Also, display the marginal distributions graphically using ggplot2
pX <- plot_marginal(marginalX_counts, varname = "X")
pY <- plot_marginal(marginalY_counts, varname = "Y")
grid.arrange(pX, pY, ncol = 2)

# Compute theoretical maximum and minimum Pearson correlations
r_max <- max_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
r_min <- min_corr_sorted(marginalX_counts, marginalY_counts, sample_size = sample_size)
cat("\nTheoretical maximum Pearson's r:", round(r_max, 3), "\n")
cat("Theoretical minimum Pearson's r:", round(r_min, 3), "\n")

# Simulate the permutation distribution of Pearson's r
set.seed(123)  # for reproducibility
r_vals <- simulate_random_corr(marginalX_counts, marginalY_counts, nsim = 1000, sample_size = sample_size)

# Calculate the 95% CI (null interval) from the permutation distribution
ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
cat("\n95% CI for Pearson's r (from permutation distribution):\n")
print(ci_bounds)

# Plot the empirical distribution of Pearson's r using ggplot2
p_empirical <- plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds,
										   main = "Permutation Distribution of Pearson's r")
print(p_empirical)

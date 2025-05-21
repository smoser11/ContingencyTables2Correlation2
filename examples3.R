#######################################
rm(list=)
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
# 2. Define ggplot functions to display results

# Function to plot the empirical distribution of Pearson's r with vertical lines and legend
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
										main = "Empirical Distribution of Pearson's r") {
	# Data frame for r values
	df <- data.frame(r = r_vals)
	
	# Determine x-axis limits to include r_min and r_max.
	x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
	x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
	
	# Data frame for vertical lines (theoretical min, max, and CI bounds)
	vlines <- data.frame(
		xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
		label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
					   levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
	)
	
	p <- ggplot(df, aes(x = r)) +
		geom_histogram(aes(y = ..density..), bins = 30,
					   fill = "lightblue", color = "white", alpha = 0.7) +
		geom_density(color = "darkblue", size = 1) +
		geom_vline(data = vlines,
				   aes(xintercept = xintercept, color = label, linetype = label),
				   size = 1) +
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

# Function to plot marginal distributions as bar plots using ggplot2
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
# 3. Monte Carlo over different numbers of categories with extreme marginals

# Simulation parameters
sample_size <- 5000  # sample size for counts
nsim <- 1000         # number of simulations for permutation distribution

# Define a range for number of categories for X and Y.
# X categories: 5, 7, or 9
# Y categories: 6, 8, 10, or 11 (ensuring they differ from X)
nX_values <- c(5, 7, 9)
nY_values <- c(6, 8, 10, 11)

# Create all combinations (we only want combinations where nX != nY)
combinations <- expand.grid(nX = nX_values, nY = nY_values) %>%
	filter(nX != nY)

# Prepare lists to store simulation summaries and plots
results <- list()
plots <- list()

# Loop over each combination of categories
for(i in 1:nrow(combinations)) {
	nX <- combinations$nX[i]
	nY <- combinations$nY[i]
	
	# Generate extreme marginals:
	# For X: assign 70% probability to the first category and split the remaining 30% equally.
	pX <- c(0.7, rep(0.3/(nX - 1), nX - 1))
	
	# For Y: assign a very small probability (e.g., 0.02) to the first (nY - 1) categories,
	# and the remainder to the last category.
	pY <- c(rep(0.02, nY - 1), 1 - 0.02*(nY - 1))
	
	# Compute theoretical maximum and minimum correlations.
	r_max <- max_corr_sorted(pX, pY, sample_size = sample_size)
	r_min <- min_corr_sorted(pX, pY, sample_size = sample_size)
	
	# Simulate the permutation distribution of Pearson's r.
	r_vals <- simulate_random_corr(pX, pY, nsim = nsim, sample_size = sample_size)
	
	# Compute the 95% confidence interval from the permutation distribution.
	ci_bounds <- quantile(r_vals, probs = c(0.025, 0.975))
	median_r <- median(r_vals)
	
	# Save the summary results
	results[[i]] <- data.frame(nX = nX, nY = nY,
							   r_min = r_min, r_max = r_max,
							   median_r = median_r,
							   CI_lower = ci_bounds[1], CI_upper = ci_bounds[2])
	
	# Create a title string for the plot.
	title_str <- paste("nX =", nX, "nY =", nY)
	
	# Create the permutation distribution plot using ggplot2.
	p_emp <- plot_empirical_distribution(r_vals, r_min, r_max, ci_bounds,
										 main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
	
	plots[[i]] <- p_emp
}

# Combine all simulation summaries into one data frame and print it.
summary_df <- do.call(rbind, results)
print(summary_df)

# Optionally, arrange and display all the permutation distribution plots.
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as examples
# (Here we use the first combination from our simulation)
example_nX <- combinations$nX[1]
example_nY <- combinations$nY[1]
# Generate extreme marginals for this instance.
example_pX <- c(0.7, rep(0.3/(example_nX - 1), example_nX - 1))
example_pY <- c(rep(0.02, example_nY - 1), 1 - 0.02*(example_nY - 1))
# Convert probabilities to counts for display purposes.
example_countsX <- round(example_pX * sample_size)
example_countsY <- round(example_pY * sample_size)

# Print the marginal distributions as tables.
cat("Marginal Distribution for X (counts):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
				 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
				 Frequency = example_countsY))

# Plot the marginal distributions using ggplot2.
pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)


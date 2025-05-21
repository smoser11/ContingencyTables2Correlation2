# First, run one of the examples to get results
results <- basic_demonstration()

# The results contain summary statistics and simulated values
summary_df <- results$summary
sim_r_df <- results$simulations

# You can create specific visualizations using the visualization functions:

# 1. Summary plot comparing theoretical bounds and confidence intervals
summary_plot <- plot_bounds_summary(summary_df)
print(summary_plot)

# 2. Boxplot of simulated distributions
boxplot <- plot_sim_boxplot(sim_r_df)
print(boxplot)

# 3. For a specific scenario and sample size, create a permutation distribution plot
scenario <- "Extreme"
sample_size <- 10000

# Filter data for the specific scenario and sample size
filtered_summary <- summary_df %>% 
	filter(scenario == !!scenario, sample_size == !!sample_size)
filtered_r_vals <- sim_r_df %>% 
	filter(scenario == !!scenario, sample_size == !!sample_size) %>% 
	pull(r)

# Create and display the plot
dist_plot <- plot_permutation_distribution(
	filtered_r_vals, 
	filtered_summary$r_min, 
	filtered_summary$r_max, 
	c(filtered_summary$lower_ci, filtered_summary$upper_ci),
	main = paste("Permutation Distribution (", scenario, ", n =", sample_size, ")")
)
print(dist_plot)



###################

# Run the range comparison
range_results <- range_comparison_demonstration()

# Create a comparison plot directly from the results
range_plot <- plot_range_comparison(range_results)
print(range_plot)





## ---
	
# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# --- Functions defined earlier ---

# Maximum Spearman correlation via comonotonic coupling
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	# Generate counts if marginals sum to ~1 (i.e., probabilities)
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX; sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX)-1)
	y_levels <- 0:(length(countsY)-1)
	
	pX <- countsX/sum(countsX); pY <- countsY/sum(countsY)
	muX <- sum(x_levels * pX); muY <- sum(y_levels * pY)
	sigmaX <- sqrt(sum(x_levels^2 * pX)-muX^2)
	sigmaY <- sqrt(sum(y_levels^2 * pY)-muY^2)
	
	# Comonotonic coupling: use the cumulative probabilities (Fréchet–Hoeffding upper bound)
	cum_pX <- cumsum(pX)
	cum_pY <- cumsum(pY)
	joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
	
	i <- 1; j <- 1; cumX_prev <- 0; cumY_prev <- 0
	while(i <= length(x_levels) && j <= length(y_levels)){
		currX <- cum_pX[i]; currY <- cum_pY[j]
		joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
		if(currX < currY){
			cumX_prev <- currX; i <- i+1
		} else if(currX > currY){
			cumY_prev <- currY; j <- j+1
		} else {
			cumX_prev <- currX; cumY_prev <- currY; i <- i+1; j <- j+1
		}
	}
	E_XY <- sum(outer(x_levels, y_levels, FUN="*") * joint)
	r_max <- (E_XY - muX * muY)/(sigmaX * sigmaY)
	return(r_max)
}

# Minimum Spearman correlation via countermonotonic coupling
min_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX; sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	
	x_levels <- 0:(length(countsX)-1)
	y_levels <- 0:(length(countsY)-1)
	
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Countermonotonic coupling: sort X in descending order, Y in ascending order
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

# --- End functions ---

# Set fixed marginal for X (uniform over 5 categories)
p_X <- rep(1/5, 5)

# Define Y: Uniform and Extreme marginals
p_Y_uniform <- rep(1/5, 5)
p_Y_extreme <- c(0.02, 0.02, 0.02, 0.02, 0.92)

# Define a sequence of interpolation parameters t in [0,1]
t_seq <- seq(0, 1, length.out = 20)

# Initialize storage for results
results <- data.frame(t = t_seq, 
					  D_TV = NA, 
					  r_max = NA, 
					  r_min = NA,
					  diff = NA)

# Function to compute total variation distance between p and its reflection
TV_distance <- function(p) {
	K <- length(p)
	p_reflect <- p[K:1]
	return(0.5 * sum(abs(p - p_reflect)))
}

sample_size <- 10000  # fixed sample size

for(i in seq_along(t_seq)){
	t <- t_seq[i]
	# Interpolate: p_Y(t) = (1-t)*uniform + t*extreme
	p_Y <- (1-t)*p_Y_uniform + t*p_Y_extreme
	# Compute total variation distance between p_Y and its mirror
	D_TV <- TV_distance(p_Y)
	# Compute theoretical extremes for Spearman correlation
	r_max_val <- max_corr_sorted(p_X, p_Y, sample_size = sample_size)
	r_min_val <- min_corr_sorted(p_X, p_Y, sample_size = sample_size)
	
	results$t[i] <- t
	results$D_TV[i] <- D_TV
	results$r_max[i] <- r_max_val
	results$r_min[i] <- r_min_val
	results$diff[i] <- r_max_val + r_min_val  # if symmetric, this would be 0
}

print(results)

# Plot the total variation distance versus t
p1 <- ggplot(results, aes(x=t, y=D_TV)) +
	geom_line(size=1, color="blue") +
	geom_point(color="blue") +
	labs(title="Total Variation Distance from Symmetry vs. t", x="t", y="TV Distance") +
	theme_minimal()

# Plot r_max and r_min versus t
p2 <- ggplot(results, aes(x=t)) +
	geom_line(aes(y=r_max, color="r_max"), size=1) +
	geom_line(aes(y=r_min, color="r_min"), size=1) +
	geom_point(aes(y=r_max, color="r_max"), size=2) +
	geom_point(aes(y=r_min, color="r_min"), size=2) +
	labs(title="Extreme Spearman Correlations vs. t", x="t", y="Correlation") +
	scale_color_manual(name="Legend", values=c("r_max"="green", "r_min"="red")) +
	theme_minimal()

# Plot the sum r_max + r_min (should be 0 if symmetric)
p3 <- ggplot(results, aes(x=t, y=diff)) +
	geom_line(size=1, color="purple") +
	geom_point(size=2, color="purple") +
	labs(title="r_max + r_min vs. t (Symmetry Indicator)", x="t", y="r_max + r_min") +
	theme_minimal()

# Arrange the plots in one display
library(gridExtra)
grid.arrange(p1, p2, p3, ncol=1)



##---



# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)
library(gridExtra)

# -----------------------------------------------------
# Define functions for extreme Spearman correlations

# Maximum Spearman correlation via comonotonic coupling
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX; sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	x_levels <- 0:(length(countsX)-1)
	y_levels <- 0:(length(countsY)-1)
	
	pX <- countsX/sum(countsX)
	pY <- countsY/sum(countsY)
	muX <- sum(x_levels * pX)
	muY <- sum(y_levels * pY)
	sigmaX <- sqrt(sum(x_levels^2 * pX)-muX^2)
	sigmaY <- sqrt(sum(y_levels^2 * pY)-muY^2)
	
	# Comonotonic coupling via cumulative probabilities (upper Fréchet bound)
	cum_pX <- cumsum(pX)
	cum_pY <- cumsum(pY)
	joint <- matrix(0, nrow = length(x_levels), ncol = length(y_levels))
	
	i <- 1; j <- 1; cumX_prev <- 0; cumY_prev <- 0
	while(i <= length(x_levels) && j <= length(y_levels)){
		currX <- cum_pX[i]; currY <- cum_pY[j]
		joint[i, j] <- min(currX, currY) - max(cumX_prev, cumY_prev)
		if(currX < currY){
			cumX_prev <- currX; i <- i + 1
		} else if(currX > currY){
			cumY_prev <- currY; j <- j + 1
		} else {
			cumX_prev <- currX; cumY_prev <- currY; i <- i + 1; j <- j + 1
		}
	}
	E_XY <- sum(outer(x_levels, y_levels, FUN="*") * joint)
	r_max <- (E_XY - muX * muY)/(sigmaX * sigmaY)
	return(r_max)
}

# Minimum Spearman correlation via countermonotonic coupling
min_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	if (sum(marginalX) <= 1.1) {
		countsX <- as.vector(rmultinom(1, size = sample_size, prob = marginalX))
	} else {
		countsX <- marginalX; sample_size <- sum(countsX)
	}
	if (sum(marginalY) <= 1.1) {
		countsY <- as.vector(rmultinom(1, size = sample_size, prob = marginalY))
	} else {
		countsY <- marginalY
		if (sum(countsY) != sample_size) stop("Counts for X and Y must be equal.")
	}
	x_levels <- 0:(length(countsX)-1)
	y_levels <- 0:(length(countsY)-1)
	
	x_vec <- rep(x_levels, times = countsX)
	y_vec <- rep(y_levels, times = countsY)
	
	# Countermonotonic coupling: sort X in descending order and Y in ascending order.
	x_sorted <- sort(x_vec, decreasing = TRUE)
	y_sorted <- sort(y_vec, decreasing = FALSE)
	
	r_min <- cor(x_sorted, y_sorted)
	return(r_min)
}

# -----------------------------------------------------
# Define a function to compute the total variation distance 
# between a probability vector and its reflection.
TV_distance <- function(p) {
	K <- length(p)
	p_reflect <- p[K:1]
	return(0.5 * sum(abs(p - p_reflect)))
}

# -----------------------------------------------------
# Setup: Fix X as uniform over 5 categories and define a family for Y.

p_X <- rep(1/5, 5)  # uniform marginal for X

# Define anchor distributions for Y:
p_Y_uniform <- rep(1/5, 5)
# Define an extremely asymmetric marginal for Y
p_Y_extreme <- c(0.02, 0.02, 0.02, 0.02, 0.92)

# Create a family of marginals for Y by interpolating between uniform and extreme.
t_seq <- seq(0, 1, length.out = 20)
results <- data.frame(t = t_seq, D_TV = NA, r_max = NA, r_min = NA, diff = NA)

sample_size <- 10000

set.seed(123)  # for reproducibility
for(i in seq_along(t_seq)){
	t <- t_seq[i]
	# Interpolated marginal for Y:
	p_Y <- (1-t)*p_Y_uniform + t*p_Y_extreme
	# Compute asymmetry measure:
	D_TV <- TV_distance(p_Y)
	# Compute extreme Spearman correlations:
	r_max_val <- max_corr_sorted(p_X, p_Y, sample_size = sample_size)
	r_min_val <- min_corr_sorted(p_X, p_Y, sample_size = sample_size)
	
	results$t[i] <- t
	results$D_TV[i] <- D_TV
	results$r_max[i] <- r_max_val
	results$r_min[i] <- r_min_val
	results$diff[i] <- r_max_val + r_min_val  # should be 0 when symmetric
}

print(results)

# -----------------------------------------------------
# Plot results:

# (A) Plot total variation distance vs t.
p1 <- ggplot(results, aes(x = t, y = D_TV)) +
	geom_line(size = 1, color = "blue") +
	geom_point(color = "blue") +
	labs(title = "TV Distance from Symmetry vs. t", x = "t", y = "TV Distance") +
	theme_minimal()

# (B) Plot r_max and r_min vs t.
p2 <- ggplot(results, aes(x = t)) +
	geom_line(aes(y = r_max, color = "r_max"), size = 1) +
	geom_line(aes(y = r_min, color = "r_min"), size = 1) +
	geom_point(aes(y = r_max, color = "r_max"), size = 2) +
	geom_point(aes(y = r_min, color = "r_min"), size = 2) +
	labs(title = "Extreme Spearman Correlations vs. t", x = "t", y = "Correlation") +
	scale_color_manual(name = "Legend", values = c("r_max" = "green", "r_min" = "red")) +
	theme_minimal()

# (C) Plot the sum r_max + r_min vs t (symmetry indicator).
p3 <- ggplot(results, aes(x = t, y = diff)) +
	geom_line(size = 1, color = "purple") +
	geom_point(size = 2, color = "purple") +
	labs(title = "r_max + r_min vs. t (Symmetry Indicator)", x = "t", y = "r_max + r_min") +
	theme_minimal()

grid.arrange(p1, p2, p3, ncol = 1)


#---

library(transport)  # for optimal matching
library(ggplot2)

# Define ranks for ordinal categories
ranks <- 1:4

# Fixed uniform marginal for X
pX <- rep(0.25, 4)

# Function to compute r for a given joint distribution
pearson_r <- function(joint, x_vals, y_vals) {
	Ex <- sum(rowSums(joint) * x_vals)
	Ey <- sum(colSums(joint) * y_vals)
	cov_xy <- sum(joint * outer(x_vals, y_vals, "*")) - Ex * Ey
	sd_x <- sqrt(sum(pX * x_vals^2) - Ex^2)
	sd_y <- sqrt(sum(colSums(joint) * y_vals^2) - Ey^2)
	return(cov_xy / (sd_x * sd_y))
}

# Function to generate max and min correlation
bounds_r <- function(pY) {
	joint_max <- outer(pX, pY)
	joint_max <- joint_max[order(-ranks), order(-ranks)]  # comonotonic
	joint_min <- joint_max[order(-ranks), order(ranks)]   # antimonotonic
	r_max <- pearson_r(joint_max, ranks, ranks)
	r_min <- pearson_r(joint_min, ranks, ranks)
	return(c(r_min = r_min, r_max = r_max))
}

# Varying pY from uniform to skewed
skew_seq <- seq(0.25, 1, by = 0.05)
results <- data.frame()

for (a in skew_seq) {
	pY <- c(a, (1 - a) / 3, (1 - a) / 3, (1 - a) / 3)
	b <- bounds_r(pY)
	results <- rbind(results, data.frame(skew = a, r_min = b["r_min"], r_max = b["r_max"]))
}

# Plot
ggplot(results, aes(x = skew)) +
	geom_line(aes(y = r_max), color = "blue") +
	geom_line(aes(y = -r_min), color = "red", linetype = "dashed") +
	labs(title = "Asymmetry in Pearson's r bounds",
		 x = "Skew in Y's marginal (prob of 1st category)",
		 y = "Correlation",
		 caption = "r_max (solid blue); -r_min (dashed red)") +
	theme_minimal()

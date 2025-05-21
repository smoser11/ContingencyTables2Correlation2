# Load required libraries
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# 1. Functions for theoretical correlations and simulation

# Function to compute the maximum correlation (comonotonic coupling)
max_corr_sorted <- function(marginalX, marginalY, sample_size = 10000) {
	# If marginals sum to ~1, treat as probabilities and generate counts.
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
	
	# Compute the joint distribution using cumulative probabilities (Fréchet–Hoeffding upper bound)
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
# 2. Define ggplot functions for displaying results

# Function to plot the empirical distribution of Pearson's r with vertical lines and legend
plot_empirical_distribution <- function(r_vals, r_min, r_max, ci_bounds,
										main = "Empirical Distribution of Pearson's r") {
	df <- data.frame(r = r_vals)
	
	# Set x-axis limits to include r_min and r_max
	x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
	x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
	
	vlines <- data.frame(
		xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
		label = factor(c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"),
					   levels = c("Theoretical r_min", "Theoretical r_max", "95% CI Lower", "95% CI Upper"))
	)
	
	p <- ggplot(df, aes(x = r)) +
		geom_histogram(aes(y = ..density..), bins = 30,
					   fill = "lightblue", color = "white", alpha = 0.7) +
		geom_density(color = "darkblue", size = 1) +
		geom_vline(data = vlines,
				   aes(xintercept = xintercept, color = label, linetype = label),
				   size = 1) +
		scale_color_manual(name = "Legend", 
						   values = c("Theoretical r_min" = "red", 
						   		   "Theoretical r_max" = "green", 
						   		   "95% CI Lower" = "purple", 
						   		   "95% CI Upper" = "purple")) +
		scale_linetype_manual(name = "Legend",
							  values = c("Theoretical r_min" = "dashed", 
							  		   "Theoretical r_max" = "dashed", 
							  		   "95% CI Lower" = "dotted", 
							  		   "95% CI Upper" = "dotted")) +
		labs(title = main,
			 x = "Pearson's r",
			 y = "Density") +
		xlim(x_lower, x_upper) +
		theme_minimal()
	return(p)
}

# Function to plot a marginal distribution as a bar plot using ggplot2
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
# 3. Simulation study: Explore cases where the simulated extremes are nearly the theoretical bounds.
#
# We now include additional scenarios in the scenarios list.
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
	)
)
sample_sizes <- c(100, 500, 1000, 5000, 10000)

# Storage for summary statistics, simulated r values, and glued pairs.
summary_df <- data.frame()
sim_r_df <- data.frame()
glued_pairs <- list()  # nested list: glued_pairs[[scenario]][[sample_size]] = list(max = , min = )

# Loop over scenarios and sample_sizes.
for (sc in names(scenarios)) {
	pX <- scenarios[[sc]]$marginalX
	pY <- scenarios[[sc]]$marginalY
	glued_pairs[[sc]] <- list()
	
	for (s in sample_sizes) {
		# Compute theoretical bounds.
		r_min_val <- min_corr_sorted(pX, pY, sample_size = s)
		r_max_val <- max_corr_sorted(pX, pY, sample_size = s)
		
		# Simulate permutation distribution.
		r_sim <- simulate_random_corr(pX, pY, nsim = 1000, sample_size = s)
		med_r <- median(r_sim)
		lower_ci <- quantile(r_sim, 0.025)
		upper_ci <- quantile(r_sim, 0.975)
		
		# Save summary statistics (also compute differences).
		diff_lower <- abs(r_min_val - lower_ci)
		diff_upper <- abs(r_max_val - upper_ci)
		summary_df <- rbind(summary_df, data.frame(
			scenario = sc,
			sample_size = s,
			r_min = r_min_val,
			lower_ci = lower_ci,
			diff_lower = diff_lower,
			r_max = r_max_val,
			upper_ci = upper_ci,
			diff_upper = diff_upper,
			median_r = med_r
		))
		
		# Save simulated r values.
		sim_r_df <- rbind(sim_r_df, data.frame(
			scenario = sc,
			sample_size = s,
			r = r_sim
		))
		
		# Save "glued pairs" (joint distributions) for r_max and r_min.
		# Create counts from probabilities, ensuring they sum exactly to s.
		x_levels <- 0:(length(pX)-1)
		y_levels <- 0:(length(pY)-1)
		
		countsX <- round(pX * s)
		diffX <- s - sum(countsX)
		if(diffX != 0) {
			i_max <- which.max(countsX)
			countsX[i_max] <- countsX[i_max] + diffX
		}
		countsY <- round(pY * s)
		diffY <- s - sum(countsY)
		if(diffY != 0) {
			i_max <- which.max(countsY)
			countsY[i_max] <- countsY[i_max] + diffY
		}
		
		x_vec <- rep(x_levels, times = countsX)
		y_vec <- rep(y_levels, times = countsY)
		
		max_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
								Y = sort(y_vec, decreasing = TRUE))
		min_pairs <- data.frame(X = sort(x_vec, decreasing = TRUE),
								Y = sort(y_vec, decreasing = FALSE))
		
		glued_pairs[[sc]][[as.character(s)]] <- list(max = max_pairs, min = min_pairs)
	}
}

# Print the simulation summary.
cat("Simulation Summary:\n")
print(summary_df)

# Identify cases where the theoretical lower bound is nearly equal to the 2.5% quantile 
# and the upper bound is nearly equal to the 97.5% quantile.
threshold <- 0.91  # tolerance for differences
cat("\nCases where |r_min - lower_ci| < ", threshold, " and |r_max - upper_ci| < ", threshold, ":\n", sep = "")
print(subset(summary_df, diff_lower < threshold & diff_upper < threshold))

# Optionally, arrange and display all the permutation distribution plots.
plots <- list()
for (i in 1:nrow(summary_df)) {
	row <- summary_df[i, ]
	title_str <- paste("Scenario:", row$scenario, "Sample Size:", row$sample_size)
	r_vals <- sim_r_df %>% filter(scenario == row$scenario, sample_size == row$sample_size) %>% pull(r)
	ci_bounds <- c(row$lower_ci, row$upper_ci)
	p_emp <- plot_empirical_distribution(r_vals, row$r_min, row$r_max, ci_bounds,
										 main = paste("Permutation Distribution of r (", title_str, ")", sep = " "))
	plots[[i]] <- p_emp
}
grid.arrange(grobs = plots, ncol = 2)

# -----------------------------------------------------------------------------
# Also, display the marginal distributions for one instance as an example.
# (We use the "Extreme" scenario at the smallest sample_size.)
example_sample_size <- sample_sizes[1]
example_pX <- scenarios[["Extreme"]]$marginalX
example_pY <- scenarios[["Extreme"]]$marginalY
example_countsX <- round(example_pX * example_sample_size)
diffX <- example_sample_size - sum(example_countsX)
if(diffX != 0) {
	i_max <- which.max(example_countsX)
	example_countsX[i_max] <- example_countsX[i_max] + diffX
}
example_countsY <- round(example_pY * example_sample_size)
diffY <- example_sample_size - sum(example_countsY)
if(diffY != 0) {
	i_max <- which.max(example_countsY)
	example_countsY[i_max] <- example_countsY[i_max] + diffY
}

cat("\nMarginal Distribution for X (counts, Extreme scenario):\n")
print(data.frame(Category = 0:(length(example_countsX)-1),
				 Frequency = example_countsX))
cat("\nMarginal Distribution for Y (counts, Extreme scenario):\n")
print(data.frame(Category = 0:(length(example_countsY)-1),
				 Frequency = example_countsY))

pX_plot <- plot_marginal(example_countsX, varname = "X")
pY_plot <- plot_marginal(example_countsY, varname = "Y")
grid.arrange(pX_plot, pY_plot, ncol = 2)

# -----------------------------------------------------------------------------
# Optionally, inspect the glued pairs for one example.
# For instance, for the "Extreme" scenario at sample_size = 500.
example_glued <- glued_pairs[["Extreme"]][["500"]]
cat("\nGlued pairs for maximum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$max, 10))
cat("\nGlued pairs for minimum correlation (Extreme, sample_size = 500):\n")
print(head(example_glued$min, 10))






###########


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

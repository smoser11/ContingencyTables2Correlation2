# correlation_bounds_visualization.R
#
# Visualization functions for correlation bounds and permutation distributions
#
# Author: [Your Name]
# Date: March 2, 2025

# -----------------------------------------------------------------------------
# Load required libraries
# -----------------------------------------------------------------------------
library(ggplot2)
library(gridExtra)
library(dplyr)

# -----------------------------------------------------------------------------
# Function to plot the empirical distribution of Pearson's r with theoretical bounds
# and confidence intervals
#
# Arguments:
#   r_vals - Vector of simulated correlation coefficients
#   r_min - Theoretical minimum correlation
#   r_max - Theoretical maximum correlation
#   ci_bounds - Vector of length 2 with lower and upper confidence bounds
#   observed_r - Observed correlation coefficient
#   r_rescaled - Rescaled correlation coefficient
#   main - Plot title
#
# Returns:
#   ggplot object
# -----------------------------------------------------------------------------
plot_permutation_distribution <- function(r_vals, r_min, r_max, ci_bounds, 
										  observed_r = NULL, r_rescaled = NULL,
										  main = "Permutation Distribution of Pearson's r") {
	df <- data.frame(r = r_vals)
	
	# Set x-axis limits to include r_min and r_max
	x_lower <- min(r_min, quantile(r_vals, 0.01)) - 0.05
	x_upper <- max(r_max, quantile(r_vals, 0.99)) + 0.05
	
	# If observed_r is provided, include it in limits
	if (!is.null(observed_r)) {
		x_lower <- min(x_lower, observed_r - 0.05)
		x_upper <- max(x_upper, observed_r + 0.05)
	}
	
	# Create line data frame
	vlines <- data.frame(
		xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
		label = factor(c("Theoretical Minimum", "Theoretical Maximum", "95% CI Lower", "95% CI Upper"),
					   levels = c("Theoretical Minimum", "Theoretical Maximum", "95% CI Lower", "95% CI Upper"))
	)
	
	# Add observed_r if provided
	if (!is.null(observed_r)) {
		if (!is.null(r_rescaled)) {
			# Include both observed and rescaled
			vlines <- rbind(vlines, data.frame(
				xintercept = c(observed_r),
				label = factor(c("Observed Correlation"),
							   levels = c("Theoretical Minimum", "Theoretical Maximum", "95% CI Lower", "95% CI Upper", 
							   		   "Observed Correlation"))
			))
			subtitle <- paste0("Observed r: ", round(observed_r, 3), " (rescaled: ", round(r_rescaled, 3), ")")
		} else {
			# Just observed
			vlines <- rbind(vlines, data.frame(
				xintercept = c(observed_r),
				label = factor(c("Observed Correlation"),
							   levels = c("Theoretical Minimum", "Theoretical Maximum", "95% CI Lower", "95% CI Upper", 
							   		   "Observed Correlation"))
			))
			subtitle <- paste0("Observed r: ", round(observed_r, 3))
		}
	} else {
		subtitle <- NULL
	}
	
	# Create the plot
	p <- ggplot(df, aes(x = r)) +
		geom_histogram(aes(y = ..density..), bins = 30,
					   fill = "lightblue", color = "white", alpha = 0.7) +
		geom_density(color = "darkblue", size = 1) +
		geom_vline(data = vlines,
				   aes(xintercept = xintercept, color = label, linetype = label),
				   size = 1) +
		scale_color_manual(name = "Reference Lines", 
						   values = c("Theoretical Minimum" = "red", 
						   		   "Theoretical Maximum" = "green", 
						   		   "95% CI Lower" = "purple", 
						   		   "95% CI Upper" = "purple",
						   		   "Observed Correlation" = "black")) +
		scale_linetype_manual(name = "Reference Lines",
							  values = c("Theoretical Minimum" = "dashed", 
							  		   "Theoretical Maximum" = "dashed", 
							  		   "95% CI Lower" = "dotted", 
							  		   "95% CI Upper" = "dotted",
							  		   "Observed Correlation" = "solid")) +
		labs(title = main,
			 subtitle = subtitle,
			 x = "Pearson's r",
			 y = "Density") +
		xlim(x_lower, x_upper) +
		theme_minimal()
	
	return(p)
}

# -----------------------------------------------------------------------------
# Function to plot a marginal distribution as a bar plot
#
# Arguments:
#   counts - Vector of category counts
#   varname - Variable name for plot labels
#
# Returns:
#   ggplot object
# -----------------------------------------------------------------------------
plot_marginal_distribution <- function(counts, varname = "X") {
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
# Function to create a summary plot comparing theoretical bounds and simulated ranges
#
# Arguments:
#   summary_df - Data frame with simulation summary statistics
#
# Returns:
#   ggplot object
# -----------------------------------------------------------------------------
plot_bounds_summary <- function(summary_df) {
	p <- ggplot(summary_df, aes(x = factor(sample_size))) +
		geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci, color = "Simulated 95% CI"), width = 0.2) +
		geom_point(aes(y = median_r, color = "Median Simulated r"), size = 3) +
		geom_point(aes(y = r_min, color = "Theoretical Minimum"), shape = 17, size = 3) +
		geom_point(aes(y = r_max, color = "Theoretical Maximum"), shape = 17, size = 3) +
		facet_wrap(~scenario, scales = "free_y") +
		labs(x = "Sample Size", y = "Pearson's r",
			 title = "Summary of Theoretical Bounds and Simulated Distribution") +
		scale_color_manual(name = "Legend",
						   values = c("Simulated 95% CI" = "blue",
						   		   "Median Simulated r" = "blue",
						   		   "Theoretical Minimum" = "red",
						   		   "Theoretical Maximum" = "green")) +
		theme_minimal()
	
	return(p)
}

# -----------------------------------------------------------------------------
# Function to plot comparison of theoretical and empirical ranges
#
# Arguments:
#   results - Data frame with theoretical and empirical ranges by scenario
#
# Returns:
#   ggplot object
# -----------------------------------------------------------------------------
plot_range_comparison <- function(results) {
	# Convert to long format for plotting
	results_long <- results %>%
		tidyr::pivot_longer(cols = c("theo_range", "emp_range"), 
							names_to = "Type", 
							values_to = "Range")
	
	# Create the plot
	p <- ggplot(results_long, aes(x = Scenario, y = Range, fill = Type)) +
		geom_bar(stat = "identity", position = "dodge") +
		labs(title = "Range of Pearson's r by Marginal Scenario",
			 y = "Range (Max - Min)", x = "Scenario") +
		scale_fill_manual(name = "Range Type",
						  labels = c("theo_range" = "Theoretical", "emp_range" = "Empirical"),
						  values = c("theo_range" = "darkblue", "emp_range" = "orange")) +
		theme_minimal()
	
	return(p)
}

# -----------------------------------------------------------------------------
# Function to display paired marginal distributions side by side
#
# Arguments:
#   countsX - Vector of category counts for X
#   countsY - Vector of category counts for Y
#
# Returns:
#   Arranged grid of ggplot objects
# -----------------------------------------------------------------------------
plot_paired_marginals <- function(countsX, countsY) {
	pX <- plot_marginal_distribution(countsX, varname = "X")
	pY <- plot_marginal_distribution(countsY, varname = "Y")
	grid.arrange(pX, pY, ncol = 2)
}

# -----------------------------------------------------------------------------
# Function to create a boxplot of simulated r distributions
#
# Arguments:
#   sim_r_df - Data frame with simulated r values and grouping variables
#
# Returns:
#   ggplot object
# -----------------------------------------------------------------------------
plot_sim_boxplot <- function(sim_r_df) {
	p_box <- ggplot(sim_r_df, aes(x = factor(sample_size), y = r, fill = factor(sample_size))) +
		geom_boxplot() +
		facet_wrap(~scenario, scales = "free_y") +
		labs(x = "Sample Size", y = "Simulated Pearson's r",
			 title = "Boxplot of Simulated r Distributions") +
		theme_minimal() +
		guides(fill = FALSE)
	
	return(p_box)
}
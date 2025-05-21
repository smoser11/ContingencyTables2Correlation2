# correlation_matrix_example.R
#
# Example usage of correlation matrix testing functions
#
# Author: [Your Name]
# Date: March 2, 2025

# Load required libraries
library(dplyr)
library(ggplot2)
library(gridExtra)
library(Matrix)
library(matrixcalc)
library(reshape2)

# Source required functions
source("correlation_bounds_core.R")
source("correlation_bounds_bes.R") 
source("correlation_matrix_test.R")

# Function to create example data for testing
create_example_dataset <- function(n_vars = 15, n_obs = 1000, seed = 123) {
	# Set seed for reproducibility
	set.seed(seed)
	
	# Create variable combinations for pairwise correlations
	var_pairs <- expand.grid(var1 = 1:n_vars, var2 = 1:n_vars) %>%
		filter(var1 < var2)  # Only keep upper triangle
	
	# Initialize results data frame
	results <- data.frame()
	
	# Process each variable pair
	for (i in 1:nrow(var_pairs)) {
		var1 <- var_pairs$var1[i]
		var2 <- var_pairs$var2[i]
		
		# Generate random marginal distributions for categorical variables
		# For var1: 3-5 categories
		# For var2: 4-7 categories
		var1_cats <- sample(3:5, 1)
		var2_cats <- sample(4:7, 1)
		
		# Randomly determine if variables start at 0 or 1
		var1_start <- sample(0:1, 1)
		var2_start <- sample(0:1, 1)
		
		# Generate random marginal distributions
		var1_probs <- runif(var1_cats)
		var1_probs <- var1_probs / sum(var1_probs)
		var1_counts <- round(var1_probs * n_obs)
		# Adjust to ensure sum equals n_obs
		diff <- n_obs - sum(var1_counts)
		var1_counts[1] <- var1_counts[1] + diff
		
		var2_probs <- runif(var2_cats)
		var2_probs <- var2_probs / sum(var2_probs)
		var2_counts <- round(var2_probs * n_obs)
		# Adjust to ensure sum equals n_obs
		diff <- n_obs - sum(var2_counts)
		var2_counts[1] <- var2_counts[1] + diff
		
		# Calculate theoretical bounds
		r_min <- min_corr_bound(var1_counts, var2_counts, sample_size = n_obs)
		r_max <- max_corr_bound(var1_counts, var2_counts, sample_size = n_obs)
		
		# Generate a random correlation within the bounds
		# With 70% chance near the bounds, 30% chance in the middle
		if (runif(1) < 0.7) {
			if (runif(1) < 0.5) {
				# Near r_min
				corr <- r_min + runif(1) * (r_max - r_min) * 0.2
			} else {
				# Near r_max
				corr <- r_max - runif(1) * (r_max - r_min) * 0.2
			}
		} else {
			# In the middle
			corr <- r_min + runif(1) * (r_max - r_min)
		}
		
		# Create row for this variable pair
		row <- list(
			var1 = var1,
			var2 = var2,
			var1cats = var1_cats,
			var2cats = var2_cats,
			nobs = n_obs,
			corr = corr,
			r_min = r_min,
			r_max = r_max
		)
		
		# Add frequency columns for var1
		for (j in 0:10) {
			col_name <- paste0("var1freq", j)
			if (j >= var1_start && j < var1_start + var1_cats) {
				index <- j - var1_start + 1
				row[[col_name]] <- var1_counts[index]
			} else {
				row[[col_name]] <- 0
			}
		}
		
		# Add frequency columns for var2
		for (j in 0:10) {
			col_name <- paste0("var2freq", j)
			if (j >= var2_start && j < var2_start + var2_cats) {
				index <- j - var2_start + 1
				row[[col_name]] <- var2_counts[index]
			} else {
				row[[col_name]] <- 0
			}
		}
		
		# Convert to data frame and add to results
		row_df <- as.data.frame(row)
		results <- rbind(results, row_df)
	}
	
	# Calculate rescaled correlations
	for (i in 1:nrow(results)) {
		row <- results[i, ]
		if (row$corr < 0) {
			# For negative correlations, rescale between r_min and 0
			if (row$r_min < 0) {
				r_rescaled <- (-1 / row$r_min) * row$corr
			} else {
				r_rescaled <- -1  # Default to -1 in this edge case
			}
		} else if (row$corr > 0) {
			# For positive correlations, rescale between 0 and r_max
			if (row$r_max > 0) {
				r_rescaled <- (1 / row$r_max) * row$corr
			} else {
				r_rescaled <- 1  # Default to 1 in this edge case
			}
		} else {
			# If correlation is exactly 0, keep it as 0
			r_rescaled <- 0
		}
		results$r_rescaled[i] <- r_rescaled
	}
	
	return(results)
}

# Example 1: Test correlation matrix properties with a small dataset
demo_small_dataset <- function() {
	cat("Creating a small example dataset with 6 variables...\n")
	example_data <- create_example_dataset(n_vars = 6, n_obs = 1000, seed = 456)
	
	cat("Original correlations:\n")
	print(example_data[, c("var1", "var2", "corr", "r_min", "r_max", "r_rescaled")])
	
	# Construct both correlation matrices
	cat("\nConstructing correlation matrices...\n")
	orig_matrix <- construct_correlation_matrix(example_data, use_rescaled = FALSE)
	rescaled_matrix <- construct_correlation_matrix(example_data, use_rescaled = TRUE)
	
	cat("\nOriginal correlation matrix:\n")
	print(round(orig_matrix, 3))
	
	cat("\nRescaled correlation matrix:\n")
	print(round(rescaled_matrix, 3))
	
	# Test matrix properties
	cat("\nTesting properties of original matrix:\n")
	orig_props <- test_matrix_properties(orig_matrix)
	cat("Symmetric:", orig_props$is_symmetric, "\n")
	cat("Positive semidefinite:", orig_props$is_positive_semidefinite, "\n")
	cat("Invertible:", orig_props$is_invertible, "\n")
	cat("Determinant:", orig_props$determinant, "\n")
	cat("Condition number:", orig_props$condition_number, "\n")
	cat("Min eigenvalue:", orig_props$min_eigenvalue, "\n")
	cat("Max eigenvalue:", orig_props$max_eigenvalue, "\n")
	
	cat("\nTesting properties of rescaled matrix:\n")
	rescaled_props <- test_matrix_properties(rescaled_matrix)
	cat("Symmetric:", rescaled_props$is_symmetric, "\n")
	cat("Positive semidefinite:", rescaled_props$is_positive_semidefinite, "\n")
	cat("Invertible:", rescaled_props$is_invertible, "\n")
	cat("Determinant:", rescaled_props$determinant, "\n")
	cat("Condition number:", rescaled_props$condition_number, "\n")
	cat("Min eigenvalue:", rescaled_props$min_eigenvalue, "\n")
	cat("Max eigenvalue:", rescaled_props$max_eigenvalue, "\n")
	
	# Visualize matrix comparison
	cat("\nVisualizing matrix comparison...\n")
	plots <- visualize_matrix_comparison(orig_matrix, rescaled_matrix)
	
	grid.arrange(
		plots$original, plots$rescaled, plots$difference,
		ncol = 3, widths = c(1, 1, 1)
	)
	
	return(list(
		data = example_data,
		orig_matrix = orig_matrix,
		rescaled_matrix = rescaled_matrix,
		orig_props = orig_props,
		rescaled_props = rescaled_props
	))
}

# Example 2: Run multiple trials with random subsets of variables
demo_random_trials <- function(n_trials = 50) {
	# Create a larger dataset
	cat("Creating a larger example dataset with 20 variables...\n")
	example_data <- create_example_dataset(n_vars = 20, n_obs = 1000, seed = 789)
	
	# Run random matrix tests
	cat("\nRunning", n_trials, "random trials...\n")
	test_results <- test_random_correlation_matrices(
		example_data, n_trials = n_trials, 
		min_vars = 3, max_vars = 15,
		seed = 123
	)
	
	# Summarize results
	cat("\nSummarizing results...\n")
	summary <- summarize_matrix_tests(test_results)
	
	# Print summary
	cat("\nSummary of", summary$n_trials, "trials:\n")
	print(summary)
	
	# Plot summarized results
	cat("\nPlotting summary results...\n")
	
	# Prepare data for bar chart
	compare_df <- data.frame(
		Property = rep(c("Positive Semidefinite", "Invertible"), 2),
		Type = c(rep("Original", 2), rep("Rescaled", 2)),
		Percentage = c(summary$orig_psd_percent, summary$orig_invertible_percent,
					   summary$rescaled_psd_percent, summary$rescaled_invertible_percent)
	)
	
	# Create grouped bar chart
	p <- ggplot(compare_df, aes(x = Property, y = Percentage, fill = Type)) +
		geom_bar(stat = "identity", position = "dodge") +
		geom_text(aes(label = sprintf("%.1f%%", Percentage)), 
				  position = position_dodge(width = 0.9), vjust = -0.5) +
		scale_fill_manual(values = c("Original" = "skyblue", "Rescaled" = "coral")) +
		labs(title = "Comparison of Matrix Properties",
			 subtitle = paste("Based on", summary$n_trials, "random trials"),
			 y = "Percentage of Matrices", x = "") +
		theme_minimal() +
		ylim(0, 110)  # Leave room for text labels
	
	print(p)
	
	return(list(
		data = example_data,
		test_results = test_results,
		summary = summary
	))
}

# Run demonstrations
if (!interactive()) {
	cat("========================================\n")
	cat("DEMONSTRATION 1: SMALL DATASET EXAMPLE\n")
	cat("========================================\n\n")
	small_results <- demo_small_dataset()
	
	cat("\n\n========================================\n")
	cat("DEMONSTRATION 2: RANDOM TRIALS\n")
	cat("========================================\n\n")
	random_results <- demo_random_trials(30)
	
	cat("\n\n========================================\n")
	cat("DEMONSTRATION 3: ANALYZING SPECIFIC CASES\n")
	cat("========================================\n\n")
	
	# Find cases where properties differ
	diff_cases <- random_results$test_results %>%
		filter(properties_differ)
	
	if (nrow(diff_cases) > 0) {
		cat("Found", nrow(diff_cases), "cases where matrix properties differ between original and rescaled correlations.\n")
		
		# Select an interesting case
		case <- diff_cases %>%
			arrange(desc(n_variables)) %>%
			slice(1)
		
		cat("\nAnalyzing a case with", case$n_variables, "variables where:\n")
		cat("- Original matrix positive semidefinite:", case$orig_psd, "\n")
		cat("- Rescaled matrix positive semidefinite:", case$rescaled_psd, "\n")
		cat("- Original matrix invertible:", case$orig_invertible, "\n")
		cat("- Rescaled matrix invertible:", case$rescaled_invertible, "\n")
		
		cat("\nNote: In a real application with BES data, we would select the specific variables\n")
		cat("and analyze their correlation matrices in detail. For this example, we don't have\n")
		cat("the mapping of which variables were used in each random trial.\n")
	} else {
		cat("No cases found where matrix properties differ between original and rescaled correlations.\n")
	}
}




# Source the required files
source("correlation_bounds_core.R")
source("correlation_bounds_bes.R")
source("correlation_matrix_test.R")

# Process your BES data
all_results <- analyze_all_corr_bounds(bes_data)

# Run multiple random trials
test_results <- test_random_correlation_matrices(
	all_results, 
	n_trials = 1000,  # Number of random trials 
	min_vars = 10,   # Minimum variables per trial
	max_vars = 100   # Maximum variables per trial
)

# Get summary statistics
summary <- summarize_matrix_tests(test_results)
print(summary)



# Select specific variables for detailed analysis
selected_vars <- c(1, 5, 10, 15, 20)  # Replace with your variable IDs
specific_analysis <- analyze_specific_matrix(all_results, selected_vars)

# Compare original vs rescaled matrices
matrix_plots <- visualize_matrix_comparison(
	specific_analysis$original$matrix, 
	specific_analysis$rescaled$matrix
)

# Display the plots
grid.arrange(
	matrix_plots$original, 
	matrix_plots$rescaled, 
	matrix_plots$difference,
	ncol = 3
)

# Compare matrix properties
cat("Original matrix properties:\n")
print(specific_analysis$original$properties)

cat("\nRescaled matrix properties:\n")
print(specific_analysis$rescaled$properties)

# Check if there are differences in key properties
if (specific_analysis$comparison$psd_difference) {
	cat("\nThe matrices differ in positive semidefiniteness!\n")
}
if (specific_analysis$comparison$invertibility_difference) {
	cat("\nThe matrices differ in invertibility!\n")
}


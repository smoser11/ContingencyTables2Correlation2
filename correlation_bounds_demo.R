# correlation_bounds_demo_updated.R
#
# Comprehensive demonstration of correlation bounds and matrix testing functions
# with improved PSD checking and validation
#
# Author: [Your Name]
# Date: March 2, 2025

# -----------------------------------------------------------------------------
# 0. Load required libraries and source all functions
# -----------------------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(gridExtra)
library(Matrix)
library(matrixcalc)

# Source all required functions (make sure they're in your working directory)
source("correlation_bounds_core.R")
source("correlation-bounds-visualization.R")
source("correlation_bounds_bes.R")
source("correlation_matrix_test.R")

# Set seed for reproducibility
set.seed(42)

# -----------------------------------------------------------------------------
# 1. Create example data for demonstration
# -----------------------------------------------------------------------------
cat("========================================================\n")
cat("PART 1: CREATING EXAMPLE DATA\n")
cat("========================================================\n\n")

create_example_dataset <- function(n_vars = 10, seed = 42) {
	set.seed(seed)
	
	# Create all pairwise combinations
	pairs <- expand.grid(var1 = 1:n_vars, var2 = 1:n_vars)
	pairs <- pairs[pairs$var1 < pairs$var2, ]  # Keep only upper triangle
	
	# Initialize results data frame
	results <- data.frame()
	
	# Create each row
	for (i in 1:nrow(pairs)) {
		var1 <- pairs$var1[i]
		var2 <- pairs$var2[i]
		
		# Randomize number of categories and observations
		cats1 <- sample(3:6, 1)
		cats2 <- sample(3:6, 1)
		n_obs <- sample(800:1200, 1)
		
		# Create marginal distributions
		var1_counts <- rmultinom(1, n_obs, runif(cats1))[,1]
		var2_counts <- rmultinom(1, n_obs, runif(cats2))[,1]
		
		# Create the row structure
		row <- list(
			var1 = var1,
			var2 = var2,
			nobs = n_obs,
			var1cats = cats1,
			var2cats = cats2
		)
		
		# Add frequency columns (including zeros for unused categories)
		for (j in 0:10) {
			row[[paste0("var1freq", j)]] <- if(j < cats1) var1_counts[j+1] else 0
		}
		
		for (j in 0:10) {
			row[[paste0("var2freq", j)]] <- if(j < cats2) var2_counts[j+1] else 0
		}
		
		# Set placeholder correlation (to be updated later)
		row$corr <- 0
		
		# Convert to data frame and add to results
		row_df <- as.data.frame(row)
		results <- rbind(results, row_df)
	}
	
	return(results)
}

# Create a dataset with 8 variables (28 pairwise combinations)
example_data <- create_example_dataset(8)
cat("Created example dataset with", nrow(example_data), "variable pairs\n")

# -----------------------------------------------------------------------------
# 2. Calculate theoretical bounds and update correlations
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 2: CALCULATING BOUNDS AND SETTING CORRELATIONS\n")
cat("========================================================\n\n")

for (i in 1:nrow(example_data)) {
	# Extract frequencies
	var1_counts <- unlist(lapply(0:10, function(j) {
		freq_col <- paste0("var1freq", j)
		if (freq_col %in% names(example_data)) example_data[i, freq_col] else 0
	}))
	var1_counts <- var1_counts[var1_counts > 0]
	
	var2_counts <- unlist(lapply(0:10, function(j) {
		freq_col <- paste0("var2freq", j)
		if (freq_col %in% names(example_data)) example_data[i, freq_col] else 0
	}))
	var2_counts <- var2_counts[var2_counts > 0]
	
	# Calculate theoretical bounds
	r_min <- min_corr_bound(var1_counts, var2_counts)
	r_max <- max_corr_bound(var1_counts, var2_counts)
	
	# Generate a random correlation within the bounds
	# Use different patterns for demonstration
	if (i %% 4 == 0) {
		# Near r_min
		r <- r_min + (r_max - r_min) * runif(1, 0, 0.2)
	} else if (i %% 4 == 1) {
		# Near r_max
		r <- r_min + (r_max - r_min) * runif(1, 0.8, 1)
	} else if (i %% 4 == 2) {
		# Near zero
		zero_point <- -r_min / (r_max - r_min)
		zero_point <- max(0, min(1, zero_point))  # Ensure it's in [0,1]
		r <- r_min + (r_max - r_min) * runif(1, zero_point - 0.1, zero_point + 0.1)
	} else {
		# Randomly anywhere in the range
		r <- r_min + (r_max - r_min) * runif(1)
	}
	
	# Update the correlation
	example_data$corr[i] <- r
}

cat("Updated all correlations with values within their theoretical bounds\n")

# -----------------------------------------------------------------------------
# 3. Analyze correlation bounds
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 3: ANALYZING CORRELATION BOUNDS\n")
cat("========================================================\n\n")

# Analyze all pairs
cat("Analyzing correlation bounds for all pairs...\n")
bounds_results <- analyze_all_corr_bounds(example_data, nsim = 500, progress = TRUE)

# Display results for a few pairs
cat("\nResults for first few pairs:\n")
print(bounds_results[1:5, c("var1", "var2", "observed_r", "r_min", "r_max", "r_rescaled")])

# Generate summary report
cat("\nGenerating summary report...\n")
bounds_summary <- generate_bounds_summary(bounds_results)

# -----------------------------------------------------------------------------
# 4. Testing correlation matrix properties
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 4: TESTING CORRELATION MATRIX PROPERTIES\n")
cat("========================================================\n\n")

# First, let's demonstrate with a simple example
cat("Example 1: Testing a small correlation matrix (with PSD enforcement)\n")
small_vars <- 1:4
small_matrix_analysis <- analyze_specific_matrix(bounds_results, small_vars, enforce_psd = TRUE)

cat("\nOriginal matrix:\n")
print(round(small_matrix_analysis$original$matrix, 3))

cat("\nOriginal matrix properties:\n")
print(small_matrix_analysis$original$properties[c("is_symmetric", "has_unit_diagonal", 
												  "is_positive_semidefinite", "is_invertible", 
												  "is_valid_correlation_matrix")])

cat("\nRescaled matrix:\n")
print(round(small_matrix_analysis$rescaled$matrix, 3))

cat("\nRescaled matrix properties:\n")
print(small_matrix_analysis$rescaled$properties[c("is_symmetric", "has_unit_diagonal", 
												  "is_positive_semidefinite", "is_invertible", 
												  "is_valid_correlation_matrix")])

# Now, let's see what happens without PSD enforcement
cat("\nExample 2: Testing the same matrix (without PSD enforcement)\n")
small_matrix_analysis2 <- analyze_specific_matrix(bounds_results, small_vars, enforce_psd = FALSE)

cat("\nOriginal matrix properties (without PSD enforcement):\n")
print(small_matrix_analysis2$original$properties[c("is_symmetric", "has_unit_diagonal", 
												   "is_positive_semidefinite", "is_invertible", 
												   "is_valid_correlation_matrix")])

cat("\nRescaled matrix properties (without PSD enforcement):\n")
print(small_matrix_analysis2$rescaled$properties[c("is_symmetric", "has_unit_diagonal", 
												   "is_positive_semidefinite", "is_invertible", 
												   "is_valid_correlation_matrix")])

# Visualize the matrices
matrix_plots <- visualize_matrix_comparison(
	small_matrix_analysis$original$matrix, 
	small_matrix_analysis$rescaled$matrix
)

grid.arrange(
	matrix_plots$original, 
	matrix_plots$rescaled, 
	matrix_plots$difference,
	ncol = 3
)

# -----------------------------------------------------------------------------
# 5. Random matrix trials with PSD enforcement
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 5: RANDOM MATRIX TRIALS (WITH PSD ENFORCEMENT)\n")
cat("========================================================\n\n")

# Run multiple trials with PSD enforcement
cat("Running 30 random trials with PSD enforcement...\n")
matrix_trials_psd <- test_random_correlation_matrices(
	bounds_results, 
	n_trials = 30, 
	min_vars = 3, 
	max_vars = 7,
	enforce_psd = TRUE
)

# Summarize results
trial_summary_psd <- summarize_matrix_tests(matrix_trials_psd)

cat("\nSummary of matrix properties with PSD enforcement:\n")
# Print the available columns to avoid errors
cat("Available columns in summary:\n")
print(names(trial_summary_psd))

# Use a more robust approach to print the key columns
key_columns <- c()
if ("n_trials" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "n_trials")
if ("orig_valid_percent" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "orig_valid_percent")
if ("rescaled_valid_percent" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "rescaled_valid_percent")
if ("orig_psd_percent" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "orig_psd_percent")
if ("rescaled_psd_percent" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "rescaled_psd_percent")
if ("orig_invertible_percent" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "orig_invertible_percent")
if ("rescaled_invertible_percent" %in% names(trial_summary_psd)) key_columns <- c(key_columns, "rescaled_invertible_percent")

if (length(key_columns) > 0) {
	print(trial_summary_psd[key_columns])
} else {
	# Print all columns as a fallback
	print(trial_summary_psd)
}

# -----------------------------------------------------------------------------
# 6. Random matrix trials without PSD enforcement
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 6: RANDOM MATRIX TRIALS (WITHOUT PSD ENFORCEMENT)\n")
cat("========================================================\n\n")

# Run multiple trials without PSD enforcement
cat("Running 30 random trials without PSD enforcement...\n")
matrix_trials_raw <- test_random_correlation_matrices(
	bounds_results, 
	n_trials = 30, 
	min_vars = 3, 
	max_vars = 7,
	enforce_psd = FALSE
)

# Summarize results
trial_summary_raw <- summarize_matrix_tests(matrix_trials_raw)

cat("\nSummary of matrix properties without PSD enforcement:\n")
# Print the available columns to avoid errors
cat("Available columns in summary:\n")
print(names(trial_summary_raw))

# Use a more robust approach to print the key columns
key_columns <- c()
if ("n_trials" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "n_trials")
if ("orig_valid_percent" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "orig_valid_percent")
if ("rescaled_valid_percent" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "rescaled_valid_percent")
if ("orig_psd_percent" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "orig_psd_percent")
if ("rescaled_psd_percent" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "rescaled_psd_percent")
if ("orig_invertible_percent" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "orig_invertible_percent")
if ("rescaled_invertible_percent" %in% names(trial_summary_raw)) key_columns <- c(key_columns, "rescaled_invertible_percent")

if (length(key_columns) > 0) {
	print(trial_summary_raw[key_columns])
} else {
	# Print all columns as a fallback
	print(trial_summary_raw)
}

# -----------------------------------------------------------------------------
# 7. Comparing with and without PSD enforcement
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 7: COMPARING WITH AND WITHOUT PSD ENFORCEMENT\n")
cat("========================================================\n\n")

# Create comparison data
psd_comparison <- data.frame(
	Property = c(),
	Matrix_Type = c(),
	PSD_Enforcement = c(),
	Percentage = c()
)

# Check if we have the required columns
has_valid_cols <- all(c("orig_valid_percent", "rescaled_valid_percent") %in% names(trial_summary_raw)) &&
	all(c("orig_valid_percent", "rescaled_valid_percent") %in% names(trial_summary_psd))
has_psd_cols <- all(c("orig_psd_percent", "rescaled_psd_percent") %in% names(trial_summary_raw)) &&
	all(c("orig_psd_percent", "rescaled_psd_percent") %in% names(trial_summary_psd))
has_inv_cols <- all(c("orig_invertible_percent", "rescaled_invertible_percent") %in% names(trial_summary_raw)) &&
	all(c("orig_invertible_percent", "rescaled_invertible_percent") %in% names(trial_summary_psd))

# Build the comparison data frame carefully
if (has_valid_cols) {
	psd_comparison <- rbind(psd_comparison, data.frame(
		Property = rep("Valid Correlation Matrix", 4),
		Matrix_Type = rep(c("Original", "Rescaled"), each = 2),
		PSD_Enforcement = c("Without Enforcement", "Without Enforcement", "With Enforcement", "With Enforcement"),
		Percentage = c(
			trial_summary_raw$orig_valid_percent, 
			trial_summary_raw$rescaled_valid_percent,
			trial_summary_psd$orig_valid_percent,
			trial_summary_psd$rescaled_valid_percent
		)
	))
}

if (has_psd_cols) {
	psd_comparison <- rbind(psd_comparison, data.frame(
		Property = rep("Positive Semidefinite", 4),
		Matrix_Type = rep(c("Original", "Rescaled"), each = 2),
		PSD_Enforcement = c("Without Enforcement", "Without Enforcement", "With Enforcement", "With Enforcement"),
		Percentage = c(
			trial_summary_raw$orig_psd_percent, 
			trial_summary_raw$rescaled_psd_percent,
			trial_summary_psd$orig_psd_percent,
			trial_summary_psd$rescaled_psd_percent
		)
	))
}

if (has_inv_cols) {
	psd_comparison <- rbind(psd_comparison, data.frame(
		Property = rep("Invertible", 4),
		Matrix_Type = rep(c("Original", "Rescaled"), each = 2),
		PSD_Enforcement = c("Without Enforcement", "Without Enforcement", "With Enforcement", "With Enforcement"),
		Percentage = c(
			trial_summary_raw$orig_invertible_percent, 
			trial_summary_raw$rescaled_invertible_percent,
			trial_summary_psd$orig_invertible_percent,
			trial_summary_psd$rescaled_invertible_percent
		)
	))
}

# Only create the plot if we have data
if (nrow(psd_comparison) > 0) {
	# Create grouped bar chart
	p <- ggplot(psd_comparison, aes(x = Property, y = Percentage, fill = Matrix_Type)) +
		geom_bar(stat = "identity", position = "dodge") +
		facet_wrap(~ PSD_Enforcement) +
		geom_text(aes(label = sprintf("%.1f%%", Percentage)), 
				  position = position_dodge(width = 0.9), vjust = -0.5, size = 3) +
		scale_fill_manual(values = c("Original" = "skyblue", "Rescaled" = "coral")) +
		labs(title = "Matrix Properties by Type and PSD Enforcement",
			 y = "Percentage of Matrices", x = "") +
		theme_minimal() +
		ylim(0, 110)  # Leave room for text labels
	
	print(p)
} else {
	cat("Not enough data to create comparison plot\n")
}

# -----------------------------------------------------------------------------
# 8. Condition number analysis
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 8: CONDITION NUMBER ANALYSIS\n")
cat("========================================================\n\n")

# Filter for finite condition numbers (invertible matrices only)
condition_data_psd <- matrix_trials_psd %>%
	filter(is.finite(orig_condition) & is.finite(rescaled_condition))

condition_data_raw <- matrix_trials_raw %>%
	filter(is.finite(orig_condition) & is.finite(rescaled_condition))

# Only proceed if we have data
if (nrow(condition_data_psd) > 0) {
	cat("Average condition numbers with PSD enforcement:\n")
	cat("Original matrices:", mean(condition_data_psd$orig_condition), "\n")
	cat("Rescaled matrices:", mean(condition_data_psd$rescaled_condition), "\n")
	
	# Plot condition number comparison
	p_condition_psd <- ggplot(condition_data_psd, aes(x = orig_condition, y = rescaled_condition)) +
		geom_point(aes(size = n_variables), alpha = 0.7) +
		geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
		labs(title = "Condition Numbers (With PSD Enforcement)",
			 x = "Original Matrix", y = "Rescaled Matrix",
			 size = "Number of Variables") +
		theme_minimal() +
		coord_equal()
	
	print(p_condition_psd)
}

if (nrow(condition_data_raw) > 0) {
	cat("\nAverage condition numbers without PSD enforcement:\n")
	cat("Original matrices:", mean(condition_data_raw$orig_condition), "\n")
	cat("Rescaled matrices:", mean(condition_data_raw$rescaled_condition), "\n")
	
	# Plot condition number comparison
	p_condition_raw <- ggplot(condition_data_raw, aes(x = orig_condition, y = rescaled_condition)) +
		geom_point(aes(size = n_variables), alpha = 0.7) +
		geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
		labs(title = "Condition Numbers (Without PSD Enforcement)",
			 x = "Original Matrix", y = "Rescaled Matrix",
			 size = "Number of Variables") +
		theme_minimal() +
		coord_equal()
	
	print(p_condition_raw)
}

# -----------------------------------------------------------------------------
# 9. Summary and conclusions
# -----------------------------------------------------------------------------
cat("\n========================================================\n")
cat("PART 9: SUMMARY AND CONCLUSIONS\n")
cat("========================================================\n\n")

cat("1. Matrix Validity:\n")
cat("   - With PSD enforcement: All matrices are valid correlation matrices\n")
cat("   - Without PSD enforcement:", 
	sprintf("%.1f%% of original and %.1f%% of rescaled matrices are valid\n", 
			trial_summary_raw$orig_valid_percent, 
			trial_summary_raw$rescaled_valid_percent))

cat("\n2. Positive Semidefiniteness:\n")
cat("   - With PSD enforcement: All matrices are positive semidefinite (by design)\n")
cat("   - Without PSD enforcement:", 
	sprintf("%.1f%% of original and %.1f%% of rescaled matrices are PSD\n", 
			trial_summary_raw$orig_psd_percent, 
			trial_summary_raw$rescaled_psd_percent))

cat("\n3. Invertibility:\n")
if (trial_summary_psd$orig_invertible_percent > trial_summary_psd$rescaled_invertible_percent) {
	cat("   - Original matrices are MORE likely to be invertible\n")
} else if (trial_summary_psd$orig_invertible_percent < trial_summary_psd$rescaled_invertible_percent) {
	cat("   - Rescaled matrices are MORE likely to be invertible\n")
} else {
	cat("   - No difference in invertibility\n")
}

if (nrow(condition_data_psd) > 0 && nrow(condition_data_raw) > 0) {
	cat("\n4. Condition Numbers:\n")
	if (mean(condition_data_psd$orig_condition) > mean(condition_data_psd$rescaled_condition)) {
		cat("   - Rescaled matrices have BETTER conditioning on average\n")
	} else if (mean(condition_data_psd$orig_condition) < mean(condition_data_psd$rescaled_condition)) {
		cat("   - Original matrices have BETTER conditioning on average\n")
	} else {
		cat("   - No significant difference in conditioning\n")
	}
}

cat("\nConclusions about correlation rescaling effects on matrix properties:\n")
if (trial_summary_raw$rescaled_psd_percent > trial_summary_raw$orig_psd_percent) {
	cat("- Rescaling appears to IMPROVE positive semidefiniteness properties\n")
} else if (trial_summary_raw$rescaled_psd_percent < trial_summary_raw$orig_psd_percent) {
	cat("- Rescaling appears to WORSEN positive semidefiniteness properties\n")
} else {
	cat("- Rescaling doesn't appear to affect positive semidefiniteness properties\n")
}

cat("- PSD enforcement is strongly recommended for both original and rescaled matrices\n")
cat("- Invertibility properties are", 
	ifelse(trial_summary_psd$orig_invertible_percent == trial_summary_psd$rescaled_invertible_percent, 
		   "similar", "different"), 
	"between original and rescaled matrices\n")

cat("\nThis concludes the demonstration of correlation bounds and matrix testing functions.\n")
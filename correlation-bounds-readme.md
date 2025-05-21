# Correlation Bounds for Categorical Variables

This repository contains a collection of R functions and demonstrations for exploring the theoretical bounds of Pearson's correlation coefficient when analyzing categorical variables with fixed marginal distributions.

## Overview

When working with categorical variables (especially ordinal ones), there are theoretical constraints on the possible values of Pearson's correlation coefficient. These constraints depend solely on the marginal distributions of the variables.

This project provides tools to:

1. Calculate the theoretical minimum and maximum possible correlation given specific marginal distributions
2. Simulate permutation distributions of correlations under the null hypothesis
3. Visualize these bounds and distributions
4. Explore how these bounds change with different distributions and sample sizes

## File Structure

* `correlation_bounds_core.R` - Core functions for computing correlation bounds and simulations
* `correlation_bounds_visualization.R` - Functions for visualizing the results
* `correlation_bounds_examples.R` - Examples and demonstrations of various scenarios

## Key Concepts

### Theoretical Bounds

The correlation coefficient r is bounded by mathematical constraints when marginal distributions are fixed:

* **Maximum correlation** is achieved through comonotonic coupling (sorting both variables in the same direction)
* **Minimum correlation** is achieved through anti-comonotonic coupling (sorting one variable in reverse order)

### Permutation Distribution

The permutation distribution represents the distribution of correlation coefficients that would be observed under the null hypothesis of independence between variables. We compute this by randomly permuting one variable while keeping the marginals fixed.

## Examples Included

1. **Basic Demonstration** - Explores uniform and extreme distributions at various sample sizes
2. **Range Comparison** - Compares theoretical and empirical correlation ranges across different marginal scenarios
3. **Category Count Exploration** - Examines how the number of categories affects correlation bounds
4. **Extremal Bounds Investigation** - Identifies cases where empirical bounds closely approximate theoretical bounds

## Usage

To use this package:

```r
# Source the required files
source("correlation_bounds_core.R")
source("correlation-bounds-visualization.R")
source("correlation_bounds_examples.R")

# Run all examples
results <- run_all_examples()

# Or run a specific example
results <- basic_demonstration()
```

### Example ###

```r
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


# Customize a plot
summary_plot <- plot_bounds_summary(summary_df) +
  theme_bw() +
  ggtitle("Custom Title") +
  scale_color_brewer(palette = "Set1")
print(summary_plot)

```

```{r warning=FALSE, message=FALSE}
# Process your BES data
results <- analyze_all_corr_bounds(bes_data)

# Generate the enhanced summary with significance comparison
summary_report <- generate_bounds_summary(results)

# Identify cases where t-test and randomization test disagree
disagreement <- subset(summary_report, !tests_agree)

# Visualize the significance comparison
plot_significance_comparison(summary_report)

# Examine relationship between theoretical bounds and significance
bounds_sig_plot <- plot_bounds_significance(summary_report)
print(bounds_sig_plot)

```
## Requirements

The code requires the following R packages:
* ggplot2
* dplyr
* tidyr
* gridExtra

## Mathematical Background

The theoretical bounds are based on the Fréchet–Hoeffding bounds for copulas, adapted specifically for categorical variables. The maximum correlation is achieved when both variables are sorted in the same direction (comonotonic), while the minimum correlation is achieved when they are sorted in opposite directions (anti-comonotonic).

## References

1. Fréchet, M. (1951). Sur les tableaux de corrélation dont les marges sont données. *Annales de l'Université de Lyon, Section A*, 9, 53-77.
2. Hoeffding, W. (1940). Masstabinvariante Korrelationstheorie. *Schriften des Mathematischen Instituts und des Instituts für Angewandte Mathematik der Universität Berlin*, 5, 179-233.

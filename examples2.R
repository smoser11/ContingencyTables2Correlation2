# Assume df is a data frame with your r-values, and that r_min, r_max, and ci_bounds are defined.
# Also assume x_lower and x_upper are set to ensure the full range is shown.

# Create a data frame for the vertical lines
vlines <- data.frame(
	xintercept = c(r_min, r_max, ci_bounds[1], ci_bounds[2]),
	label = factor(c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"),
				   levels = c("Theoretical Min", "Theoretical Max", "95% CI Lower", "95% CI Upper"))
)



# Build the ggplot
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
	labs(title = "Empirical Distribution of Pearson's r",
		 x = "Pearson's r",
		 y = "Density") +
	xlim(x_lower, x_upper) +
	theme_minimal()

print(p)

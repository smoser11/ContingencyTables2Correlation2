######

library(dplyr)

# Function to convert contingency table to dataset
contingency_table_to_dataset <- function(table) {
	# Create an empty data frame
	dataset <- data.frame(X = integer(), Y = integer())
	
	# Get the dimensions of the table
	n_rows <- nrow(table)
	n_cols <- ncol(table)
	
	# Iterate over each cell of the table
	for (i in 1:n_rows) {
		for (j in 1:n_cols) {
			count <- table[i, j]
			if (count > 0) {
				# Append rows to dataset
				temp_df <- data.frame(X = rep(j, count), Y = rep(i, count))
				dataset <- bind_rows(dataset, temp_df)
			}
		}
	}
	
	return(dataset)
}

# Example contingency table
contingency_table <- matrix(c(
	10, 20, 30, 40,  # Corresponds to Y_1
	50, 60, 70, 80,  # Corresponds to Y_2
	90, 100, 110, 120, # Corresponds to Y_3
	130, 140, 150, 160 # Corresponds to Y_4
), nrow = 4, byrow = TRUE)

contingency_table <- contingency_table/10
contingency_table

sum(contingency_table)


# Convert the contingency table to a dataset
dataset <- contingency_table_to_dataset(contingency_table)

# Print the first few rows of the dataset
head(dataset)
contingency_table
dataset

cor(dataset)



###################
## FROM DATA 2 X-TAB


# Function to convert a dataset to a contingency table
dataset_to_contingency_table <- function(dataset) {
	# Use table() to create a contingency table from the dataset
	contingency_table <- table(dataset$Y, dataset$X)
	
	# Optionally, you can convert it to a matrix if needed
	contingency_matrix <- as.matrix(contingency_table)
	
	# Name the dimensions for clarity
	dimnames(contingency_matrix) <- list(
		paste("Y", 1:nrow(contingency_matrix), sep = "_"),
		paste("X", 1:ncol(contingency_matrix), sep = "_")
	)
	
	return(contingency_matrix)
}

# Example dataset
dataset <- data.frame(
	X = c(1, 2, 2, 2, 4, 4, 3, 2, 1, 1, 2, 3, 4, 1,4,4,4),
	Y = c(1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4, 1, 2,4,4,4)
)

dataset <- dataset %>% arrange(X,Y)

dataset# Convert the dataset to a contingency table
contingency_table <- dataset_to_contingency_table(dataset)

dataset
# Print the contingency table
print(contingency_table)
cor(dataset)



##########################
##### no numbers

# Load necessary libraries
library(dplyr)

# Function to convert contingency table to dataset
contingency_to_dataset <- function(contingency_table) {
	# Get the dimension names, assuming they might be NULL if not set
	row_names <- rownames(contingency_table)
	col_names <- colnames(contingency_table)
	
	# If row or column names are not set, use default indices
	if (is.null(row_names)) row_names <- seq_len(nrow(contingency_table))
	if (is.null(col_names)) col_names <- seq_len(ncol(contingency_table))
	
	# Initialize vectors to store the resulting dataset
	data_x <- numeric()
	data_y <- numeric()
	
	# Loop through each element of the contingency table
	for (i in seq_len(nrow(contingency_table))) {
		for (j in seq_len(ncol(contingency_table))) {
			count <- contingency_table[i, j]
			if (count > 0) {
				data_x <- c(data_x, rep(col_names[j], count))
				data_y <- c(data_y, rep(row_names[i], count))
			}
		}
	}
	
	# Create a data frame from the vectors
	data_frame(X = data_x, Y = data_y)
}

# Example usage
# Define a contingency table as a matrix
contingency_table <- matrix(c(5, 4, 3, 1, 3, 0, 5, 2, 2, 1, 2, 3, 1, 2, 0, 4), 
							nrow = 4, byrow = TRUE,
							dimnames = list(c("Y_1", "Y_2", "Y_3", "Y_4"), 
											c("X_1", "X_2", "X_3", "X_4")))

contingency_table

sum(contingency_table)

# Convert the contingency table to a dataset
dataset <- contingency_to_dataset(contingency_table)
print(dataset)



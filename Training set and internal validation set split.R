# R Code:

# -------- Train / validation split script --------
set.seed(123456789)  # reproducible split
val_index <- sample(seq_len(nrow(final_data)),
                     size = round(nrow(final_data) * 0.40000))
train_data      <- final_data[-val_index, ]
validation_data <- final_data[ val_index, ]
cat("\n===== TRAIN_DATA (head) =====\n")
print(head(train_data))
cat("Rows :", nrow(train_data), "  Cols :", ncol(train_data), "\n")
cat("Numeric :", sum(sapply(train_data, is.numeric)),
    " Factor/Char :", sum(sapply(train_data, function(x) is.factor(x) || is.character(x))),
    " Missing :", sum(is.na(train_data)), "\n")
cat("\n===== VALIDATION_DATA (head) =====\n")
print(head(validation_data))
cat("Rows :", nrow(validation_data), "  Cols :", ncol(validation_data), "\n")
cat("Numeric :", sum(sapply(validation_data, is.numeric)),
    " Factor/Char :", sum(sapply(validation_data, function(x) is.factor(x) || is.character(x))),
    " Missing :", sum(is.na(validation_data)), "\n")



# R Code:

library(rms)
# Reset datadist and create new datadist from the training dataset
options(datadist = NULL)
ddist <- datadist(nomogram_data)
options(datadist = "ddist")

# Define the formula
formula <- as.formula("cam_icu_score ~ neurological_disease+ventilator_setting+midazolam_use+sofa+temperature_mean+hemoglobin_min+sodium_max")

# Fit logistic regression model using lrm()
F1 <- lrm(formula, data = nomogram_data, x = TRUE, y = TRUE)
F1

# Create nomogram object
tmp <- nomogram(
  F1,
  fun = function(x) 1/(1 + exp(-x)),
  fun.at = c(0.01,0.1,0.2,0.4,0.6,0.8,0.9,0.99),
  funlabel = "Risk of Outcome",
  conf.int = FALSE,
  abbrev = FALSE,
  minlength = 1,
  lp = TRUE
)

# Plot nomogram
plot(
  tmp,
  points.label = "Points",
  col.grid = c("tomato", "grey"),
  total.points.label = "Total Points",
  cex = 1,
  cex.axis = 1,
  cex.lab = 1
)



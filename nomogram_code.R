library(rms)
options(datadist = NULL)
ddist <- datadist(nomogram_data)
options(datadist = "ddist")
formula <- as.formula("cam_icu_score ~ neurological_disease+ventilator_setting+midazolam_use+sofa+temperature_mean+hemoglobin_min+sodium_max")
F1 <- lrm(formula, data = nomogram_data, x = TRUE, y = TRUE)
F1
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

plot(
  tmp,
  points.label = "Points",
  col.grid = c("tomato", "grey"),
  total.points.label = "Total Points",
  cex = 1,
  cex.axis = 1,
  cex.lab = 1
)



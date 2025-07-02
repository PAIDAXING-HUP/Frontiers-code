library(rmda)
fit.glm <- glm(cam_icu_score ~ neurological_disease + ventilator_setting + midazolam_use +     sofa + temperature_mean + hemoglobin_min + sodium_max, data = dca_train_data, family = binomial())
dca1_train_data <- na.omit(dca_train_data[, c('cam_icu_score', 'neurological_disease', 'ventilator_setting', 'midazolam_use', 'sofa', 'temperature_mean', 'hemoglobin_min', 'sodium_max')])

pred.logit_train <- predict(fit.glm, dca1_train_data)

dca1_train_data$pred.logit <- pred.logit_train

DCA.1_train <- rmda::decision_curve(

  formula = as.formula('cam_icu_score ~ pred.logit'),

  family = binomial(link = 'logit'),

  thresholds = seq(0, 1, by = 0.01),

  confidence.intervals = 0.95,
  study.design = 'cohort',
  data = dca1_train_data
)

plot.new()
rmda::plot_decision_curve(DCA.1_train, curve.names = 'Model', xlim = c(0, 0.8), cost.benefit.axis = TRUE, col = '#E64B35B2', confidence.intervals = FALSE, standardize = FALSE)

dca1_validation_data <- na.omit(dca_validation_data[, c('cam_icu_score', 'neurological_disease', 'ventilator_setting', 'midazolam_use', 'sofa', 'temperature_mean', 'hemoglobin_min', 'sodium_max')])
pred.logit_val <- predict(fit.glm, dca1_validation_data)
dca1_validation_data$pred.logit <- pred.logit_val
DCA.1_validation <- rmda::decision_curve(
  formula = as.formula('cam_icu_score ~ pred.logit'),
  family = binomial(link = 'logit'),
  thresholds = seq(0, 1, by = 0.01),
  confidence.intervals = 0.95,
  study.design = 'cohort',
  data = dca1_validation_data
)

plot.new()
rmda::plot_decision_curve(DCA.1_validation, curve.names = 'Model', xlim = c(0, 0.8), cost.benefit.axis = TRUE, col = '#E64B35B2', confidence.intervals = FALSE, standardize = FALSE)



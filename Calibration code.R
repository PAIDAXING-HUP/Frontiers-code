# R Code:

# Load required packages
library(rms)


# Fit logistic regression model on training data
# Fit logistic regression model on training data

fit3_glm <- glm(cam_icu_score ~ neurological_disease + ventilator_setting + midazolam_use +     sofa + temperature_mean + hemoglobin_min + sodium_max, data = calibration_train_data, family = binomial())
# Training data calibration via val.prob


# Training data calibration via val.prob

pred.logit_train <- predict(fit3_glm, newdata = calibration_train_data)

phat_train <- 1 / (1 + exp(-pred.logit_train))



val.prob(lim = c(0, 1), statloc = c(0, 1 - 0.01),

         p = phat_train, y = calibration_train_data[['cam_icu_score']], cex = 0.8)



# Validation data calibration via val.prob
# Validation data calibration via val.prob
pred.logit_val <- predict(fit3_glm, newdata = calibration_validation_data)
phat_val <- 1 / (1 + exp(-pred.logit_val))

val.prob(lim = c(0, 1), statloc = c(0, 1 - 0.01),
         p = phat_val, y = calibration_validation_data[['cam_icu_score']], cex = 0.8)



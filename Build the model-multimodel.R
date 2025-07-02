# R Code:

# Fit the train_model
train_model <- glm(formula = cam_icu_score ~ neurological_disease + ventilator_setting + 
    midazolam_use + sofa + temperature_mean + hemoglobin_min + 
    sodium_max, family = binomial, data = multimodel_train_data)
# Display summary of train_model
summary(train_model)
# Fit the validation_model
validation_model <- glm(formula = cam_icu_score ~ neurological_disease + ventilator_setting + 
    midazolam_use + sofa + temperature_mean + hemoglobin_min + 
    sodium_max, family = binomial, data = multimodel_validation_data)
# Display summary of validation_model
summary(validation_model)



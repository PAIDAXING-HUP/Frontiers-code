train_model <- glm(formula = cam_icu_score ~ neurological_disease + ventilator_setting + 
    midazolam_use + sofa + temperature_mean + hemoglobin_min + 
    sodium_max, family = binomial, data = multimodel_train_data)
summary(train_model)
validation_model <- glm(formula = cam_icu_score ~ neurological_disease + ventilator_setting + 
    midazolam_use + sofa + temperature_mean + hemoglobin_min + 
    sodium_max, family = binomial, data = multimodel_validation_data)
summary(validation_model)



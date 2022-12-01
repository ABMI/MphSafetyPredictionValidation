#' Prediction for existing GLM
#'
#' @details
#' This applies the existing models and calcualtes the risk for a population
#'
#' @param plpModel The model being applied
#' @param data  The new data
#' @param cohort The new population
#'
#' @return
#' The population with an extra column 'value' corresponding to the patients risk
#'
#' @export
predictNonPlpGlm <- function(plpModel, data, cohort){

  coeff <- plpModel$model$coefficients
  finalMapping <- plpModel$model$finalMapping
  type <- attr(plpModel, 'predictionType')
  offset <- plpModel$model$offset
  baselineHazard <- plpModel$model$baselineHazard

  data$covariateData$coefficients <- coeff
  on.exit(data$covariateData$coefficients <- NULL, add = TRUE)

  if(sum(c('power','offset')%in%colnames(coeff))==2){
    prediction <- data$covariateData$covariates %>%
      dplyr::inner_join(data$covariateData$coefficients, by= 'covariateId') %>%
      dplyr::mutate(values = (.data$covariateValue-.data$offset)^.data$power*.data$points) %>%
      dplyr::group_by(.data$rowId) %>%
      dplyr::summarise(value = sum(.data$values, na.rm = TRUE)) %>%
      dplyr::select(.data$rowId, .data$value) %>%
      dplyr::collect()
  } else{
    prediction <- data$covariateData$covariates %>%
      dplyr::inner_join(data$covariateData$coefficients, by= 'covariateId') %>%
      dplyr::mutate(values = .data$covariateValue*.data$points) %>%
      dplyr::group_by(.data$rowId) %>%
      dplyr::summarise(value = sum(.data$values, na.rm = TRUE)) %>%
      dplyr::select(.data$rowId, .data$value) %>%
      dplyr::collect()
  }
  prediction <- as.data.frame(prediction)
  prediction <- merge(cohort, prediction, by ="rowId", all.x = TRUE)
  prediction$value[is.na(prediction$value)] <- 0

  # add any final mapping here (e.g., add intercept and mapping)
  prediction$value <- finalMapping(prediction$value)
  attr(prediction, "metaData")$modelType <- attr(plpModel, "modelType")

  attr(prediction, "metaData")$offset <-  offset
  attr(prediction, "metaData")$timepoint = attr(cohort,'metaData')$riskWindowEnd
  attr(prediction, "metaData")$baselineHazard = plpModel$model$baselineHazard
  #baselineHazardTimepoint

  return(prediction)
}

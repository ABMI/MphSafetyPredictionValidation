#example code to add existing model into a created validation package

source('./extras/addModel.R')

baseUrl <- 'https://addyours/WebAPI'

ROhdsiWebApi::authorizeWebApi(
  baseUrl = baseUrl,
)

finalMapping <- function(x){1/(1+exp(10-x))}

diabetes1 <- PatientLevelPrediction::createCohortCovariateSettings(
  cohortName = 'Diabetes',
  settingId = 1,
  cohortDatabaseSchema = NULL,
  cohortTable = NULL,
  cohortId = 1182,
  startDay = -365*5,
  endDay = -1,
  count = F,
  ageInteraction = F,
  lnAgeInteraction = F,
  analysisId = 456
)

coefficients1 <- data.frame(covariateId = diabetes1$covariateId, points = 5, offset = 0, power = 1)


gender <- FeatureExtraction::createCovariateSettings(useDemographicsGender = T)
coefficients2 <- data.frame(covariateId = 8532001, points = 10, offset = 0, power = 1)


hepaticfailure1 <- PatientLevelPrediction::createCohortCovariateSettings(
  cohortName = 'Hepatic failure',
  settingId = 1,
  cohortDatabaseSchema = NULL,
  cohortTable = NULL,
  cohortId = 1113,
  startDay = -365*10,
  endDay = -1,
  count = F,
  ageInteraction = F,
  lnAgeInteraction = F,
  analysisId = 456
)

coefficients3 <- data.frame(covariateId = diabetes1$covariateId, points = 5, offset = 0, power = 1)

covariateSettings <- list(diabetes1, gender, hepaticfailure1)
coefficients <- rbind(coefficients1, coefficients2, coefficients3)


addModel(
  packageLocation = "D:/lungTestResults2/skelPredTestValidation",
  analysisId = 'Analysis_5',
  modelDevelopmentDataName = 'testing',
  outcomeId = 3426,
  cohortId = 4728,
  plpDataSettings = PatientLevelPrediction::createRestrictPlpDataSettings(),
  covariateSettings = covariateSettings,
  populationSettings = PatientLevelPrediction::createStudyPopulationSettings(binary = T),
  coefficients = coefficients,
  finalMapping = finalMapping,
  offset = 0,
  baseUrl = baseUrl
)


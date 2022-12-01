# add the functions for the exisitng models here
#======= add custom function here...

addModel <- function(
  type = c('binary', 'survival')[1],
  packageLocation = getwd(),
  analysisId = 'Analysis_10',
  modelDevelopmentDataName = '',
  outcomeId = 2,
  cohortId = 1,
  plpDataSettings = PatientLevelPrediction::createRestrictPlpDataSettings(),
  covariateSettings = FeatureExtraction::createCovariateSettings(useDemographicsAgeGroup = T),
  populationSettings = PatientLevelPrediction::createStudyPopulationSettings(binary = T),
  coefficients = data.frame(covariateId = 1001, points = 10, offset = 0, power = 1),
  finalMapping = function(p){sapply(p, function(x){ x <- x + 9; x/(1+x) } )},
  offset = 0,
  baseUrl = NULL,
  baselineHazard = 1
){

  modelLocation <- file.path(packageLocation, 'inst','models')
  if(!dir.exists(modelLocation)){
    dir.create(modelLocation, recursive = T)
  }

  # extract new cohorts
  if(class(covariateSettings) == 'covariateSettings'){
    covariateSettings <- list(covariateSettings)
  }

  covariateCohortIds <- unlist(lapply(covariateSettings, function(x) x$cohortId))
  cohortIds <- c(outcomeId, cohortId, covariateCohortIds)

  # update the cohortsToCreate.csv
  cohortsToCreate <- tryCatch(
    {read.csv(file.path(packageLocation, 'inst', 'Cohorts.csv'))},
    error = function(e){print(e); return(list())}
  )

  if(sum(!cohortIds %in% cohortsToCreate$cohortId)>0){
    cohortIds <- cohortIds[!cohortIds %in% cohortsToCreate$cohortId]

    newCohortsToCreate <- c()
    for(cohort in cohortIds){

      # extract cohort sql and json into package
      ParallelLogger::logInfo('Extracting cohorts using webapi')

      ParallelLogger::logInfo(paste("Extracting cohort:", cohort))
      cohortDefinition <- ROhdsiWebApi::getCohortDefinition(
        cohortId = cohort,
        baseUrl = baseUrl
      )

      ParallelLogger::logInfo(paste0('Extracted ', cohortDefinition$name ))

      # make dirs
      if(!dir.exists(file.path(packageLocation, 'inst', 'cohorts'))){
        dir.create(file.path(packageLocation, 'inst', 'cohorts'), recursive = T)
      }
      if(!dir.exists(file.path(packageLocation,'inst', 'sql', 'sql_server'))){
        dir.create(file.path(packageLocation,'inst', 'sql', 'sql_server'), recursive = T)
      }

      # save cohort
      write(
        x = jsonlite::serializeJSON(cohortDefinition, digits = 23),
        file = file.path(
          packageLocation, 'inst', 'cohorts',
          paste0(cohortDefinition$id, '.json')
        )
      )

      # save sql
      write(
        x = ROhdsiWebApi::getCohortSql(cohortDefinition, baseUrl = baseUrl, generateStats = F),
        file = file.path(
          packageLocation, 'inst', 'sql', 'sql_server',
          paste0(cohortDefinition$id, '.sql')
        )
      )

      newCohortsToCreate <- rbind(
        newCohortsToCreate,
        c(
          cohortName = cohortDefinition$name,
          cohortId = cohort,
          webApiCohortId = cohort
        )
      )
    }

    utils::write.table(
      x = rbind(cohortsToCreate[,c('cohortName','cohortId','webApiCohortId')], newCohortsToCreate),
      file = file.path(packageLocation, 'inst','Cohorts.csv'),
      append = F,
      row.names = F,
      sep = ','
    )
  }


  # create the model
  plpModel <- createModel(
    type,
    analysisId,
    modelDevelopmentDataName,
    outcomeId,
    cohortId,
    plpDataSettings,
    covariateSettings,
    populationSettings,
    coefficients,
    finalMapping,
    offset,
    baselineHazard
  )

  # save the model
  PatientLevelPrediction::savePlpModel(
    plpModel = plpModel,
    dirPath = file.path(modelLocation, analysisId)
  )

  return(file.path(modelLocation, analysisId))
}

createModel <- function(
  type = c('binary', 'survival')[1],
  analysisId,
  modelDevelopmentDataName,
  outcomeId,
  cohortId,
  plpDataSettings,
  covariateSettings,
  populationSettings,
  coefficients,
  finalMapping,
  offset = 0,
  baselineHazard = 1
){

  type <- type[1]

  if(!type %in% c('binary', 'survival')){
    stop('Unsupported type')
  }

  modelSettings <- list(
    model = list(
      name = 'NonPlpGlm'
    )
  )
  class(modelSettings) <- 'modelSettings'

  settings <- list(
    plpDataSettings = plpDataSettings,
    covariateSettings = covariateSettings,
    featureEngineering = NULL,
    tidyCovariates = NULL,
    covariateMap = NULL,
    requireDenseMatrix = F,
    populationSettings = populationSettings,
    modelSettings = modelSettings,
    splitSettings = NULL,
    sampleSettings = NULL
  )


  trainDetails <- list(
    analysisId = analysisId,
    cdmDatabaseSchema = modelDevelopmentDataName,
    outcomeId = outcomeId,
    cohortId = cohortId,
    trainingTime = 0,
    trainingDate = '',
    hyperParamSearch = c()
  )

  if(type == 'binary'){
    model <- list(
      coefficients = coefficients,
      finalMapping = finalMapping,
      offset = offset#,
      #baselineHazard
    )
  } else{
    model <- list(
      coefficients = coefficients,
      finalMapping = finalMapping,
      offset = offset,
      baselineHazard = baselineHazard
    )
  }

  plpModel <- list(
    settings = settings,
    trainDetails = trainDetails,
    covariateImportance = c(),
    model = model
  )

  class(plpModel) <- 'plpModel'
  attr(plpModel, 'predictionFunction') <- 'SkeletonPredictionValidationStudy::predictNonPlpGlm'
  attr(plpModel, 'saveType') <- 'RtoJson'
  attr(plpModel, 'modelType') <- type

  return(plpModel)
}

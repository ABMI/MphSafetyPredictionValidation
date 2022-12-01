#' Execute the validation study
#'
#' @details
#' This function will execute the sepcified parts of the study
#'
#' @param databaseDetails      Database details for the validation created using \code{PatientLevelPrediction::createDatabaseDetails()}
#' @param restrictPlpDataSettings      Extras data settings such as sampling created using \code{PatientLevelPrediction::createRestrictPlpDataSettings()}
#' @param validationSettings   Settings for the validation such as whether to recalibrate
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/)
#' @param createCohorts        Whether to create the cohorts for the study
#' @param runValidation        Whether to run the valdiation models
#' @param packageResults       Whether to package the results (after removing sensitive details)
#' @param minCellCount         The min count for the result to be included in the package results
#' @param logSettings          Settings for the logging created using \code{PatientLevelPrediction::createLogSettings()}
#' @export
execute <- function(
  databaseDetails,
  restrictPlpDataSettings = PatientLevelPrediction::createRestrictPlpDataSettings(
    sampleSize = NULL
  ),
  validationSettings = PatientLevelPrediction::createValidationSettings(
    recalibrate = NULL
  ),
  outputFolder,
  createCohorts = T,
  runValidation = T,
  packageResults = T,
  minCellCount = 5,
  logSettings = PatientLevelPrediction::createLogSettings(verbosity = 'INFO', logName = 'validatePLP')
){

  databaseName <- databaseDetails$cdmDatabaseName

  if (!file.exists(file.path(outputFolder,databaseName))){
    dir.create(file.path(outputFolder,databaseName), recursive = TRUE)
  }

  ParallelLogger::addDefaultFileLogger(file.path(outputFolder,databaseName, "log.txt"))

  if(createCohorts){
    ParallelLogger::logInfo("Creating Cohorts")
    createCohorts(
      databaseDetails = databaseDetails,
      outputFolder = file.path(outputFolder,databaseName)
    )
  }

  if(runValidation){
    ParallelLogger::logInfo("Validating Models")
    # for each model externally validate

      ParallelLogger::logInfo("Applying Models in models folder")
      analysesLocation <- system.file(
        "models",
        package = "MphSafetyPredictionValidation"
        )

      models <- dir(analysesLocation)

      for(model in models){

        tryCatch(

          {

        plpModel <- PatientLevelPrediction::loadPlpModel(file.path(analysesLocation, model))

        #update cohort schema and table in covariate settings
        ParallelLogger::logInfo('Updating cohort covariate settings is being used')
        plpModel$settings$covariateSettings <- addCohortSettings(
            covariateSettings = plpModel$settings$covariateSettings,
            cohortDatabaseSchema = databaseDetails$cohortDatabaseSchema,
            cohortTable = databaseDetails$cohortTable
        )


        PatientLevelPrediction::externalValidateDbPlp(
          plpModel = plpModel,
          validationDatabaseDetails =  databaseDetails,
          validationRestrictPlpDataSettings = restrictPlpDataSettings,
          settings = validationSettings,
          logSettings = logSettings,
          outputFolder = outputFolder
          )
          },
        error = function(e) {
          message("Failed to externally validate model")
          message(e)
        }
        )
      }
  }


  # package the results: this creates a compressed file with sensitive details removed - ready to be reviewed and then
  # submitted to the network study manager

  # results saved to outputFolder/databaseName
  if (packageResults) {
    ParallelLogger::logInfo("Packaging results")

    if (is.null(nrow(plpResult$prediction)) || nrow(plpResult$prediction)==0) {
      ParallelLogger::logInfo(paste0("Skipping ", folder, ": predictions are missing"))
      next
    }

    packageResults(
      outputFolder = outputFolder,
      databaseName = databaseName,
      minCellCount = minCellCount
    )
  }


  invisible(NULL)

}

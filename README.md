MphSafetyPredictionValidation
======================

Introduction
============
This package contains code to externally validate models for the prediction quesiton <Can we predict adverse drug events from methylphenidate users?> developed on the database <add database>.

Features
========
  - Applies models developed using the OHDSI PatientLevelPrediction package
  - Evaluates the performance of the models on new data
  - Packages up the results (after removing sensitive date) to share with study owner

Technology
==========
  MphSafetyPredictionValidation is an R package.

System Requirements
===================
  * Requires: OMOP CDM database and connection details
  * Requires: Java runtime enviroment (for the database connection)
  * Requires: R (version 4.0.0 or higher)

Dependencies
============
  * PatientLevelPrediction
  
Guide
============
A general guide for running a valdiation study package is available here: [Skeleton Validation Study guide](https://github.com/OHDSI/MphSafetyPredictionValidation/tree/main/inst/doc/UsingSkeletonValidationPackage.pdf)

A0. Installing the package from GitHub
===============
  1. To download the package from github or you can use below codes in your terminal (git required).
```r
# in you terminal
git clone https://github.com/ABMI/MphSafetyPredictionValidation
```
A1. Building the package inside RStudio
===============
  1. Open the MPHSafetyPredictionValidation package project file in validation folder (file ending in .Rproj) 
  2. Restore the dependency packages as follow
  
  ```r
  # install renv package. you can skip the installation if you already have installed it. 
  install.packages("renv")
  renv::restore() 
  ```
  3. Build the package in RStudio by selecting the 'Build' option in the top right (the tabs contain  'Environment', 'History', 'Connections', 'Build', 'Git') and then clicking on the 'Install and Restart'

B. Getting Started
===============
  1. Make sure to have both: download (A0) and built (A1) the package 
  2. In R, run the code in 'extras/codeToRun.R' (see [Skeleton Validation Study guide](https://github.com/ted9219/MphSafetyPrediction/tree/main/validation/inst/doc/UsingSkeletonValidationPackage.pdf) for guideance)


C. Example Code
===============
```r
library(MphSafetyPredictionValidation)

outputFolder <- './Validation'

# add the database connection details
dbms = 'your database management system'
server = 'your server'
user = 'your username'
password = 'top secret'
port = 'your port'
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = pw,
                                                                port = port)

# add cdm database details:
cdmDatabaseSchema <- 'your cdm database schema'

# add a schema you have read/write access to
# this is where the cohorts will be created (or are already created)
cohortDatabaseSchema <- 'your cohort database schema'

# if using oracle specify the temp schema
oracleTempSchema <- NULL
tempEmulationSchema <- NULL

# Add a sharebale name for the database containing the OMOP CDM data
databaseName <- 'your database name'

# table name where the cohorts will be generated
cohortTable <- 'MphSafetyPredictionValidationCohort'

#===== execution choices =====

# how much details do you want for in progress report?
verbosity <- "INFO"

# create the cohorts using the sql in the package?
createCohorts = T # If you already created the cohorts, please change to FALSE.

# apply the models in the package to your data?
runValidation = T
# if you only want to apply models to a sample of
# patients put the number as the sampleSize
sampleSize = NULL
# do you want to recalibrate results?
# NULL means none (see ?MphSafetyPredictionValidation::execute for options)
recalibrate <- NULL

# extract the results to share as a zip file?
packageResults = T
# when extracting results - what is the min cell count?
minCellCount = 5

#=============================
# configure the settings
databaseDetails <- PatientLevelPrediction::createDatabaseDetails(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cdmDatabaseName = databaseName,
  tempEmulationSchema = tempEmulationSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  outcomeDatabaseSchema = cohortDatabaseSchema,
  outcomeTable = cohortTable,
  cdmVersion = 5
)

restrictPlpDataSettings <- PatientLevelPrediction::createRestrictPlpDataSettings(
  sampleSize = sampleSize
)

validationSettings <- PatientLevelPrediction::createValidationSettings(
  recalibrate = recalibrate
)

logSettings <- PatientLevelPrediction::createLogSettings(
  verbosity = verbosity
)

#=============================
# Now run the study
MphSafetyPredictionValidation::execute(
  databaseDetails = databaseDetails,
  restrictPlpDataSettings = restrictPlpDataSettings,
  validationSettings = validationSettings,
  logSettings = logSettings,
  outputFolder = outputFolder,
  createCohorts = createCohorts,
  runValidation = runValidation,
  packageResults = packageResults,
  minCellCount = minCellCount
)
                 
```

D.Result sharing
===============
  1. After you finished, please send the results zip file to dongyun90@ajou.ac.kr/ted9219@ajou.ac.kr

License
=======
  MphSafetyPredictionValidation is licensed under Apache License 2.0

Development
===========
  MphSafetyPredictionValidation is being developed in R Studio.

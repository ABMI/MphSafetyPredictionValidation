# download master skeleton

createPackage <- function(
  outputFolder,
  packageName
){

  packageLocation <- downLoadSkeleton(
    outputFolder = outputFolder,
    packageName = packageName,
    skeletonType = 'SkeletonPredictionValidationStudy'
  )

  # replace 'SkeletonPredictionValidationStudy' with packageName
  replaceName(
    packageLocation = file.path(outputFolder,packageName),
    packageName = packageName,
    skeletonType = 'SkeletonPredictionValidationStudy'
  )

  return(invisible(file.path(outputFolder,packageName)))
}

# code to use skeleton master from github rather than hydra
# download a .zip file of the repository
# from the "Clone or download - Download ZIP" button
# on the GitHub repository of interest
downLoadSkeleton <- function(
  outputFolder,
  packageName,
  skeletonType = 'SkeletonPredictionValidationStudy'
){
  # check outputFolder exists

  # check file.path(outputFolder,  packageName) does not exist

  # download, unzip and rename:

  download.file(url = paste0("https://github.com/ohdsi/",skeletonType,"/archive/main.zip")
    , destfile = file.path(outputFolder, "package.zip"))
  # unzip the .zip file
  unzip(zipfile = file.path(outputFolder, "package.zip"), exdir = outputFolder)
  file.rename( from = file.path(outputFolder, paste0(skeletonType, '-main')),
    to = file.path(outputFolder,  packageName))
  unlink(file.path(outputFolder, "package.zip"))
  return(file.path(outputFolder, packageName))
}

replaceName <- function(
  packageLocation = getwd(),
  packageName = 'ValidateRCRI',
  skeletonType = 'SkeletonPredictionValidationStudy'
){

  filesToRename <- c(paste0(skeletonType,".Rproj"),paste0("R/",skeletonType,".R"))
  for(f in filesToRename){
    ParallelLogger::logInfo(paste0('Renaming ', f))
    fnew <- gsub(skeletonType, packageName, f)
    file.rename(from = file.path(packageLocation,f), to = file.path(packageLocation,fnew))
  }

  filesToEdit <- c(
    file.path(packageLocation,"DESCRIPTION"),
    file.path(packageLocation,"README.md"),
    file.path(packageLocation,"extras/CodeToRun.R"),
    file.path(packageLocation,"extras/addModel.R"),
    dir(file.path(packageLocation,"R"), full.names = T)
  )
  for( f in filesToEdit ){
    ParallelLogger::logInfo(paste0('Editing ', f))
    x <- readLines(f)
    y <- gsub( skeletonType, packageName, x )
    cat(y, file=f, sep="\n")

  }

  return(packageName)
}

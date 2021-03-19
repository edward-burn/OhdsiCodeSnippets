
# Optional: specify where the temporary files will be created:
options(andromedaTempFolder = "C/andromedaTemp")

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

oracleTempSchema <- NULL

outputFolder <- here::here("results")

DatabaseConnector::downloadJdbcDrivers("postgresql", pathToDriver = here::here())


if("HM" %in% run.for){
  print("Running for HM")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                server = "10.80.192.22/hmhospitals2", 
                                                                port="5432", user= user, password = password, 
                                                                pathToDriver=here::here())
cdmDatabaseSchema <- "hm"
cohortDatabaseSchema <- "results"
cohortTable <- cohort_table
databaseId <- "HM"
databaseName <- "HM"
databaseDescription <- "HM"
  
CohortDiag::runCohortDiagnostics(connectionDetails = connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortDatabaseSchema = cohortDatabaseSchema,
                                     cohortTable = cohortTable,
                                     oracleTempSchema = oracleTempSchema,
                                     outputFolder = outputFolder,
                                     databaseId = databaseId,
                                     databaseName = databaseName,
                                     databaseDescription = databaseDescription,
                                     createCohorts = createCohorts,
                                     runInclusionStatistics = runInclusionStatistics,
                                     runIncludedSourceConcepts = TRUE, #shiny wants concept set
                                     runOrphanConcepts = runOrphanConcepts,
                                     runTimeDistributions = runTimeDistributions,
                                     runBreakdownIndexEvents = runBreakdownIndexEvents,
                                     runIncidenceRates = runIncidenceRates,
                                     runCohortOverlap = runCohortOverlap,
                                     runCohortCharacterization = runCohortCharacterization,
                                     runTemporalCohortCharacterization = runTemporalCohortCharacterization,
                                     minCellCount = 5)
}


if("SIDIAP_H" %in% run.for){
  print("Running for SIDIAP_H")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                server = "10.80.192.22/postgres20v2", 
                                                                port="5432", user= user, password = password, 
                                                                pathToDriver=here::here())
cdmDatabaseSchema <- "omop20v2_h"
cohortDatabaseSchema <- "results20v2_h"
cohortTable <- cohort_table
databaseId <- "H_SIDIAP"
databaseName <- "H_SIDIAP"
databaseDescription <- "H_SIDIAP"
  
CohortDiag::runCohortDiagnostics(connectionDetails = connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortDatabaseSchema = cohortDatabaseSchema,
                                     cohortTable = cohortTable,
                                     oracleTempSchema = oracleTempSchema,
                                     outputFolder = outputFolder,
                                     databaseId = databaseId,
                                     databaseName = databaseName,
                                     databaseDescription = databaseDescription,
                                     createCohorts = createCohorts,
                                     runInclusionStatistics = runInclusionStatistics,
                                     runIncludedSourceConcepts = TRUE, #shiny wants concept set
                                     runOrphanConcepts = runOrphanConcepts,
                                     runTimeDistributions = runTimeDistributions,
                                     runBreakdownIndexEvents = runBreakdownIndexEvents,
                                     runIncidenceRates = runIncidenceRates,
                                     runCohortOverlap = runCohortOverlap,
                                     runCohortCharacterization = runCohortCharacterization,
                                     runTemporalCohortCharacterization = runTemporalCohortCharacterization,
                                     minCellCount = 5)
}


if("SIDIAP" %in% run.for){
  print("Running for SIDIAP_H")
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                server = "10.80.192.22/postgres20v2", 
                                                                port="5432", user= user, password = password, 
                                                                pathToDriver=here::here())
cdmDatabaseSchema <- "omop20v2"
cohortDatabaseSchema <- "results20v2"
cohortTable <- cohort_table
databaseId <- "SIDIAP"
databaseName <- "SIDIAP"
databaseDescription <- "SIDIAP"
  
CohortDiag::runCohortDiagnostics(connectionDetails = connectionDetails,
                                     cdmDatabaseSchema = cdmDatabaseSchema,
                                     cohortDatabaseSchema = cohortDatabaseSchema,
                                     cohortTable = cohortTable,
                                     oracleTempSchema = oracleTempSchema,
                                     outputFolder = outputFolder,
                                     databaseId = databaseId,
                                     databaseName = databaseName,
                                     databaseDescription = databaseDescription,
                                     createCohorts = createCohorts,
                                     runInclusionStatistics = runInclusionStatistics,
                                     runIncludedSourceConcepts = TRUE, #shiny wants concept set
                                     runOrphanConcepts = runOrphanConcepts,
                                     runTimeDistributions = runTimeDistributions,
                                     runBreakdownIndexEvents = runBreakdownIndexEvents,
                                     runIncidenceRates = runIncidenceRates,
                                     runCohortOverlap = runCohortOverlap,
                                     runCohortCharacterization = runCohortCharacterization,
                                     runTemporalCohortCharacterization = runTemporalCohortCharacterization,
                                     minCellCount = 5)
}






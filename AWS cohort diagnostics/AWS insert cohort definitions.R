#### SETTING UP A COHORT DIAGNOSTICS PACKAGE 
# I assume that you have taken the example package folder from
# https://github.com/OHDSI/CohortDiagnostics/tree/master/examplePackage
# and followed the instructions to rename it etc
# and now you have reached the part where you want to add your cohort definitions from our AWS Atlas
# I assume that you now in RStudio on AWS, and are inside the Rproj of your package

# Yes? Ok, so please run the next three lines and give our atlas location, along with your login and password to Atlas so that we connect
baseUrl <- .rs.askForPassword("Atlas baseurl:")
login <- .rs.askForPassword("Atlas username:")
password  <- .rs.askForPassword("Atlas password:")
# note when run these should pop up to ask you to add them in interactively
# this is to try and reduce the risk of accidently revealing sensitive information if this script is shared
# So please try not to hard code them!

# what is the name of the cohort diagnostics package?
packageName <- "DiagAi" 

# Next, load these three packages (you might need to install them first.....)
library(httr) #from CRAN
library(dplyr) # from CRAN
library(ROhdsiWebApi) # from the OHDSI github

# Ok, now specify what cohorts you want to include
# specify the set of ids from ATLAS
# I´m going to use the same name as whatever you called it in ATLAS
# please make sure this does not have trailing spaces and is not too long 
# (both of which I know can cause problems later on from bitter experience)
Atlas.ids<-""
# for example, 
#Atlas.ids<-c(194, 133)
# would bring in Jenny´s cohorts 
# 194,[MSK_AI]outcome_oa_thumb,194,[MSK_AI]outcome_oa_thumb
# and 
# 133,[MSK_AI]target_ai

# Now, hopefully, all you should need to do is run all of the below code
# this should connect to atlas
# then create a csv with the cohorts (you can check this in the inst/settings folder)
# then drop in the json and sql for each cohort
# (you can check these by going to do inst/cohorts and inst/sql/sql_server)

# once this is run and you have your cohorts in the package
# remember to (re)build your package
# "Build -> Install and Restart"
# Before this though you might also need to install other required dependencies
# (which you can find at the top of the Code to Run file)
# After this, you can start trying to get 

# get authentication ------
authUrl <- paste0(baseUrl, "/user/login/db")
login <- list(login = login, password = login)
r <- POST(authUrl, body = login, encode = "form")
authHeader <- paste0("Bearer ", httr::headers(r)$bearer)

# edit functions to incorporate authentication  ------
#getCdmSources(baseUrl) 
getCdmSources <- function (baseUrl) {
  .checkBaseUrl(baseUrl)
  url <- sprintf("%s/source/sources", baseUrl)
  request <- httr::GET(url, httr::add_headers(Authorization = authHeader))
  httr::stop_for_status(request)
  sources <- httr::content(request)
  sourceDetails <- lapply(sources, function(s) {
    cdmDatabaseSchema <- NA
    vocabDatabaseSchema <- NA
    resultsDatabaseSchema <- NA
    if (length(s$daimons) > 0) {
      for (i in 1:length(s$daimons)) {
        if (!is.na(s$daimons[[i]]$daimonType)) {
          if (toupper(s$daimons[[i]]$daimonType) == 
              toupper("cdm")) {
            cdmDatabaseSchema <- s$daimons[[i]]$tableQualifier
          }
          if (toupper(s$daimons[[i]]$daimonType) == 
              toupper("vocabulary")) {
            vocabDatabaseSchema <- s$daimons[[i]]$tableQualifier
          }
          if (toupper(s$daimons[[i]]$daimonType) == 
              toupper("results")) {
            resultsDatabaseSchema <- s$daimons[[i]]$tableQualifier
          }
        }
      }
    }
    tibble::tibble(sourceId = s$sourceId, sourceName = s$sourceName, 
                   sourceKey = s$sourceKey, sourceDialect = s$sourceDialect, 
                   cdmDatabaseSchema = cdmDatabaseSchema, vocabDatabaseSchema = vocabDatabaseSchema, 
                   resultsDatabaseSchema = resultsDatabaseSchema)
  })
  return(dplyr::bind_rows(sourceDetails))
}
#with auth
# Get the problematic version of the function out of the package namespace
# and replace
tmpfun <- get("getCdmSources", 
              envir = asNamespace("ROhdsiWebApi"))
environment(getCdmSources) <- environment(tmpfun)
assignInNamespace("getCdmSources", 
                  getCdmSources, ns = "ROhdsiWebApi")

getDefinition<-function (id, category, baseUrl) {
  .checkBaseUrl(baseUrl)
  arguments <- .getStandardCategories()
  argument <- arguments %>% dplyr::filter(.data$categoryStandard == 
                                            category)
  errorMessage <- checkmate::makeAssertCollection()
  checkmate::assertInt(id, add = errorMessage)
  checkmate::assertChoice(x = category, choices = arguments$categoryStandard)
  checkmate::reportAssertions(errorMessage)
  url <- paste0(baseUrl, "/", argument$categoryUrl, "/", id)
  response <- httr::GET(url, httr::add_headers(Authorization = authHeader))
  if (!response$status_code == 200) {
    definitionsMetaData <- getDefinitionsMetadata(baseUrl = baseUrl, 
                                                  category = category)
    if (!id %in% definitionsMetaData$id) {
      error <- paste0(argument$categoryFirstUpper, ": ", 
                      id, " not found.")
    }
    else {
      error <- ""
    }
    ParallelLogger::logError(error, "Status code = ", httr::content(response)$status_code)
    stop()
  }
  response <- httr::content(response)
  if (is.null(response$expression)) {
    if (!is.null(response$specification)) {
      response$expression <- response$specification
      response$specification <- NULL
    }
    else if (!is.null(response$design)) {
      response$expression <- response$design
      response$design <- NULL
    }
    else {
      if (argument$categoryUrlGetExpression != "") {
        urlExpression <- paste0(baseUrl, "/", argument$categoryUrl, 
                                "/", id, "/", argument$categoryUrlGetExpression)
        expression <- httr::GET(urlExpression, httr::add_headers(Authorization = authHeader))
        expression <- httr::content(expression)
        response$expression <- expression
      }
      else {
        response$expression <- response
        response$expression$name <- NULL
      }
    }
  }
  if (is.character(response$expression)) {
    if (jsonlite::validate(response$expression)) {
      response$expression <- RJSONIO::fromJSON(response$expression, 
                                               nullValue = NA)
    }
  }
  return(response)
}
tmpfun <- get("getDefinition", 
              envir = asNamespace("ROhdsiWebApi"))
environment(getDefinition) <- environment(tmpfun)
assignInNamespace("getDefinition", 
                  getDefinition, ns = "ROhdsiWebApi")

getCohortSql<-function (cohortDefinition, baseUrl, generateStats = TRUE) {
  .checkBaseUrl(baseUrl)
  arguments <- .getStandardCategories()
  argument <- arguments %>% dplyr::filter(.data$categoryStandard == 
                                            "cohort")
  if (!"cohort" %in% c("cohort")) {
    ParallelLogger::logError("Retrieving SQL for ", argument$categoryFirstUpper, 
                             " is not supported")
    stop()
  }
  errorMessage <- checkmate::makeAssertCollection()
  checkmate::assertList(x = cohortDefinition, min.len = 1, 
                        add = errorMessage)
  checkmate::reportAssertions(errorMessage)
  url <- paste0(baseUrl, "/", argument$categoryUrl, "/sql/")
  httpheader <- c(Accept = "application/json; charset=UTF-8", 
                  `Content-Type` = "application/json")
  if ("expression" %in% names(cohortDefinition)) {
    expression <- cohortDefinition$expression
  }
  else {
    expression <- cohortDefinition
  }
  listGenerateStats <- list(expression = expression, options = list(generateStats = generateStats))
  validJsonExpression <- .toJSON(listGenerateStats)
  response <- httr::POST(url, body = validJsonExpression,  config = httr::add_headers(httpheader, Authorization = authHeader))
  if (response$status == 200) {
    response <- httr::content(response)
    sql <- response$templateSql
    return(sql)
  }
  else {
    ParallelLogger::logError("Error: No Sql returned for cohort definition id: ", 
                             cohortDefinition)
    stop()
  }
}
tmpfun <- get("getCohortSql", 
              envir = asNamespace("ROhdsiWebApi"))
environment(getCohortSql) <- environment(tmpfun)
assignInNamespace("getCohortSql", 
                  getCohortSql, ns = "ROhdsiWebApi")


getDefinitionsMetadata<- function (baseUrl, category) {
  .checkBaseUrl(baseUrl)
  arguments <- .getStandardCategories()
  argument <- arguments %>% dplyr::filter(.data$categoryStandard == 
                                            !!category)
  errorMessage <- checkmate::makeAssertCollection()
  checkmate::assertCharacter(category, min.len = 1, add = errorMessage)
  checkmate::assertNames(x = category, subset.of = arguments$categoryStandard)
  checkmate::reportAssertions(errorMessage)
  categoryUrl <- argument %>% dplyr::pull(.data$categoryUrl)
  url <- paste(baseUrl, categoryUrl, "?size=100000000", sep = "/")
  request <- httr::GET(url, httr::add_headers(Authorization = authHeader))
  if (!request$status == 200) {
    ParallelLogger::logError(argument$categoryFirstUpper, 
                             " definitions not found. Unable to retrieve meta data. Please try later.")
    stop()
  }
  group1 <- c("conceptSet", "cohort", "incidenceRate", "estimation", 
              "prediction")
  group2 <- c("characterization", "pathway")
  if (category %in% group1) {
    request <- httr::content(request)
  }
  else if (category %in% group2) {
    request <- httr::content(request)$content
  }
  request <- tidyr::tibble(request = request) %>% tidyr::unnest_wider(request) %>% 
    utils::type.convert(as.is = TRUE, dec = ".") %>% .standardizeColumnNames() %>% 
    .normalizeDateAndTimeTypes()
  return(request)
}
tmpfun <- get("getDefinitionsMetadata", 
              envir = asNamespace("ROhdsiWebApi"))
environment(getDefinitionsMetadata) <- environment(tmpfun)
assignInNamespace("getDefinitionsMetadata", 
                  getDefinitionsMetadata, ns = "ROhdsiWebApi")

# trace(getCdmSources,edit=TRUE) 
#change line line 5 to   "request <- httr::GET(url, httr::add_headers(Authorization = authHeader))"

# trace(getDefinition,edit=TRUE) 
#l12 to "response <- httr::GET(url, httr::add_headers(Authorization = authHeader))"
#l40 to "expression <- httr::GET(urlExpression, httr::add_headers(Authorization = authHeader))"

# trace(getCohortSql,edit=TRUE) 
#line 27 to   "response <- httr::POST(url, body = validJsonExpression,  config = httr::add_headers(httpheader, Authorization = authHeader))"

# clean folders -----
# will remove any existing cohorts 
unlink("inst/cohorts/*")
unlink("inst/sql/sql_server/*")
unlink("inst/settings/*")

# CohortsToCreate csv -----
# atlasId	atlasName	cohortId	name
AllCohorts<-suppressWarnings(getCohortDefinitionsMetaData(baseUrl))
# all cohorts in Atlas

CohortsToCreate<-AllCohorts %>% 
  filter(id %in% Atlas.ids) %>% 
  select(id, name) %>% 
  rename(atlasId=id,
         atlasName=name) %>% 
  mutate(cohortId=atlasId,
         name=atlasName)

write.csv(CohortsToCreate,
          row.names = FALSE,
          "inst/settings/CohortsToCreate.csv")
# get jsons  ------
fileName = "inst/settings/CohortsToCreate.csv"
jsonFolder = "inst/cohorts"
sqlFolder = "inst/sql/sql_server"
rFileName = "R/CreateCohorts.R"
insertTableSql = TRUE
insertCohortCreationR = TRUE
generateStats = TRUE
cohortsToCreate <- readr::read_csv(file = fileName, col_types = readr::cols(), 
                                   guess_max = 1e+07, locale = readr::locale(encoding = "UTF-8")) %>% 
  dplyr::mutate(name = .data$name %>% as.character() %>% 
                  trimws())
for (i in 1:nrow(cohortsToCreate)) {
  writeLines(paste("Inserting cohort:", cohortsToCreate$name[i]))
  insertCohortDefinitionInPackage(cohortId = cohortsToCreate$atlasId[i], 
                                  name = cohortsToCreate$name[i], baseUrl = baseUrl, 
                                  jsonFolder = jsonFolder, sqlFolder = sqlFolder, 
                                  generateStats = generateStats)
}

# add sql to set up cohort table-----
sql <-"IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
	DROP TABLE @cohort_database_schema.@cohort_table;

CREATE TABLE @cohort_database_schema.@cohort_table (
	cohort_definition_id BIGINT,
	subject_id BIGINT,
	cohort_start_date DATE,
	cohort_end_date DATE
	);

IF OBJECT_ID('tempdb..#cohort_inclusion', 'U') IS NOT NULL 
  DROP TABLE #cohort_inclusion;
  
IF OBJECT_ID('tempdb..#cohort_inc_result', 'U') IS NOT NULL 
  DROP TABLE #cohort_inc_result;
  
IF OBJECT_ID('tempdb..#cohort_inc_stats', 'U') IS NOT NULL 
  DROP TABLE #cohort_inc_stats;
  
IF OBJECT_ID('tempdb..#cohort_summary_stats', 'U') IS NOT NULL 
  DROP TABLE #cohort_summary_stats;

CREATE TABLE #cohort_inclusion (
	cohort_definition_id BIGINT NOT NULL,
	rule_sequence INT NOT NULL,
	name VARCHAR(255) NULL,
	description VARCHAR(1000) NULL
	);

CREATE TABLE #cohort_inc_result (
	cohort_definition_id BIGINT NOT NULL,
	inclusion_rule_mask BIGINT NOT NULL,
	person_count BIGINT NOT NULL,
	mode_id INT
	);

CREATE TABLE #cohort_inc_stats (
	cohort_definition_id BIGINT NOT NULL,
	rule_sequence INT NOT NULL,
	person_count BIGINT NOT NULL,
	gain_count BIGINT NOT NULL,
	person_total BIGINT NOT NULL,
	mode_id INT
	);

CREATE TABLE #cohort_summary_stats (
	cohort_definition_id BIGINT NOT NULL,
	base_count BIGINT NOT NULL,
	final_count BIGINT NOT NULL,
	mode_id INT
	);
"
writeChar(sql, file.path(sqlFolder, "CreateCohortTable.sql"), eos = NULL)


# get inclusion rules ------
.getCohortInclusionRules <- function(jsonFolder) {
  rules <- tidyr::tibble()
  for (file in list.files(path = jsonFolder, pattern = ".*\\.json")) {
    writeLines(paste("Parsing", file, "for inclusion rules"))
    definition <- RJSONIO::fromJSON(file.path(jsonFolder, file))
    if (!is.null(definition$InclusionRules)) {
      nrOfRules <- length(definition$InclusionRules)
      if (nrOfRules > 0) {
        cohortName <- sub(".json", "", file)
        for (i in 1:nrOfRules) {
          rules <- dplyr::bind_rows(rules, tidyr::tibble(cohortName = cohortName,
                                                         ruleSequence = i - 1,
                                                         ruleName = definition$InclusionRules[[i]]$name))
        }
      }
    }
  }
  rules
}
rules <- .getCohortInclusionRules(jsonFolder)
if (nrow(rules) > 0) {
  rules <- dplyr::inner_join(rules, tidyr::tibble(cohortId = cohortsToCreate$cohortId, 
                                                  cohortName = cohortsToCreate$name))
  csvFileName <- file.path(jsonFolder, "InclusionRules.csv")
  readr::write_csv(x = rules, path = csvFileName)
  writeLines(paste("- Created CSV file:", csvFileName))
}

# add create cohorts R ------
templateFileName <- system.file("CreateCohorts.R", package = "ROhdsiWebApi")
rCode <- readChar(templateFileName, file.info(templateFileName)$size)
rCode <- gsub("#CopyrightYear#", format(Sys.Date(), 
                                        "%Y"), rCode)
rCode <- gsub("#packageName#", packageName, rCode)
libPath <- gsub(".*inst[/\\]", "", fileName)
libPath <- gsub("/|\\\\", "\", \"", libPath)
rCode <- gsub("#fileName#", libPath, rCode)
rCode <- gsub("#stats_start#", "", rCode)
rCode <- gsub("#stats_end#", "", rCode)
fileConn <- file(rFileName)
writeChar(rCode, fileConn, eos = NULL)
close(fileConn)

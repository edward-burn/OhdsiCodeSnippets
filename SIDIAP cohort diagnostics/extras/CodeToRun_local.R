

# 1) Make sure you are inside the RProj
# You need to be inside the project. If you are, you should see "SIDIAP cohort diagnostics" on the top right

# 2) Set up environment
#install.packages("renv") # if not already installed, install renv from CRAN
renv::restore() # this should prompt you to install the various packages required for the study
source(here::here("extras","SetUp.R")) # this will load packages and bring in some functions

# 3) Check you have the cdm username and password saved in .Renviron
# If you haven´t already, save the username and password for the database to .Renviron by running:
# usethis::edit_r_environ()
# this will open the .Renviron, here add the following with username and password
# DB_USER = "...."
# DB_PASSWORD = "...."
user <- Sys.getenv("DB_USER")
password <- Sys.getenv("DB_PASSWORD")

# 4) Specify your cohorts of interest
# Ok, now specify what cohorts you want to include
# specify the set of ids from ATLAS
# I´m going to use the same name as whatever you called it in ATLAS
# please make sure this does not have trailing spaces and is not too long 
Atlas.ids<-""
# for example, 
#Atlas.ids<-c(507, 508)
# would bring in the cohorts 
# 507,[EB] CovCoag PE,508,[EB] CovCoag DVT
bring.in.cohorts()

# 5) Specify the name of your results table
cohort_table  <- "TestCohorts"
# this results table will be created with the people who are in your cohorts
# If the table already exists the following will overwrite it!
# To check if the already exists
check.table.names(cohort_table)

# 6) Specify what parts of cohort diagnostics you want to run
# Set the below to TRUE or FALSE depending on if you want it run or not
createCohorts = TRUE
runInclusionStatistics = TRUE
runOrphanConcepts = FALSE
runTimeDistributions = FALSE
runBreakdownIndexEvents = FALSE
runIncidenceRates = FALSE
runCohortOverlap = FALSE
runCohortCharacterization = FALSE
runTemporalCohortCharacterization = FALSE

# 7) Build the package
# once this is run and you have your cohorts in the package
# remember to (re)build your package
# "Build -> Install and Restart"
library(CohortDiag)

# 7) Choose which databases you want to run for
run.for<-c("HM")
# "HM", "SIDIAP", or "SIDIAP_H"
# to run for multiple: c("HM", "SIDIAP_H", "SIDIAP")

# 8) Run
source(here::here("extras","Run.R"))

# 9)  View results
# merge results
CohortDiagnostics::preMergeDiagnosticsFiles(file.path(here::here("results"), "diagnosticsExport"))
# View  results 
CohortDiagnostics::launchDiagnosticsExplorer(file.path(here::here("results"), "diagnosticsExport"))





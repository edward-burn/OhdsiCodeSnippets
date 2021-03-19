
# packages
library(ROhdsiWebApi)
library(DBI)
library(dbplyr)
library(dplyr)
library(here)
library(shiny)

# Functions 
check.table.names<- function(table.name) {
  
db <-dbConnect(RPostgreSQL::PostgreSQL(),
                dbname = "postgres20v2",
                port = 5432,
                host = "10.80.192.22", 
                user = user, 
                password = password)
if(any(stringr::str_to_lower(
    dbGetQuery(db,
           "SELECT table_name FROM information_schema.tables
                   WHERE table_schema='results20v2'")$table_name)
    ==stringr::str_to_lower(table.name))==TRUE){
  print("Table in SIDIAP with the same name")
} else {
  print("No table in SIDIAP with the same name")
}  
  if(any(stringr::str_to_lower(
    dbGetQuery(db,
           "SELECT table_name FROM information_schema.tables
                   WHERE table_schema='results20v2_h'")$table_name)
    ==stringr::str_to_lower(table.name))==TRUE){
  print("Table in SIDIAP_H with the same name")
} else {
  print("No table in SIDIAP_H with the same name")
}  

#HM
db <- dbConnect(RPostgreSQL::PostgreSQL(),
                dbname = "hmhospitals2",
                port = 5432,
                host = "10.80.192.22", 
                user = user, 
                password = password)
if(any(stringr::str_to_lower(
    dbGetQuery(db,
           "SELECT table_name FROM information_schema.tables
                   WHERE table_schema='results'")$table_name)
    ==stringr::str_to_lower(table.name))==TRUE){
  print("Table in HM with the same name")
} else {
  print("No table in HM with the same name")
}

}

bring.in.cohorts<-function(){

# remove any existing cohorts 
unlink("inst/cohorts/*")
unlink("inst/sql/sql_server/*")
unlink("inst/settings/*")
  
# CohortsToCreate csv 
# atlasId	atlasName	cohortId	name
AllCohorts<-getCohortDefinitionsMetaData("http://10.80.192.22:8080/WebAPI")
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
  
ROhdsiWebApi::insertCohortDefinitionSetInPackage(fileName = "inst/settings/CohortsToCreate.csv",
                                                 baseUrl = "http://10.80.192.22:8080/WebAPI",
                                                 insertTableSql = TRUE,
                                                 insertCohortCreationR = TRUE,
                                                 generateStats = TRUE,
                                                 packageName = "CohortDiag")
if(file.exists(here("inst/cohorts/InclusionRules.csv"))==FALSE){
write.csv(data.frame(cohortName=character(),ruleSequence=character(),ruleName=character(),cohortId=character()),
          row.names = FALSE,
          "inst/cohorts/InclusionRules.csv")}
  
}

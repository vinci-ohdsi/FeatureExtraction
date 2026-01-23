# @author Marc Suchard
# @author Rich Boyce

#' Create care-site covariate settings from the person table
#' 
#' @details
#' Creates an object specifying how care-site covariates should be constructed from 
#' person.care_site_id in the CDM model
#' 
#' @param analysisId                   Unique integer between 0 and 999
#' @param includeAncestorConcepts      Boolean: include ancestor concepts to identified care_site_concept_id
#' @param includedCareSiteClassIds     Restrict included concepts to care_site_class_id in given vector
#' 
#' @return
#' An object of type \code{covariateSettings} to be used in other functions.
#' 
#' @export
createPersonCareSiteCovariateSettings <- function(
    analysisId,
    includeAncestorConcepts = TRUE,
    includedCareSiteClassIds = NULL) {
  
  checkmate::check_integer(analysisId, lower = 0, upper = 999)
  checkmate::check_logical(includeAncestorConcepts)
  
  if (!is.null(includedCareSiteClassIds)) {
    checkmate::check_character(includedCareSiteClassIds)
    includedCareSiteClassIds <- paste(paste0("'", includedCareSiteClassIds, "'"), 
                                      collapse = ", ")
  } else {
    includedCareSiteClassIds <- ""
  }
  
  careSiteCovariateSettings <- createDetailedCovariateSettings(analyses = list(createAnalysisDetails(
    analysisId = analysisId,
    sqlFileName = "DemographicsCareSiteConcept.sql",
    parameters = list(analysisId = analysisId,
                      analysisName = "CareSite",
                      domainId = "CareSite",
                      includeAncestorConcepts = includeAncestorConcepts,
                      includedCareSiteClassIds = includedCareSiteClassIds),
    includedCovariateConceptIds =  c(),
    addDescendantsToInclude = FALSE,
    excludedCovariateConceptIds = c(),
    addDescendantsToExclude = FALSE,
    includedCovariateIds = c())))  
  
  return(careSiteCovariateSettings)  
}

#' Create care-site covariate settings from the care_site_era table
#' 
#' @details
#' Creates an object specifying how care-site covariates should be constructed from 
#' care_site_era in the CDM model
#' 
#' @param analysisId                   Unique integer between 0 and 999
#' @param startReferenceDate           Construct time-interval for covariate starting relative to 
#'                                     "cohort_start_date" or "cohort_end_date"
#' @param startDays                    Integer days relative to startReferenceDate or "anyTimePrior"
#' @param endReferenceDate             Construct time-interval for covariate ending relative toBibtex
#'                                     "cohort_start_date" or "cohort_end_date"
#' @param endDays                      Integer days relative to endReferenceDate or "anyTimeAfter"
#' @param includeAncestorConcepts      Boolean: include ancestor concepts to identified care_site_concept_id
#' @param includedCareSiteClassIds     Restrict included concepts to care_site_class_id in given vector
#' 
#' @return
#' An object of type \code{covariateSettings} to be used in other functions.
#' 
#' @export
createCareSiteEraCovariateSettings <- function(
    analysisId,
    startDays = -365,
    endDays = 0,
    startReferenceDate = "cohort_start_date",
    endReferenceDate = "cohort_start_date",
    includeAncestorConcepts = TRUE,
    includedCareSiteClassIds = NULL) {

  checkmate::check_integer(analysisId, lower = 0, upper = 999)
  if (startDays != "anyTimePrior") {
    checkmate::check_integer(startDays)
  }
  if (endDays != "anyTimeAfter") {
    checkmate::check_integer(endDays)
  }
  choices = c("cohort_start_date", "cohort_end_date")
  checkmate::check_choice(startReferenceDate, choices = choices)
  checkmate::check_choice(endReferenceDate, choices = choices)
  checkmate::check_logical(includeAncestorConcepts)
  
  if (!is.null(includedCareSiteClassIds)) {
    checkmate::check_character(includedCareSiteClassIds)
    includedCareSiteClassIds <- paste(paste0("'", includedCareSiteClassIds, "'"), 
                                      collapse = ", ")
  } else {
    includedCareSiteClassIds <- ""
  }
  
  careSiteCovariateSettings <- createDetailedCovariateSettings(
    analyses = list(createAnalysisDetails(
      analysisId = analysisId,
      sqlFileName = "CareSiteHistoryConcept.sql",
      parameters = list(analysisId = analysisId,
                        analysisName = "CareSite",
                        domainId = "CareSite",
                        endDay = endDays,
                        startDay = startDays,
                        endReferenceDate = endReferenceDate,
                        startReferenceDate = startReferenceDate,
                        timeLabel = makeTimeLabel(endDays, startDays,
                                                  endReferenceDate, startReferenceDate),
                        includeAncestorConcepts = includeAncestorConcepts,
                        includedCareSiteClassIds = includedCareSiteClassIds),
      includedCovariateConceptIds =  c(),
      addDescendantsToInclude = FALSE,
      excludedCovariateConceptIds = c(),
      addDescendantsToExclude = FALSE,
      includedCovariateIds = c())))
  
  return(careSiteCovariateSettings)
}

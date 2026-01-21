-- Feature construction

-- grab observed care site concepts
DROP TABLE IF EXISTS #tmp_person_care_site_concept1;

SELECT
	cohort.cohort_definition_id,
	cohort.subject_id,
	care_site.care_site_concept_id
INTO #tmp_person_care_site_concept1
FROM @cohort_table cohort
INNER JOIN @cdm_database_schema.person
	ON cohort.subject_id = person.person_id
INNER JOIN @cdm_database_schema.care_site
	ON person.care_site_id = care_site.care_site_id
WHERE cohort_definition_id != 0
{@cohort_definition_id != -1} ? {
	AND cohort_definition_id IN (@cohort_definition_id)
}
;

-- grab all ancestor and observed care site concepts
DROP TABLE IF EXISTS #tmp_person_care_site_concept2;

{@include_ancestor_concepts} ? {
SELECT
	cohort.cohort_definition_id,
	cohort.subject_id,
	ancestor.ancestor_concept_id AS care_site_concept_id
INTO #tmp_person_care_site_concept2	
FROM #tmp_person_care_site_concept1 AS cohort
JOIN @cdm_database_schema.concept_ancestor AS ancestor
	ON ancestor.descendant_concept_id = cohort.care_site_concept_id
WHERE ancestor.descendant_concept_id != ancestor.ancestor_concept_id
ORDER BY cohort_definition_id, subject_id
;
}

DROP TABLE IF EXISTS #tmp_person_care_site_concept;

SELECT
  cohort_definition_id,
  subject_id,
  care_site_concept_id
INTO #tmp_person_care_site_concept
FROM (
  SELECT * FROM #tmp_person_care_site_concept1
{@include_ancestor_concepts} ? {
  UNION
  SELECT * FROM #tmp_person_care_site_concept2
}
)
{@included_care_site_class_ids != ''} ? {
INNER JOIN @cdm_database_schema.concept
  ON care_site_concept_id = concept.concept_id
WHERE concept.concept_class_id IN (@included_care_site_class_ids)
}
ORDER BY cohort_definition_id, subject_id
;

-- make features
DROP TABLE IF EXISTS @covariate_table;

SELECT 
	CAST(care_site_concept_id AS BIGINT) * 1000 + @analysis_id AS covariate_id,
{@temporal | @temporal_sequence} ? {
    CAST(NULL AS INT) AS time_id,
}		
{@aggregated} ? {
	cohort_definition_id,
	COUNT(*) AS sum_value
} : {
	@row_id_field AS row_id,
	1 AS covariate_value 
}
INTO @covariate_table
FROM #tmp_person_care_site_concept
WHERE care_site_concept_id != 0
{@excluded_concept_table != ''} ? {	
	AND care_site_concept_id  NOT IN (SELECT id FROM @excluded_concept_table)
}
{@included_concept_table != ''} ? {
	AND care_site_concept_id IN (SELECT id FROM @included_concept_table)
}	
{@included_cov_table != ''} ? {	
	AND CAST(care_site_concept_id AS BIGINT) * 1000 + @analysis_id IN (
		SELECT id FROM @included_cov_table
	)
}	
{@cohort_definition_id != -1} ? {
	AND cohort_definition_id IN (@cohort_definition_id)
}
{@aggregated} ? {		
GROUP BY cohort_definition_id,
	care_site_concept_id 
}
;

-- Reference construction
INSERT INTO #cov_ref (
	covariate_id,
	covariate_name,
	analysis_id,
	concept_id
	)
SELECT covariate_id,
	CAST(CONCAT('person care site = ', CASE WHEN concept_name IS NULL THEN 'Unknown concept' ELSE concept_name END) AS VARCHAR(512)) AS covariate_name,
	@analysis_id AS analysis_id,
	CAST((covariate_id - @analysis_id) / 1000 AS INT) AS concept_id
FROM (
	SELECT DISTINCT covariate_id
	FROM @covariate_table
	) t1
LEFT JOIN @cdm_database_schema.concept
	ON concept_id = CAST((covariate_id - @analysis_id) / 1000 AS INT);
	
INSERT INTO #analysis_ref (
	analysis_id,
	analysis_name,
	domain_id,
{!@temporal} ? {
	start_day,
	end_day,
}
	is_binary,
	missing_means_zero
	)
SELECT @analysis_id AS analysis_id,
	CAST('@analysis_name' AS VARCHAR(512)) AS analysis_name,
	CAST('@domain_id' AS VARCHAR(20)) AS domain_id,
{!@temporal} ? {
	CAST(NULL AS INT) AS start_day,
	CAST(NULL AS INT) AS end_day,
}
	CAST('Y' AS VARCHAR(1)) AS is_binary,
	CAST(NULL AS VARCHAR(1)) AS missing_means_zero;
	

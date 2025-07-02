DROP TABLE IF EXISTS mimiciv_derived.sepsis_cohort_unique;
1. Create a new table to store the deduplicated Sepsis-3 ICU stay list.
CREATE TABLE mimiciv_derived.sepsis_cohort_unique AS
SELECT DISTINCT
    s.subject_id,
    s.icustay_id    AS stay_id,
    i.hadm_id
FROM mimiciv_derived.sepsis3 s
JOIN mimiciv.icustays i
  ON s.icustay_id = i.icustay_id;
SELECT COUNT(*) AS n_unique_sepsis
FROM mimiciv_derived.sepsis_cohort_unique;

2. Add an age column to the sepsis_cohort_unique table.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
ADD COLUMN age INTEGER;
3. Populate age from mimiciv_derived.age table and delete records that are not in the 65–89 age range.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET age = a.age
FROM mimiciv_derived.age a
WHERE sc.subject_id = a.subject_id
  AND sc.stay_id     = a.stay_id;
DELETE FROM mimiciv_derived.sepsis_cohort_unique
WHERE age < 65 OR age > 89;
SELECT COUNT(*) AS remaining_sepsis_stays
FROM mimiciv_derived.sepsis_cohort_unique;

4. Add a gender column to the sepsis_cohort_unique table
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
ADD COLUMN gender VARCHAR(10);
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET gender = d.gender
FROM mimiciv_derived.icustay_detail d
WHERE sc.stay_id = d.icustay_id;
SELECT
  gender,
  COUNT(*) AS count_stays
FROM mimiciv_derived.sepsis_cohort_unique
GROUP BY gender;

5. Add three columns: icu_intime, icu_outtime, icu_los in the sepsis_cohort_unique table.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
ADD COLUMN icu_intime TIMESTAMP,
ADD COLUMN icu_outtime TIMESTAMP,
ADD COLUMN icu_los DOUBLE PRECISION;
6. Populate these three columns from icustay_detail and delete records with ICU stays of less than 2 days.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET
  icu_intime  = d.icu_intime,
  icu_outtime = d.icu_outtime,
  icu_los     = d.icu_los
FROM mimiciv_derived.icustay_detail d
WHERE sc.stay_id = d.icustay_id;
DELETE FROM mimiciv_derived.sepsis_cohort_unique
WHERE icu_los < 2;
SELECT COUNT(*) AS remaining_sepsis_stays
FROM mimiciv_derived.sepsis_cohort_unique;

7. Added cam_icu_score column 
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
ADD COLUMN cam_icu_score VARCHAR(5);
8. First delete the stay_id that have a “Yes” before or within the first 24 hours of ICU admission.
DELETE FROM mimiciv_derived.sepsis_cohort_unique sc
WHERE EXISTS (
  SELECT 1
  FROM mimiciv_icu.chartevents ce
  WHERE ce.stay_id = sc.stay_id
    AND ce.itemid IN (
      229326, 228337, 229325, 228334, 228336,
      228303, 229324, 228300, 228335, 228302, 228301
    )
    AND ce.value = 'Yes'
    AND ce.charttime < sc.icu_intime + INTERVAL '24 hours'
);
9. The evaluation results after 24 hours of admission to the ICU are matched to the cam-icu score column I built first.
WITH first_cam AS (
  SELECT
    ce.stay_id,
    MIN(ce.charttime) AS first_charttime
  FROM mimiciv_icu.chartevents ce
  JOIN mimiciv_derived.sepsis_cohort_unique sc
    ON ce.stay_id = sc.stay_id
  WHERE ce.itemid IN (
      229326, 228337, 229325, 228334, 228336,
      228303, 229324, 228300, 228335, 228302, 228301
    )
    AND ce.charttime >= sc.icu_intime + INTERVAL '24 hours'
  GROUP BY ce.stay_id
),
cam_score AS (
  SELECT
    ce.stay_id,
    CASE
      WHEN ce.value = 'Yes'              THEN '1'
      WHEN ce.value = 'No'               THEN '0'
      ELSE 'none'                         'Unable to access'
    END AS cam_icu_score
  FROM mimiciv_icu.chartevents ce
  JOIN first_cam f
    ON ce.stay_id   = f.stay_id
   AND ce.charttime = f.first_charttime
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET cam_icu_score = cs.cam_icu_score
FROM cam_score cs
WHERE sc.stay_id = cs.stay_id;

SELECT COUNT(*) AS n_after_camicu
FROM mimiciv_derived.sepsis_cohort_unique;

10. Add delirium_assessment column
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
ADD COLUMN delirium_assessment VARCHAR(5);
11.Delete the records of positive cases before admission to ICU or within the first 24 hours.
DELETE FROM mimiciv_derived.sepsis_cohort_unique sc
WHERE EXISTS (
  SELECT 1
  FROM mimiciv_icu.chartevents ce
  WHERE ce.stay_id = sc.stay_id
    AND ce.itemid = 228332        -- Delirium assessment  itemid
    AND ce.value  = 'Positive'
    AND ce.charttime < sc.icu_intime + INTERVAL '24 hours'
);

12. Map the Delirium evaluation result after 24 hours to '1'/'0'/'none'.
WITH first_delirium AS (
  SELECT
    ce.stay_id,
    MIN(ce.charttime) AS first_time
  FROM mimiciv_icu.chartevents ce
  JOIN mimiciv_derived.sepsis_cohort_unique sc
    ON ce.stay_id = sc.stay_id
  WHERE ce.itemid = 228332
    AND ce.charttime >= sc.icu_intime + INTERVAL '24 hours'
  GROUP BY ce.stay_id
),
delirium_score AS (
  SELECT
    ce.stay_id,
    CASE
      WHEN ce.value = 'Positive' THEN '1'
      WHEN ce.value = 'Negative' THEN '0'
      ELSE 'none'               -- 包括 'UTA' (Unable To Assess)
    END AS delirium_assessment
  FROM mimiciv_icu.chartevents ce
  JOIN first_delirium fd
    ON ce.stay_id   = fd.stay_id
   AND ce.charttime = fd.first_time
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET delirium_assessment = ds.delirium_assessment
FROM delirium_score ds
WHERE sc.stay_id = ds.stay_id;
SELECT COUNT(*) AS n_after_delirium
FROM mimiciv_derived.sepsis_cohort_unique;

13. Delete cases where both cam_icu_score and delirium_assessment are 'none'.
DELETE FROM mimiciv_derived.sepsis_cohort_unique
WHERE cam_icu_score        = 'none'
  AND delirium_assessment  = 'none';
SELECT COUNT(*) AS remaining_after_both_none
FROM mimiciv_derived.sepsis_cohort_unique;

14. Add the following information to my table.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN admission_type        VARCHAR(50),
  ADD COLUMN hypertension          INT DEFAULT 0,
  ADD COLUMN diabetes              INT DEFAULT 0,
  ADD COLUMN cancer                INT DEFAULT 0,
  ADD COLUMN respiratory_failure   INT DEFAULT 0,
  ADD COLUMN renal_failure         INT DEFAULT 0,
  ADD COLUMN neurological_disease  INT DEFAULT 0,
  ADD COLUMN crrt                  INT DEFAULT 0,
  ADD COLUMN ventilator_setting    VARCHAR(50),
  ADD COLUMN weight                FLOAT;

15. Use mimiciv_hosp.admissions to populate admission_type.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET admission_type = ha.admission_type
FROM mimiciv_hosp.admissions ha
WHERE sc.hadm_id = ha.hadm_id;
16. Use the charlson table in mimiciv_derived to populate diabetes and respiratory_failure.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET
  diabetes            = ch.diabetes,
  respiratory_failure = ch.respiratory_failure
FROM mimiciv_derived.charlson ch
WHERE sc.hadm_id = ch.hadm_id;

17. Tags hypertension (ICD-9 4010/4011/4019).
WITH ht AS (
  SELECT DISTINCT hadm_id
  FROM mimiciv.diagnoses_icd
  WHERE icd_code LIKE '4010%' OR icd_code LIKE '4011%' OR icd_code LIKE '4019%'
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET hypertension = 1
FROM ht
WHERE sc.hadm_id = ht.hadm_id;

18. Tag cancer (ICD-10 Z860).
WITH ca AS (
  SELECT DISTINCT hadm_id
  FROM mimiciv.diagnoses_icd
  WHERE icd_code LIKE 'Z860%'
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET cancer = 1
FROM ca
WHERE sc.hadm_id = ca.hadm_id;

19. Tag neurological_disease (ICD-10 Z820).
WITH nd AS (
  SELECT DISTINCT hadm_id
  FROM mimiciv.diagnoses_icd
  WHERE icd_code LIKE 'Z820%'
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET neurological_disease = 1
FROM nd
WHERE sc.hadm_id = nd.hadm_id;

20. Tag renal_failure (ICD-10 N17, N170, N171, N172, N178, N179).
WITH rf AS (
  SELECT DISTINCT hadm_id
  FROM mimiciv.diagnoses_icd
  WHERE icd_code LIKE 'N17%' 
     OR icd_code IN ('N170','N171','N172','N178','N179')
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET renal_failure = 1
FROM rf
WHERE sc.hadm_id = rf.hadm_id;

21.Matches crrt.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET crrt = 1
FROM mimiciv_derived.crrt cr
WHERE sc.stay_id = cr.stay_id;

22. Matches ventilator_setting.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET ventilator_setting = vs.ventilation_mode
FROM mimiciv_derived.ventilator_settings vs
WHERE sc.stay_id = vs.stay_id;

23. Matches weight.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET weight = fw.weight
FROM mimiciv_derived.first_day_weight fw
WHERE sc.subject_id = fw.subject_id
  AND sc.stay_id     = fw.stay_id;

24. Matching midazolam (itemid = 221668).
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN midazolam_use  INTEGER DEFAULT 0,
  ADD COLUMN fentanyl_use   INTEGER DEFAULT 0;
WITH mid_first AS (
  SELECT DISTINCT
    ie.stay_id
  FROM mimiciv.inputevents_mv ie
  JOIN mimiciv_derived.sepsis_cohort_unique sc
    ON ie.stay_id = sc.stay_id
  WHERE ie.itemid = 221668
    AND ie.starttime BETWEEN sc.icu_intime
                         AND sc.icu_intime + INTERVAL '24 hours'
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET midazolam_use = 1
FROM mid_first mf
WHERE sc.stay_id = mf.stay_id;

25. Matching  fentanyl (itemid = 225942).
WITH fen_first AS (
  SELECT DISTINCT
    ie.stay_id
  FROM mimiciv.inputevents_mv ie
  JOIN mimiciv_derived.sepsis_cohort_unique sc
    ON ie.stay_id = sc.stay_id
  WHERE ie.itemid = 225942
    AND ie.starttime BETWEEN sc.icu_intime
                         AND sc.icu_intime + INTERVAL '24 hours'
)
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET fentanyl_use = 1
FROM fen_first ff
WHERE sc.stay_id = ff.stay_id;
SELECT
  midazolam_use,
  COUNT(*) AS cnt
FROM mimiciv_derived.sepsis_cohort_unique
GROUP BY midazolam_use
ORDER BY midazolam_use;
SELECT
  fentanyl_use,
  COUNT(*) AS cnt
FROM mimiciv_derived.sepsis_cohort_unique
GROUP BY fentanyl_use
ORDER BY fentanyl_use;

26. Add all Day 1 vital signs columns in sepsis_cohort_unique table (using SBP/DBP/MBP).
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN heart_rate_max    FLOAT,
  ADD COLUMN heart_rate_min    FLOAT,
  ADD COLUMN heart_rate_mean   FLOAT,
  ADD COLUMN sbp_max           FLOAT,
  ADD COLUMN sbp_min           FLOAT,
  ADD COLUMN sbp_mean          FLOAT,
  ADD COLUMN dbp_max           FLOAT,
  ADD COLUMN dbp_min           FLOAT,
  ADD COLUMN dbp_mean          FLOAT,
  ADD COLUMN mbp_max           FLOAT,
  ADD COLUMN mbp_min           FLOAT,
  ADD COLUMN mbp_mean          FLOAT,
  ADD COLUMN resp_rate_max     FLOAT,
  ADD COLUMN resp_rate_min     FLOAT,
  ADD COLUMN resp_rate_mean    FLOAT,
  ADD COLUMN temperature_max   FLOAT,
  ADD COLUMN temperature_min   FLOAT,
  ADD COLUMN temperature_mean  FLOAT;
27. Bulk populate from first_day_vitalsign materialized table.
UPDATE mimiciv_derived.sepsis_cohort_unique sc
SET
  heart_rate_max    = vs.heart_rate_max,
  heart_rate_min    = vs.heart_rate_min,
  heart_rate_mean   = vs.heart_rate_mean,
  sbp_max           = vs.sbp_max,
  sbp_min           = vs.sbp_min,
  sbp_mean          = vs.sbp_mean,
  dbp_max           = vs.dbp_max,
  dbp_min           = vs.dbp_min,
  dbp_mean          = vs.dbp_mean,
  mbp_max           = vs.mbp_max,
  mbp_min           = vs.mbp_min,
  mbp_mean          = vs.mbp_mean,
  resp_rate_max     = vs.resp_rate_max,
  resp_rate_min     = vs.resp_rate_min,
  resp_rate_mean    = vs.resp_rate_mean,
  temperature_max   = vs.temperature_max,
  temperature_min   = vs.temperature_min,
  temperature_mean  = vs.temperature_mean
FROM mimiciv_derived.first_day_vitalsign AS vs
WHERE sc.subject_id = vs.subject_id
  AND sc.stay_id     = vs.stay_id;
SELECT
  COUNT(*) FILTER (WHERE sbp_max IS NOT NULL) AS n_with_sbp
FROM mimiciv_derived.sepsis_cohort_unique;

28. Add hematocrit_max、hematocrit_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN hematocrit_max    FLOAT,
  ADD COLUMN hematocrit_min    FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  hematocrit_max = lab.hematocrit_max,
  hematocrit_min = lab.hematocrit_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

29. Add hemoglobin_max、hemoglobin_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN hemoglobin_max    FLOAT,
  ADD COLUMN hemoglobin_min    FLOAT;
UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  hemoglobin_max = lab.hemoglobin_max,
  hemoglobin_min = lab.hemoglobin_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

30. Add platelets_max、platelets_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN platelets_max     FLOAT,
  ADD COLUMN platelets_min     FLOAT;
UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  platelets_max  = lab.platelets_max,
  platelets_min  = lab.platelets_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

31. Add wbc_max、wbc_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN wbc_max           FLOAT,
  ADD COLUMN wbc_min           FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  wbc_max        = lab.wbc_max,
  wbc_min        = lab.wbc_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

32. Add albumin_max、albumin_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN albumin_max       FLOAT,
  ADD COLUMN albumin_min       FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  albumin_max    = lab.albumin_max,
  albumin_min    = lab.albumin_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

33. Add aniongap_max、aniongap_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN aniongap_max      FLOAT,
  ADD COLUMN aniongap_min      FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  aniongap_max   = lab.aniongap_max,
  aniongap_min   = lab.aniongap_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

34. Add bicarbonate_max、bicarbonate_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN bicarbonate_max   FLOAT,
  ADD COLUMN bicarbonate_min   FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  bicarbonate_max = lab.bicarbonate_max,
  bicarbonate_min = lab.bicarbonate_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

35. Add bun_max、bun_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN bun_max           FLOAT,
  ADD COLUMN bun_min           FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  bun_max         = lab.bun_max,
  bun_min         = lab.bun_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

36. Add calcium_max、calcium_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN calcium_max       FLOAT,
  ADD COLUMN calcium_min       FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  calcium_max    = lab.calcium_max,
  calcium_min    = lab.calcium_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

37. Add creatinine_max、creatinine_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN creatinine_max    FLOAT,
  ADD COLUMN creatinine_min    FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  creatinine_max = lab.creatinine_max,
  creatinine_min = lab.creatinine_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

38. Add sodium_max、sodium_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN sodium_max        FLOAT,
  ADD COLUMN sodium_min        FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  sodium_max     = lab.sodium_max,
  sodium_min     = lab.sodium_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

39. Add potassium_max、potassium_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN potassium_max     FLOAT,
  ADD COLUMN potassium_min     FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  potassium_max  = lab.potassium_max,
  potassium_min  = lab.potassium_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

40. Add inr_max、inr_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN inr_max           FLOAT,
  ADD COLUMN inr_min           FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  inr_max        = lab.inr_max,
  inr_min        = lab.inr_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

41. Add pt_max、pt_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN pt_max            FLOAT,
  ADD COLUMN pt_min            FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  pt_max         = lab.pt_max,
  pt_min         = lab.pt_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

42. Add ptt_max、ptt_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN ptt_max           FLOAT,
  ADD COLUMN ptt_min           FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  ptt_max        = lab.ptt_max,
  ptt_min        = lab.ptt_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

43. Add lactate_max、lactate_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN lactate_max       FLOAT,
  ADD COLUMN lactate_min       FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  lactate_max    = lab.lactate_max,
  lactate_min    = lab.lactate_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

44. Add bilirubin_total_max、bilirubin_total_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN bilirubin_total_max FLOAT,
  ADD COLUMN bilirubin_total_min FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  bilirubin_total_max = lab.bilirubin_total_max,
  bilirubin_total_min = lab.bilirubin_total_min
FROM mimiciv_derived.first_day_lab AS lab
WHERE i.subject_id = lab.subject_id
  AND i.stay_id     = lab.stay_id;

45. Add ph_max、ph_min、po2_max、po2_min、pco2_max、pco2_min.
ALTER TABLE mimiciv_derived.sepsis_cohort_unique
  ADD COLUMN ph_max           FLOAT,
  ADD COLUMN ph_min           FLOAT,
  ADD COLUMN po2_max          FLOAT,
  ADD COLUMN po2_min          FLOAT,
  ADD COLUMN pco2_max         FLOAT,
  ADD COLUMN pco2_min         FLOAT;

UPDATE mimiciv_derived.sepsis_cohort_unique AS i
SET
  ph_max        = bg.ph_max,
  ph_min        = bg.ph_min,
  po2_max       = bg.po2_max,
  po2_min       = bg.po2_min,
  pco2_max      = bg.pco2_max,
  pco2_min      = bg.pco2_min
FROM mimiciv_derived.first_day_bg AS bg
WHERE i.subject_id = bg.subject_id
  AND i.stay_id     = bg.stay_id;

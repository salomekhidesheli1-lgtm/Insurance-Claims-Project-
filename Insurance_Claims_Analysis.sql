/*
=========================================================
Insurance Claims & Policy Performance Analysis
=========================================================

Project Objectives:
1. Clean and validate insurance customer data.
2. Remove duplicate and incomplete records.
3. Analyze insurance claim performance.
4. Segment customers by demographics and risk factors.
5. Identify high-risk customer groups.
6. Generate actionable business insights.

Skills Demonstrated:
- Data Cleaning
- Data Validation
- CTEs
- Window Functions
- Aggregations
- Customer Segmentation
- Risk Analysis
=========================================================
*/

-- =====================================================
-- DATA EXPLORATION
-- =====================================================

DESCRIBE insurance_data;

SELECT *
FROM insurance_data
WHERE age IS NULL OR age = '';

SELECT *
FROM insurance_data
WHERE region IS NULL OR region = '';

-- =====================================================
-- DATA CLEANING
-- =====================================================

SET SQL_SAFE_UPDATES = 0;

WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY `index`, PatientID, age, gender,
                            bmi, bloodpressure, diabetic,
                            children, smoker, region, claim
           ) AS row_num
    FROM insurance_data
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

CREATE TABLE `insurance_data_table` (
  `index` int DEFAULT NULL,
  `PatientID` int DEFAULT NULL,
  `age` text,
  `gender` text,
  `bmi` double DEFAULT NULL,
  `bloodpressure` int DEFAULT NULL,
  `diabetic` text,
  `children` int DEFAULT NULL,
  `smoker` text,
  `region` text,
  `claim` double DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO insurance_data_table
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY `index`, PatientID, age, gender,
                        bmi, bloodpressure, diabetic,
                        children, smoker, region, claim
       ) AS row_num
FROM insurance_data;

DELETE
FROM insurance_data_table
WHERE row_num > 1;

SELECT *
FROM insurance_data_table
WHERE age IS NULL
   OR claim IS NULL
   OR region IS NULL
   OR region = '';

DELETE
FROM insurance_data_table
WHERE region IS NULL OR region = '';

DELETE
FROM insurance_data_table
WHERE age IS NULL OR age = '';

-- =====================================================
-- KPI ANALYSIS
-- =====================================================

SELECT
    ROUND(SUM(claim), 2) AS total_claim_amount,
    ROUND(AVG(claim), 2) AS average_claim
FROM insurance_data_table;

SELECT COUNT(*) AS total_customers
FROM insurance_data_table;

-- =====================================================
-- CUSTOMER DEMOGRAPHIC ANALYSIS
-- =====================================================

SELECT
    region,
    ROUND(AVG(claim), 2) AS average_claim
FROM insurance_data_table
GROUP BY region
ORDER BY average_claim DESC;

SELECT
    gender,
    ROUND(AVG(claim), 2) AS average_claim
FROM insurance_data_table
GROUP BY gender
ORDER BY average_claim DESC;

-- =====================================================
-- CLAIM PERFORMANCE ANALYSIS
-- =====================================================

SELECT *
FROM insurance_data_table
ORDER BY claim DESC
LIMIT 10;

SELECT *
FROM insurance_data_table
ORDER BY claim
LIMIT 10;

-- =====================================================
-- BMI SEGMENTATION ANALYSIS
-- =====================================================

WITH bmi_categories AS (
    SELECT
        CASE
            WHEN bmi < 18.5 THEN 'Underweight'
            WHEN bmi < 25 THEN 'Normal'
            WHEN bmi < 30 THEN 'Overweight'
            ELSE 'Obese'
        END AS bmi_category,
        claim
    FROM insurance_data_table
)
SELECT
    bmi_category,
    COUNT(*) AS customers,
    ROUND(AVG(claim), 2) AS average_claim
FROM bmi_categories
GROUP BY bmi_category
ORDER BY average_claim DESC;

-- =====================================================
-- CLAIM VALUE SEGMENTATION
-- =====================================================

WITH claim_amount_categories AS (
    SELECT
        CASE
            WHEN claim <= 15000 THEN 'Low Claim'
            WHEN claim <= 35000 THEN 'Medium Claim'
            ELSE 'High Claim'
        END AS claim_category,
        claim
    FROM insurance_data_table
)
SELECT
    claim_category,
    COUNT(*) AS customers,
    ROUND(AVG(claim), 2) AS average_claim,
    ROUND(SUM(claim), 2) AS total_claim_amount
FROM claim_amount_categories
GROUP BY claim_category;

-- =====================================================
-- AGE GROUP ANALYSIS
-- =====================================================

WITH age_groups AS (
    SELECT
        CASE
            WHEN age <= 25 THEN '18-25'
            WHEN age <= 35 THEN '26-35'
            WHEN age <= 50 THEN '36-50'
            ELSE '51+'
        END AS age_group,
        claim
    FROM insurance_data_table
)
SELECT
    age_group,
    COUNT(*) AS customers,
    ROUND(AVG(claim), 2) AS average_claim
FROM age_groups
GROUP BY age_group
ORDER BY average_claim DESC;

-- =====================================================
-- HIGH-RISK CUSTOMER SEGMENTATION
-- =====================================================

WITH customer_risk AS (
    SELECT
        bmi,
        claim,
        CASE
            WHEN diabetic = 'Yes'
                 AND smoker = 'Yes'
                 AND bmi >= 30
            THEN 'High Risk'
            WHEN diabetic = 'Yes'
                 AND smoker = 'Yes'
            THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_level
    FROM insurance_data_table
)
SELECT
    risk_level,
    COUNT(*) AS customers,
    ROUND(AVG(bmi), 2) AS average_bmi,
    ROUND(AVG(claim), 2) AS average_claim
FROM customer_risk
GROUP BY risk_level
ORDER BY average_claim DESC;

-- =====================================================
-- REGIONAL CONTRIBUTION ANALYSIS
-- =====================================================

SELECT
    region,
    ROUND(SUM(claim), 2) AS total_claim_amount,
    ROUND(
        SUM(claim) * 100 /
        SUM(SUM(claim)) OVER(),
        2
    ) AS contribution_percentage
FROM insurance_data_table
GROUP BY region
ORDER BY total_claim_amount DESC;

-- =====================================================
-- CLAIM RANKING ANALYSIS
-- =====================================================

WITH ranked_claims AS (
    SELECT *,
           DENSE_RANK() OVER (
               ORDER BY claim DESC
           ) AS claim_rank
    FROM insurance_data_table
)
SELECT *
FROM ranked_claims
WHERE claim_rank <= 10;
-- Select the working database
USE tech_layoffs_db;

-- View raw staging data
SELECT * FROM Staging_layoffs;

-- Create the final table structure from the staging table
CREATE TABLE tech_layoffs LIKE Staging_layoffs;

-- Insert cleaned data into the final table
INSERT INTO tech_layoffs 
SELECT * FROM Staging_layoffs;

-- Identify duplicate records using ROW_NUMBER()
WITH Duplicate_cte AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY company, Location_HQ, Laid_off, `date`,
                        percentage, industry, `Source`, Stage,
                        Raised_mm, Country, `Date_Added`
         ) AS row_num
  FROM Staging_layoffs
)
SELECT * 
FROM Duplicate_cte 
WHERE row_num > 1;  -- these are duplicates


 -- Trim extra spaces in company names
UPDATE Staging_layoffs
SET company = TRIM(company);

-- Check distinct countries
SELECT DISTINCT country
FROM Staging_layoffs
ORDER BY 1;


 -- Preview conversion before updating
SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y') AS converted_date
FROM Staging_layoffs;

SELECT `Date_Added`, STR_TO_DATE(`Date_Added`, '%m/%d/%Y') AS converted_date
FROM Staging_layoffs;

-- Update the actual columns
UPDATE Staging_layoffs
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

UPDATE Staging_layoffs
SET `Date_Added` = STR_TO_DATE(`Date_Added`, '%m/%d/%Y');

-- Change column types to DATE
ALTER TABLE Staging_layoffs
MODIFY COLUMN `date` DATE;

ALTER TABLE Staging_layoffs
MODIFY COLUMN `Date_Added` DATE;

-- Find rows where both Laid_off and Percentage are blank
SELECT *
FROM Staging_layoffs
WHERE Laid_off = '' AND Percentage = '';

-- Find rows with null/blank industry
SELECT *
FROM Staging_layoffs
WHERE industry IS NULL OR industry = '';


-- Identify industry from other rows with same company/location
SELECT t1.company, t1.Location_HQ, t1.industry AS missing_industry, t2.industry AS available_industry
FROM Staging_layoffs t1
JOIN Staging_layoffs t2
  ON t1.Company = t2.Company
 AND t1.Location_HQ = t2.Location_HQ
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;
  
  
DELETE 
FROM Staging_layoffs
WHERE Laid_off = '' AND Percentage = '';

ALTER TABLE Staging_layoffs DROP COLUMN `source`;
ALTER TABLE Staging_layoffs DROP COLUMN id;


-- Review cleaned staging table
SELECT * FROM Staging_layoffs;

-- Review final production table
SELECT * FROM tech_layoffs;











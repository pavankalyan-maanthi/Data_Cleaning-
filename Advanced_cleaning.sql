-- ------------------------------------------
-- Data Cleaning Project - Final Script
-- Working Table: Staging_layoffs_Backup
-- Raw Table: Staging_layoffs (kept unchanged)
-- ------------------------------------------

-- 🔹 1. Create a backup (work on this going forward)
CREATE TABLE IF NOT EXISTS Staging_layoffs_Backup AS
SELECT * FROM Staging_layoffs;

-- =======================================================
-- 2. Standardize Column Data Types
-- =======================================================

ALTER TABLE Staging_layoffs_Backup
  MODIFY COLUMN Company VARCHAR(255),
  MODIFY COLUMN Location_HQ VARCHAR(255),
  MODIFY COLUMN Laid_off INT,
  MODIFY COLUMN Industry VARCHAR(255),
  MODIFY COLUMN Stage VARCHAR(255),
  MODIFY COLUMN Country VARCHAR(255),
  MODIFY COLUMN date DATE,
  MODIFY COLUMN date_added DATE;

-- =======================================================
-- 3. Clean Laid_off Column
-- =======================================================

-- Find bad records
SELECT * 
FROM Staging_layoffs_Backup
WHERE TRIM(Laid_off) = ''
   OR Laid_off IS NULL
   OR TRIM(Laid_off) NOT REGEXP '^[0-9]+$'
LIMIT 150;

-- Replace blanks/non-numeric with NULL
UPDATE Staging_layoffs_Backup
SET Laid_off = NULL
WHERE TRIM(Laid_off) = ''
   OR Laid_off NOT REGEXP '^[0-9]+$';

-- =======================================================
-- 4. Clean Percentage Column
-- =======================================================

-- Identify invalid values
SELECT * 
FROM Staging_layoffs_Backup
WHERE TRIM(percentage) = ''
   OR percentage IS NULL
   OR TRIM(percentage) NOT REGEXP '^[0-9]+(\.[0-9]+)?%?$';

-- Remove % symbol
UPDATE Staging_layoffs_Backup
SET percentage = REPLACE(percentage, '%', '')
WHERE percentage LIKE '%\%%';

-- Replace blanks with NULL
UPDATE Staging_layoffs_Backup
SET percentage = NULL
WHERE TRIM(percentage) = '';

-- Convert column to INT (whole numbers only)
ALTER TABLE Staging_layoffs_Backup
MODIFY COLUMN percentage INT;

-- =======================================================
-- 5. Clean Raised_mm Column
-- =======================================================

-- Remove unwanted characters
UPDATE Staging_layoffs_Backup
SET raised_mm = REPLACE(raised_mm, '$', '');

UPDATE Staging_layoffs_Backup
SET raised_mm = REPLACE(raised_mm, ',', '');

UPDATE Staging_layoffs_Backup
SET raised_mm = TRIM(raised_mm);

-- Set invalid numeric values to NULL
UPDATE Staging_layoffs_Backup
SET raised_mm = NULL
WHERE raised_mm NOT REGEXP '^[0-9]+(\.[0-9]+)?$';

-- Convert to DECIMAL for analysis
ALTER TABLE Staging_layoffs_Backup
MODIFY COLUMN raised_mm DECIMAL(15,2);

-- =======================================================
-- 6. Sync with World_layoffs1
-- =======================================================

-- Create a copy of World_layoffs for safe joins
CREATE TABLE IF NOT EXISTS World_layoffs1 LIKE World_layoffs;

INSERT INTO World_layoffs1
SELECT * FROM World_layoffs;

-- Update backup with values from World_layoffs1
UPDATE Staging_layoffs_Backup AS s
JOIN World_layoffs1 AS w
  ON s.company = w.company
SET s.raised_mm = w.raised_mm,
    s.percentage = w.percentage;

-- Ensure no blanks remain
UPDATE Staging_layoffs_Backup
SET Raised_mm = NULL
WHERE Raised_mm = '';

-- =======================================================
-- 7. Final Check
-- =======================================================

DESCRIBE Staging_layoffs_Backup;

SELECT *
FROM Staging_layoffs_Backup
LIMIT 20;
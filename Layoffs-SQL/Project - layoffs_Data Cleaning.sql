-- Data Cleaning

SELECT * 
FROM layoffs;


CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

SELECT * 
FROM layoffs_staging;

-- 1. Remove Duplicates
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- to check duplicates
SELECT *
FROM layoffs_staging
WHERE company ='Casper';

-- to delete duplicates (#1)
WITH duplicate_cte AS
(
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

-- to delete duplicates (#2)
-- create a new table `layoffs_staging2`
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- to check the table created
SELECT *
FROM layoffs_staging2;

-- to insert info into the table created
INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- to check the table
SELECT *
FROM layoffs_staging2;

-- to chech the columns that are duplicated
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- to update or delete records without specifying a key
SET SQL_SAFE_UPDATES = 0;

-- to set this back with SET SQL_SAFE_UPDATES = 1 

-- to delete the duplicated rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- to check the table without duplicated rows
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- to see all the table created
SELECT *
FROM layoffs_staging2;

-- 2. Standardize the Data

SELECT company, TRIM(company)
FROM layoffs_staging2;

-- to trim the company's name
UPDATE layoffs_staging2
SET company = TRIM(company);

-- to look the industry's names
SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- to update industry's name 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- to look location's names
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- to look for country
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- to trim the (.) from country
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- to update the (.) form country
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- to change the date column from text
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- to update the date
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- to look for the date
SELECT `date`
FROM layoffs_staging2;

-- to change the date format from text to date
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. Null Values or blank values

-- to look for null values in total_laid_off
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry is NULL
OR industry = '';

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- update blank spaces to NULL
UPDATE layoffs_staging2 
SET industry = NULL
WHERE industry = '';

-- update from NULL
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- 4. Remove any Columns or Rows

SELECT *
FROM layoffs_staging2;

-- to delete columns that total_laid_off and percentage_laid_off is NULL
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- to drop a column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

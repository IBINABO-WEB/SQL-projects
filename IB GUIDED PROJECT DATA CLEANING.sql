....DATA CLEANING


SELECT*
FROM layoffs;

---1.Remove duplicates
---2.Standardize
---3.Null values or blank values
---4.Remove unnecessary column

---Create a new table duplicate

CREATE TABLE layoffs_staging
(LIKE layoffs);

---Insert all the data from the original table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

---view new table
SELECT *
FROM layoffs_staging;

---1. Remove duplicates
---Attach a row number to the table
SELECT *,
ROW_NUMBER()OVER(PARTITION BY company,location,industry,total_laid,percentage,date,stage,country,funds_raised_millions)
FROM layoffs_staging;

WITH duplicate_cte AS
(SELECT *,
ROW_NUMBER()OVER(PARTITION BY company,location,industry,total_laid,percentage,date,stage,country,funds_raised_millions)
FROM layoffs_staging)
SELECT *
FROM duplicate_cte
WHERE row_number>1;


---Delete rows

---Create a new table layoffs_staging2 to include the row_num column
CREATE TABLE IF NOT EXISTS public.layoffs_staging2
(
    company character varying(100) COLLATE pg_catalog."default",
    location character varying(100) COLLATE pg_catalog."default",
    industry character varying(100) COLLATE pg_catalog."default",
    total_laid integer,
    percentage numeric,
    date timestamp without time zone,
    stage character varying(100) COLLATE pg_catalog."default",
    country character varying(100) COLLATE pg_catalog."default",
    funds_raised_millions numeric,
	row_num integer
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.layoffs_staging
    OWNER to postgres;

SELECT*
FROM layoffs_staging2;
----Insert values from layoffs_staging table

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER()OVER(PARTITION BY company,location,industry,total_laid,percentage,date,stage,country,funds_raised_millions)
FROM layoffs_staging;  

--- Delete from layoffs_staging2 table
DELETE 
FROM layoffs_staging2
WHERE row_num>1;

SELECT *
FROM layoffs_staging2
WHERE row_num>1;

----Standardizing data(fixing issues in the data)
---Trimming the data
SELECT *
FROM layoffs_staging2;

SELECT company,TRIM(company) AS trimmed_company
FROM layoffs_staging2;

---update the table with this value
UPDATE layoffs_staging
SET company= TRIM(company)

SELECT  DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

---multiple rows with dfferent crypto formats
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

---update table 
UPDATE layoffs_staging2
SET industry='Crypto'
WHERE industry LIKE 'Crypto%';

---To check
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT industry
FROM layoffs_staging2;

---Check location (Looks good)
SELECT DISTINCT location
FROM layoffs_staging2;

---Check country column
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

SELECT  DISTINCT country,RTRIM(country,'.')
FROM layoffs_staging2
WHERE country LIKE 'United States%'

UPDATE layoffs_staging2
SET country=RTRIM(country,'.')
WHERE country LIKE  'United States%';

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

 ----NULL OR BLANK VALUES
SELECT*
FROM layoffs_staging2
WHERE industry IS NULL OR industry='';



SELECT*
FROM layoffs_staging2
WHERE company='Juul';

---Make a join
SELECT*
FROM layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS t2
ON t1.company =t2.company
WHERE (t1.industry IS NULL OR t1.industry= '') 
AND t2.industry IS NOT NULL;

---Before updating,change blank spaces to nulls
UPDATE layoffs_staging2
SET industry=NULL
WHERE industry= '';

---To check
SELECT *
FROM layoffs_staging2
WHERE company='Airbnb';

---Filling up the table,first make a cte

WITH industry_layoffs AS(
SELECT t1.company,t2.industry
FROM layoffs_staging2 AS t1
INNER JOIN layoffs_staging2 AS t2
ON t1.company=t2.company
WHERE t1.industry IS NULL AND
	t2.industry IS NOT NULL
	)

UPDATE layoffs_staging2
SET industry=industry_layoffs.industry
FROM industry_layoffs
WHERE layoffs_staging2.company=industry_layoffs.company
AND layoffs_staging2.industry IS NULL;


---Delete columns with NULL values
SELECT *
FROM layoffs_staging2
WHERE total_laid IS NULL 
AND percentage IS NULL;

DELETE
FROM layoffs_staging2
WHERE total_laid IS NULL 
AND percentage IS NULL;

---Delete row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;
---The End





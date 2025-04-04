

-- DATA CLEANING 

-- Create a backup table to preserve the original data
CREATE TABLE laptops_backup LIKE laptopdata;

-- Insert data into the backup table
INSERT INTO laptops_backup
SELECT * FROM laptopdata;

-- Rename column `Unnamed: 0` to `IndexNo` with INT datatype
ALTER TABLE laptopdata
CHANGE COLUMN `Unnamed: 0` IndexNo INT NOT NULL;

-- Drop rows where all specified columns are NULL
DELETE FROM laptopdata
WHERE company IS NULL
AND typename IS NULL
AND inches IS NULL
AND ScreenResolution IS NULL
AND Cpu IS NULL
AND Ram IS NULL
AND Memory IS NULL
AND gpu IS NULL
AND OpSys IS NULL
AND Weight IS NULL
AND price IS NULL;

-- Modify column datatypes to ensure consistent formats
ALTER TABLE laptopdata
MODIFY COLUMN company VARCHAR(255),
MODIFY COLUMN typename VARCHAR(255),
MODIFY COLUMN inches VARCHAR(255),
MODIFY COLUMN ScreenResolution VARCHAR(255),
MODIFY COLUMN Cpu VARCHAR(255),
MODIFY COLUMN Gpu VARCHAR(255),
MODIFY COLUMN Memory VARCHAR(255),
MODIFY COLUMN OpSys VARCHAR(255);

-- Remove 'GB' from the Ram column and convert it to INT
UPDATE laptopdata
SET ram = REPLACE(ram,"GB","");
ALTER TABLE laptopdata
MODIFY COLUMN Ram INT;

-- Remove 'kg' from the Weight column and convert it to DECIMAL
UPDATE laptopdata
SET weight = REPLACE(weight,"kg","");
ALTER TABLE laptopdata
MODIFY COLUMN weight DECIMAL(5,2);

-- Trim spaces from the Weight column
UPDATE laptopdata
SET weight = TRIM(weight);

-- Replace empty strings with NULL in Weight column
UPDATE laptopdata
SET weight = REPLACE(weight,"",NULL);

-- Restore NULL weight values from the backup table
UPDATE laptopdata AS ld
JOIN laptops_backup AS lb 
ON ld.indexno = lb.id 
SET ld.weight = lb.weight;

-- Round the Price column values
UPDATE laptopdata
SET price = ROUND(price);
ALTER TABLE laptopdata
MODIFY COLUMN price INT;

-- Standardize Operating System names
SELECT DISTINCT opsys FROM laptopdata;
UPDATE laptopdata
SET opsys = 
CASE 
    WHEN opsys LIKE "mac%" THEN "MacOs"
    WHEN opsys LIKE "windows%" THEN "Windows"
    WHEN opsys LIKE "linux%" THEN "Linux"
    WHEN opsys LIKE "no%" THEN "No Os"
    WHEN opsys LIKE "%android%" THEN "Others"
    WHEN opsys LIKE "%chrome%" THEN "Others"
END;

-- Add GPU brand and name columns
ALTER TABLE laptopdata
ADD COLUMN Gpu_brand VARCHAR(255) AFTER gpu,
ADD COLUMN Gpu_name VARCHAR(255) AFTER Gpu_brand;

-- Extract GPU brand from the GPU column
UPDATE laptopdata
SET gpu_brand = substring_index(gpu," ",1);

-- Extract GPU name by removing the brand name
UPDATE laptopdata
SET gpu_name = REPLACE(gpu,gpu_brand,"");

-- Drop the original GPU column
ALTER TABLE laptopdata
DROP COLUMN gpu;

-- Add CPU brand, name, and speed columns
ALTER TABLE laptopdata
ADD COLUMN Cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN Cpu_name VARCHAR(255) AFTER Cpu_brand,
ADD COLUMN Cpu_speed VARCHAR(255) AFTER Cpu_name;

-- Extract CPU brand
UPDATE laptopdata
SET Cpu_brand = substring_index(Cpu," ",1);

-- Remove 'GHz' from CPU column
UPDATE laptopdata
SET Cpu = Replace(Cpu,"GHz","");

-- Extract CPU speed
UPDATE laptopdata
SET Cpu_speed = substring_index(Cpu," ",-1);

-- Remove CPU brand and speed to extract CPU name
UPDATE laptopdata
SET cpu = REPLACE(Cpu,cpu_brand,"");
UPDATE laptopdata
SET cpu = REPLACE(Cpu,cpu_speed,"");

-- Restore CPU name from backup
UPDATE laptopdata l1
JOIN laptopdata l2
ON l1.indexno = l2.indexno
SET l1.cpu_name = l2.cpu;

-- Drop the original CPU column
ALTER TABLE laptopdata
DROP COLUMN cpu;

-- Add new columns for resolution and screen type
ALTER TABLE laptopdata
ADD COLUMN Resolution_width VARCHAR(255) AFTER ScreenResolution,
ADD COLUMN Resolution_height VARCHAR(255) AFTER Resolution_width,
ADD COLUMN Screen VARCHAR(255) AFTER Resolution_height,
ADD COLUMN TouchScreen VARCHAR(255) AFTER Screen;

-- Extract screen resolution width
UPDATE laptopdata t1
JOIN (SELECT indexno,SUBSTRING_INDEX(substring_index(screenresolution," ",-1),"x",1) width
       FROM laptopdata) t2
ON t1.indexno = t2.indexno
SET t1.resolution_width = t2.width;

-- Extract screen resolution height
UPDATE laptopdata t1
JOIN (SELECT indexno,SUBSTRING_INDEX(substring_index(screenresolution," ",-1),"x",-1) height
       FROM laptopdata) t2
ON t1.indexno = t2.indexno
SET t1.resolution_height = t2.height;

-- Identify touchscreen laptops
UPDATE laptopdata
SET TouchScreen = 
CASE
   WHEN screenresolution LIKE "%touch%" THEN 1
   ELSE 0
END;

-- Drop old screen resolution and screen columns
ALTER TABLE laptopdata
DROP COLUMN screenresolution,
DROP COLUMN screen;

-- Standardize CPU names
UPDATE laptopdata
SET cpu_name = 
CASE 
    WHEN opsys LIKE "%i5%" THEN "Core i5"
    WHEN opsys LIKE "%i7%" THEN "Core i7"
    WHEN opsys LIKE "%i3%" THEN "Core i3"
END;

-- Restore CPU names from backup
UPDATE laptopdata AS ld
JOIN laptops_backup AS lb 
ON ld.indexno = lb.id 
SET ld.cpu_name = lb.cpu_name;

-- Add columns for memory type and storage capacity
ALTER TABLE laptopdata
ADD COLUMN memory_type VARCHAR(255) AFTER memory,
ADD COLUMN primary_storage VARCHAR(255) AFTER memory_type,
ADD COLUMN secondary_storage VARCHAR(255) AFTER primary_storage;

-- Extract memory type
UPDATE laptopdata
SET memory_type = CASE 
    WHEN memory LIKE "%SSD%" AND memory LIKE "%HDD%" THEN "Hybrid"
    WHEN memory LIKE "%SSD%" THEN "SSD"
    WHEN memory LIKE "%HDD%" THEN "HDD"
    WHEN memory LIKE "%Flash Storage%" THEN "Flash Storage"
    WHEN memory LIKE "%Flash Storage%" AND memory LIKE "%HDD%" THEN "Hybrid"
    ELSE memory
    END;

-- Extract primary storage size
UPDATE laptopdata
SET primary_storage = REPLACE(REPLACE(SUBSTRING_INDEX(memory," ",1),"GB",""),"TB","");

-- Extract secondary storage size
UPDATE laptopdata
SET secondary_storage = CASE WHEN memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(memory,"+",-1),'[0-9]+') ELSE 0 END;

-- Convert TB to GB for consistency
UPDATE laptopdata
SET primary_storage = CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage = CASE WHEN secondary_storage > 0  THEN secondary_storage*1024 ELSE secondary_storage END;

-- Identify invalid primary storage values
SELECT primary_storage FROM laptopdata
WHERE primary_storage = "?";

--  EDA 

SELECT * FROM laptopdata; 

-- HEAD ,TAIL AND SAMPLE FOR DATA PREVIEW 

-- HEAD
SELECT * FROM laptopdata
ORDER BY indexno LIMIT 5;

-- TAIL 
SELECT * FROM laptopdata
ORDER BY indexno DESC LIMIT 5;

-- RANDOM
SELECT * FROM laptopdata
ORDER BY rand() LIMIT 5;


-- UNIVARIATE ANALYSIS NUMERICAL COLUMN
-- 8 NUMBER SUMMARY ON PRICE COLUMN 

WITH price_summary 
AS (SELECT price,
    ROW_NUMBER() OVER(ORDER BY price) row_num,
    COUNT(price) OVER() AS total_count
    FROM laptopdata )
SELECT 
MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    ROUND(STDDEV(price),2) AS std_dev,
    MAX(CASE WHEN row_num = FLOOR(0.25 * total_count) + 1 THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_count) + 1 THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_count) + 1 THEN price END) AS Q3
FROM price_summary;

-- 8 NUMBER SUMMARY ON Inches COLUMN 

WITH ppi_summary 
AS ( SELECT ppi,
     ROW_NUMBER() OVER( ORDER BY ppi) row_num,
     COUNT(ppi) OVER() total_count
     FROM laptopdata
     )
SELECT COUNT(ppi) total_ppi_count,
MIN(ppi) min_ppi,
MAX(ppi) max_ppi,
AVG(ppi) avg_ppi,
ROUND(STD(ppi),2) std_ppi,
MAX(CASE WHEN row_num = FLOOR(0.25 * total_count) + 1 THEN ppi END) AS 'Q1',
MAX(CASE WHEN row_num = FLOOR(0.50 * total_count) + 1 THEN ppi END) AS 'Q2',
MAX(CASE WHEN row_num = FLOOR(0.75 * total_count) + 1 THEN ppi END) AS 'Q3'
FROM ppi_summary;

-- checking missing value   TWO APPROACH

-- FIRST APPROACH 
-- COUNT(*) totalcount with null values COUNT(COL NAME) totalcount without 
-- null values so we can find how many null values in our column 
SELECT 
COUNT(*) - COUNT(company) AS missing_value_company,
COUNT(*) - COUNT(typename) AS missing_value_typename,
COUNT(*) - COUNT(inches) AS missing_value_inches,
COUNT(*) - COUNT(ppi) AS missing_value_ppi,
COUNT(*) - COUNT(price) AS missing_value_price
FROM laptopdata;

-- SECOND APPROACH  Here If there is any null value in our column IS NULL return 1 
-- and for non-null values return 0 so we can find no of null values in our column 

SELECT 
SUM(ppi IS NULL) missing_val_ppi,
SUM(ram IS NULL) missing_val_ram,
SUM(primary_Storage IS NULL) missing_val_pri_storage,
SUM(gpu_brand IS NULL) missing_val_gpu_brand,
SUM(price IS NULL) missing_val_price
FROM laptopdata;

-- OUTLIERS DETECTION ON price col

WITH price_data 
AS ( SELECT price,
     ROW_NUMBER() OVER(ORDER BY price) row_num,
     COUNT(price) OVER() total_count
     FROM laptopdata
     )
, percentile AS
	( SELECT
    MAX(CASE WHEN row_num = FLOOR(0.25 * total_count) + 1 THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_count) + 1 THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_count) + 1 THEN price END) AS Q3
    FROM price_data )
, min_max_data
 AS ( SELECT *, 
      (Q3 - Q1) AS IQR,
      (Q1 - 1.25*(Q3 - Q1)) AS minimum_val,
      (Q3 + 1.25*(Q3 - Q1)) AS maximum_val
      FROM percentile )
SELECT * FROM price_data 
CROSS JOIN min_max_data
WHERE price < minimum_val
OR price > maximum_val;

-- OUTLIER DETECTION ON INCHES COL 

WITH inches_data 
AS ( SELECT inches,
     ROW_NUMBER() OVER(ORDER BY inches) row_num,
     COUNT(inches) OVER() totalcount
	 FROM laptopdata )
, quartile 
AS ( SELECT 
     MAX(CASE WHEN row_num = FLOOR(0.25 * totalcount) + 1 THEN inches END) AS 'Q1',
     MAX(CASE WHEN row_num = FLOOR(0.50 * totalcount) + 1 THEN inches END) AS 'Q2',
     MAX(CASE WHEN row_num = FLOOR(0.75 * totalcount) + 1 THEN inches END) AS 'Q3'
     FROM inches_data )
SELECT *
FROM inches_data
CROSS JOIN quartile
WHERE inches < (Q1 - 1.25*(Q3-Q1)) 
OR inches > (Q3 + 1.25*(Q3-Q1));

--  HISTOGRAM ON numerical price column

WITH price_buc 
AS ( SELECT price,
CASE 
    WHEN price BETWEEN 0 AND 50000 THEN '0-50K' 
    WHEN price BETWEEN 50001 AND 100000 THEN '50K-100K' 
    WHEN price BETWEEN 100001 AND 150000 THEN '100-150K' 
    WHEN price > 150000 THEN '>150K' 
END AS 'price_buckets'
FROM laptopdata )
SELECT price_buckets,
COUNT(*),
REPEAT("|",COUNT(*)/10) noofphones
FROM price_buc 
GROUP BY price_buckets;

-- For Categorial cols 
-- There is not much work in categorial col we can find frequency count for each category

SELECT company,
COUNT(*) nooflaptops,
REPEAT("|",COUNT(*)/5) histogram
FROM laptopdata
GROUP BY company;

-- Numerical numerical 
--  side by side 8 number
WITH price_summary 
AS (SELECT price,
    ROW_NUMBER() OVER(ORDER BY price) row_num,
    COUNT(price) OVER() AS total_count
    FROM laptopdata )
SELECT 
MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    ROUND(STDDEV(price),2) AS std_dev,
    MAX(CASE WHEN row_num = FLOOR(0.25 * total_count) + 1 THEN price END) AS Q1,
    MAX(CASE WHEN row_num = FLOOR(0.50 * total_count) + 1 THEN price END) AS Q2,
    MAX(CASE WHEN row_num = FLOOR(0.75 * total_count) + 1 THEN price END) AS Q3
FROM price_summary;

WITH summary AS (
    SELECT 
        price, cpu_speed,
        ROW_NUMBER() OVER(ORDER BY price) AS row_num_price,
        ROW_NUMBER() OVER(ORDER BY cpu_speed) AS row_num_cpu,
        COUNT(*) OVER() AS total_count
    FROM laptopdata
)
SELECT 
    -- Price
    MIN(price) AS min_price, 
    MAX(price) AS max_price, 
    AVG(price) AS avg_price, 
    ROUND(STDDEV(price),2) AS std_dev_price,
    MAX(CASE WHEN row_num_price = FLOOR(0.25 * total_count) + 1 THEN price END) AS Q1_price,
    MAX(CASE WHEN row_num_price = FLOOR(0.50 * total_count) + 1 THEN price END) AS Q2_price,  
    MAX(CASE WHEN row_num_price = FLOOR(0.75 * total_count) + 1 THEN price END) AS Q3_price,
    -- CPU
    MIN(cpu_speed) AS min_cpu, 
    MAX(cpu_speed) AS max_cpu, 
    AVG(cpu_speed) AS avg_cpu, 
    ROUND(STDDEV(cpu_speed),2) AS std_dev_cpu,
    MAX(CASE WHEN row_num_cpu = FLOOR(0.25 * total_count) + 1 THEN cpu_speed END) AS Q1_cpu,
    MAX(CASE WHEN row_num_cpu = FLOOR(0.50 * total_count) + 1 THEN cpu_speed END) AS Q2_cpu, 
    MAX(CASE WHEN row_num_cpu = FLOOR(0.75 * total_count) + 1 THEN cpu_speed END) AS Q3_cpu
FROM summary;

-- scatterplot -- put data in excel to see graph 
SELECT inches,price FROM laptopdata;
SELECT * FROM laptopdata;

-- Categorial categorial Col 
-- contingency table for categorial col company & touchscreen

WITH contigency_table 
AS ( SELECT company,
	 SUM(CASE WHEN touchscreen = 1 THEN 1 ELSE 0 END) AS 'touchyes',
     SUM(CASE WHEN touchscreen = 0 THEN 1 ELSE 0 END) AS 'touchno'
     FROM laptopdata
     GROUP BY company )
SELECT company,
touchyes,
REPEAT("|",touchyes/2) AS 'Barchart-yes',
touchno,
REPEAT("|",touchno/2) AS 'Barchart-no'
FROM contigency_table
GROUP BY company;

-- Numerical Categorial Bivariate Analysis

SELECT company,
COUNT(*) laptopcount,
ROUND(MIN(price)) min_price,
ROUND(MAX(price)) max_price,
ROUND(AVG(price)) avg_price,
ROUND(STD(price)) std_price,
RANK() OVER(ORDER BY AVG(price) DESC) AS price_rank
FROM laptopdata
GROUP BY company;

-- FILTER LAPTOP ON PRICE RANGE BUDGET,MID-RANGE,PREMIUM AND 
-- FIND A TOTAL NO OF LAPTOPS EACH COMPANY OWN IN EACH CATEGORY

WITH company_price_analysis
AS (  
SELECT company,
COUNT(*) total_laptops,
SUM(CASE WHEN price < 50000 THEN 1 ELSE 0 END) AS "Budget-Laptop-count",
SUM(CASE WHEN price < 100000 THEN 1 ELSE 0 END) AS "Mid-Range laptop count",
SUM(CASE WHEN price > 100000 THEN 1 ELSE 0 END) AS "Premium laptop count"
FROM laptopdata
GROUP BY company )
SELECT * FROM company_price_analysis;


-- HANDLE NULL VALUES 
-- THERE IS NO NULL VALUE IN THIS DATASET SO WE CAN CREATE SOME NULL VALUE 
-- ON PRICE COLUMN SO WE CAN SEE HOW WE CAN HANDLE NULL VALUES

UPDATE laptopdata
SET price = NULL
WHERE indexno IN (10,20,44,150,50,65,200,130,34);

-- NOW HOW TO HANDLE NULL VALUE ITS UP TO YOU HOW YOU WANT TO HANDLE WHAT IS YOUR PREFERENCE LIKE
-- YOU CAN REPLACE IT WITH AVG LAPTOP PRICE OR WITH CORRESPONDING COMPANY AVG LAPTOP PRICE OR WITH STD WHATEVER

-- IN MY CASE I WANT TO REPLACE THAT NULL VALUE WITH THEIR CORRESPONDING COMPANY AVG LAPTOPPRICE

SELECT company,
AVG(price) 
FROM laptopdata
GROUP BY company;

-- SO BASICALLY WE WANT TO REPLACE NULL VALUE WITH AVG LAPTOP PRICE BUT THE CATCH IS THAT IF LAPTOP IS FROM APPLE COMPANY 
-- SO REPLACE IT WITH APPLE AVG LAPTOP PRICE NOT OTHER SAME AS WITH OTHER COMPANY 

UPDATE laptopdata l1
SET price = ( SELECT ROUND(AVG(price)) FROM laptopdata l2 WHERE l2.company = l1.company )
WHERE price IS NULL;

-- FOR MYSQL DOES NOT ALLOW DIRECT UPDATING ON THE SAME TABLE WE USE IN SUBQUERY ALTERNATIVE APPROACH 

UPDATE laptopdata l1
JOIN (
    SELECT company, ROUND(AVG(price)) AS avg_price
    FROM laptopdata
    WHERE price IS NOT NULL
    GROUP BY company
) AS t
ON l1.company = t.company
SET l1.price = t.avg_price
WHERE l1.price IS NULL;

-- FEATURE ENGINEERING 
-- WE CAN FIND PPI BY USING RESOLUTION_WIDTH, RESOLUTION_HEIGHT AND INCHES 
-- YOU CAN GOOGLE OR CHATGPT TO SEE THE FORMULA FOR FINDING PPI

-- CREATED A NEW COLUMN PPI
ALTER TABLE laptopdata
ADD COLUMN ppi INT AFTER resolution_height;

-- FIND A PPI WITH FORMULA
SELECT ROUND(SQRT((resolution_width*resolution_width + resolution_height*resolution_height))/inches) FROM laptopdata;

-- UPDATING PPI IN ACTUAL TABLE
UPDATE laptopdata
SET ppi = ROUND(SQRT((resolution_width*resolution_width + resolution_height*resolution_height))/inches);

-- ONE HOT ENCODING 

SELECT DISTINCT gpu_brand 
FROM laptopdata;

SELECT DISTINCT gpu_brand,
CASE WHEN gpu_brand = 'intel' THEN 1 ELSE 0 END AS 'Intel',
CASE WHEN gpu_brand = 'amd' THEN 1 ELSE 0 END AS 'AMD',
CASE WHEN gpu_brand = 'nvidia' THEN 1 ELSE 0 END AS 'Nvidia',
CASE WHEN gpu_brand = 'arm' THEN 1 ELSE 0 END AS 'ARM'
FROM laptopdata;

-- ONE HOT ENCODING ON Company Categorial Column

SELECT DISTINCT company 
FROM laptopdata;

--  There is lot of company in this dataset so we take only some famous company and do a one hot encoding on that company 

SELECT company,
CASE WHEN company = 'apple' THEN 1 ELSE 0 END AS 'Apple',
CASE WHEN company = 'hp' THEN 1 ELSE 0 END AS 'Hp',
CASE WHEN company = 'acer' THEN 1 ELSE 0 END AS 'Acer',
CASE WHEN company = 'dell' THEN 1 ELSE 0 END AS 'Dell',
CASE WHEN company = 'lenovo' THEN 1 ELSE 0 END AS 'Lenovo',
CASE WHEN company = 'asus' THEN 1 ELSE 0 END AS 'Asus'
FROM laptopdata;
 

use uncleaneddb;
select * from laptopdata;
select * from laptops_backup;
    





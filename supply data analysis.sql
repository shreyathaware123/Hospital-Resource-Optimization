# View the dataset
select * from supply;

-- Step 1: View First Few Records
SELECT * FROM supply
LIMIT 10;

-- Step 2: Check for NULLs
SELECT 
  SUM(date IS NULL) AS null_date,
  SUM(supply_type IS NULL) AS null_supply_type,
  SUM(used_units IS NULL) AS null_used_units,
  SUM(inventory_level IS NULL) AS null_inventory_level
FROM supply;

--- Conclusion : There are no null values

-- Step 3: Check for Duplicates
SELECT date, supply_type, COUNT(*) AS count
FROM supply
GROUP BY date, supply_type
HAVING count > 1;

--- Conclusion: There are no duplicates

-- Step 4: Check Date Format
select date from supply
limit 5;

-- Step 5: EDA (Exploratory Data Analysis)

-- A. Supply Types
SELECT DISTINCT supply_type FROM supply;

--- Conclusion : There are no duplicates in supply_type, all of them are unique
 
-- B. Average Used Units per Supply Type
SELECT supply_type, ROUND(AVG(used_units), 2) AS avg_used
FROM supply
GROUP BY supply_type;

-- C. Average Inventory per Supply Type
SELECT supply_type, ROUND(AVG(inventory_level), 2) AS avg_inventory
FROM supply
GROUP BY supply_type;

-- D. Daily Total Used Units
SELECT date , SUM(used_units) AS total_used
FROM supply
GROUP BY date
ORDER BY date;

--  Step 6: Outlier Detection Using IQR
-- A. For used_units

WITH ranked AS 
(
  SELECT used_units,
         NTILE(4) OVER (ORDER BY used_units) AS quartile
  FROM supply
),
iqr_calc AS 
(
  SELECT 
    MAX(CASE WHEN quartile = 1 THEN used_units END) AS Q1,
    MIN(CASE WHEN quartile = 3 THEN used_units END) AS Q3
  FROM ranked
)
SELECT *,
       Q3 - Q1 AS IQR,
       Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
       Q3 + 1.5 * (Q3 - Q1) AS upper_bound
FROM iqr_calc;

-- Step to Find Outliers in used_units:
SELECT *
FROM supply
WHERE used_units < 11.65 OR used_units > 48.29;

# clean data in used_units without outlier
SELECT *
FROM supply
WHERE used_units BETWEEN 11.65 AND  48.29;

-- Delete Outliers from used_units
DELETE FROM supply
WHERE used_units <11.65 OR used_units > 48.29;

# After Deletion - Just to check
SELECT 
MIN(used_units) AS min_used,
 MAX(used_units) AS max_used
FROM supply;

-- No outliers remain in used_units
--  Cleaning completed successfully

-- B. For inventory_level

WITH ranked AS (
  SELECT inventory_level,
         NTILE(4) OVER (ORDER BY inventory_level) AS quartile
  FROM supply
),
iqr_calc AS (
  SELECT 
    MAX(CASE WHEN quartile = 1 THEN inventory_level END) AS Q1,
    MIN(CASE WHEN quartile = 3 THEN inventory_level END) AS Q3
  FROM ranked
)
SELECT *,
       Q3 - Q1 AS IQR,
       Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
       Q3 + 1.5 * (Q3 - Q1) AS upper_bound
FROM iqr_calc;

-- Step to Find Outliers in inventory_level:
SELECT *
FROM supply
WHERE inventory_level < 948.13 OR inventory_level > 980.66;

# clean data in inventory_level without outlier
SELECT *
FROM supply
WHERE inventory_level BETWEEN 948.13 AND 980.66;

-- Delete Outliers from inventory_level
DELETE FROM supply
WHERE inventory_level < 948.13 OR inventory_level > 980.66;

# After Deletion - Just to check
SELECT 
  MIN(inventory_level) AS min_inventory, 
  MAX(inventory_level) AS max_inventory
FROM supply;

-- No outliers remain in inventory_level
--  Cleaning completed successfully


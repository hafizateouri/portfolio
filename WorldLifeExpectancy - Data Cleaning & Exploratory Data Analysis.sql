#STEP 1
#DATA CLEANING

SELECT *
FROM worldlifeexpectancy
;

#There should be only one entry per country for each year. Let's identify any duplicates:
SELECT Country, Year, CONCAT(Country, Year) as country_year, COUNT(CONCAT(Country, Year)) as count
FROM worldlifeexpectancy
GROUP BY Country, Year, CONCAT(Country, Year)
HAVING count > 1
;

#We identified 3 duplicates. Now, we need to identify their row ID to be able to remove them.
SELECT *
FROM(
SELECT Row_ID, CONCAT(Country, Year) as country_year,
ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
FROM worldlifeexpectancy
) AS Row_Table
WHERE Row_Num > 1
;

#Now let's delete them:
DELETE FROM worldlifeexpectancy 
WHERE Row_ID IN (
SELECT Row_ID
FROM(
SELECT Row_ID, CONCAT(Country, Year) as country_year,
ROW_NUMBER() OVER (PARTITION BY CONCAT(Country, Year) ORDER BY CONCAT(Country, Year)) as Row_Num
FROM worldlifeexpectancy
) AS Row_Table
WHERE Row_Num > 1
)
;

#Let's identify the blanks and the nulls
SELECT *
FROM worldlifeexpectancy
WHERE Status = ""
;

#Let's identify how many different status exist:
SELECT distinct(Status)
FROM worldlifeexpectancy
WHERE Status <> ""
;

SELECT Distinct(Country)
From worldlifeexpectancy
Where Status = "Developing";


UPDATE worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
ON t1.Country = t2.Country
SET t1.Status = "Developing"
WHERE t1.Status = "" AND t2.Status <> ""
AND t2.Status = "Developing"
;
 

UPDATE worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
ON t1.Country = t2.Country
SET t1.Status = "Developed"
WHERE t1.Status = "" AND t2.Status <> ""
AND t2.Status = "Developed"
;

#There are still other blanks, like for example in the "life expectancy" column:
SELECT *
FROM worldlifeexpectancy
;

SELECT *
FROM worldlifeexpectancy
WHERE `Life expectancy` = ""
;

SELECT Country, Year, `Life expectancy`
FROM worldlifeexpectancy
;

SELECT t1.Country, t1.Year, t1.`Life expectancy`, t2.Country, t2.Year, t2.`Life expectancy`
FROM worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
ON t1.Country = t2.Country
AND t1.year =  t2.year - 1
;

SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`
FROM worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
ON t1.Country = t2.Country
AND t1.year =  t2.year - 1
JOIN worldlifeexpectancy t3
ON t1.Country = t3.Country
AND t1.year =  t3.year + 1

WHERE t1.`Life expectancy` = ""
;

SELECT t1.Country, t1.Year, t1.`Life expectancy`, 
t2.Country, t2.Year, t2.`Life expectancy`,
t3.Country, t3.Year, t3.`Life expectancy`,
ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
FROM worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
ON t1.Country = t2.Country
AND t1.year =  t2.year - 1
JOIN worldlifeexpectancy t3
ON t1.Country = t3.Country
AND t1.year =  t3.year + 1
WHERE t1.`Life expectancy` = ""
;

UPDATE worldlifeexpectancy t1
JOIN worldlifeexpectancy t2
ON t1.Country = t2.Country
AND t1.year =  t2.year - 1
JOIN worldlifeexpectancy t3
ON t1.Country = t3.Country
AND t1.year =  t3.year + 1
SET t1.`Life expectancy`= ROUND((t2.`Life expectancy` + t3.`Life expectancy`)/2,1)
WHERE t1.`Life expectancy` = ""
;

SELECT *
FROM worldlifeexpectancy
;

#STEP 2
#EXPLORATORY DATA ANALYSIS

#Let's compare the best and worst life expectancy for each country to see the evolution:
SELECT Country, MIN(`Life expectancy`), MAX(`Life expectancy`)
FROM worldlifeexpectancy
GROUP BY Country
HAVING MIN(`Life expectancy`) <> 0
AND MAX(`Life expectancy`) <> 0
ORDER BY Country DESC
;


#It would be interesting to look at which countries did good in increasing their life expectancy, by comparing the oldest data to the most recent one
SELECT Country, MIN(`Life expectancy`), MAX(`Life expectancy`)
FROM worldlifeexpectancy
GROUP BY Country
ORDER BY Country 
;

#Let's look at which countries had the best evolution
SELECT Country, MIN(`Life expectancy`), MAX(`Life expectancy`),
ROUND((MAX(`Life expectancy`) - MIN(`Life expectancy`)),2) as Life_Increase_15_Years
FROM worldlifeexpectancy
GROUP BY Country
HAVING  MIN(`Life expectancy`) <> 0
AND  MAX(`Life expectancy`) <> 0
ORDER BY Life_Increase_15_Years DESC
;


#Let's look at the average life expectancy per year, to determine which year was the best:
SELECT Year, ROUND(AVG(`Life expectancy`),2) as life_expectancy_per_year
FROM worldlifeexpectancy
WHERE `Life expectancy`<> 0
GROUP BY Year
ORDER BY Year DESC
;

SELECT *
FROM worldlifeexpectancy
;

#Let's look at the correlations between life expectancy and the other factors
SELECT Country, ROUND(AVG(`Life expectancy`),1) as Life_exp, ROUND(AVG(GDP),1) as GDP
FROM worldlifeexpectancy
GROUP BY Country
HAVING Life_exp <> 0
AND GDP <> 0
ORDER BY GDP ASC
#We notice that the higher the GDP, the higher the life expectancy. 

;

SELECT *
FROM worldlifeexpectancy
;

SELECT 
SUM(
CASE 
WHEN  GDP  >= 1500 THEN 1 ELSE 0
END) High_GDP_Count,

AVG(
CASE 
WHEN  GDP  >= 1500 THEN `Life expectancy` ELSE NULL
END) High_GDP_Life_Expecatncy
FROM worldlifeexpectancy
#The life expectancy of high GDP countries is 74 years
;

SELECT 
SUM(
CASE 
WHEN  GDP  <= 1500 THEN 1 ELSE 0
END) Low_GDP_Count,

AVG(
CASE 
WHEN  GDP  <= 1500 THEN `Life expectancy` ELSE NULL
END) Low_GDP_Life_Expecatncy
FROM worldlifeexpectancy
# The life expectancy of low GDP countries is 64 years
;

#Let's combine both:
SELECT 
SUM(
CASE 
WHEN  GDP  >= 1500 THEN 1 ELSE 0
END) High_GDP_Count,
SUM(
CASE 
WHEN  GDP  <= 1500 THEN 1 ELSE 0
END) Low_GDP_Count,

AVG(
CASE 
WHEN  GDP  >= 1500 THEN `Life expectancy` ELSE NULL
END) High_GDP_Life_Expecatncy,

AVG(
CASE 
WHEN  GDP  <= 1500 THEN `Life expectancy` ELSE NULL
END) Low_GDP_Life_Expecatncy

FROM worldlifeexpectancy
#This highlights the correlation between GDP and life expectancy
;

#We could do this with most of the columns

#Let's look at the average life expectancy for both status
SELECT Status, ROUND(AVG(`Life expectancy`),1)
FROM worldlifeexpectancy
GROUP BY Status
;

SELECT Status, COUNT(DISTINCT Country)
FROM worldlifeexpectancy
GROUP BY Status
#There are way less developed country so it is easier to keep a higher average compared to the other category

;

SELECT Status, COUNT(DISTINCT Country), ROUND(AVG(`Life expectancy`),1)
FROM worldlifeexpectancy
GROUP BY Status

;

SELECT Country, ROUND(AVG(`Life expectancy`),1) as Life_exp, ROUND(AVG(BMI),1) as BMI
FROM worldlifeexpectancy
GROUP BY Country
HAVING Life_exp > 0
AND BMI > 0
ORDER BY BMI DESC
#There's a positive correlation between high BMI and high life expectancy. 
#This is probably due to the fact that countries where the life expectancy is high are richer countries where food's more accessible.
;

#Finally, let's take a look at adult mortality,to see how many people die every year
SELECT Country, Year, `Life expectancy`, `Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY Country ORDER BY Year) as Rolling_total
FROM worldlifeexpectancy


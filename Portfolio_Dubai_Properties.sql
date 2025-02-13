-- CREATE 2 TABLES UAE RENT AND UAE LISTING AGE
-- AND IMPORT THE DATA FROM CSV

--1st TABLE dubai_rent

CREATE TABLE dubai_rent (
num_ID int,
address varchar (150),
rent int,
beds smallint,
baths smallint,
type varchar,
area_in_sqft int,
rent_per_sqft float,
rent_category varchar,
furnishing varchar,
location varchar,
city varchar);

SELECT *
FROM dubai_rent;

-- 2nd TABLE dubai_listing_days

CREATE TABLE dubai_listing_days (
num_ID int,
address varchar (150),
location varchar,
city varchar,
posted_date date,
age_of_listing_in_days int);

SELECT *
FROM dubai_listing_days;

--1. STATISTICAL ANALYSIS OF RENTAL SITUATION IN ALL THE CITIES OF UAE
--OUTLIERS IN RENT: 
--$55,000,000 IS MAX
SELECT rent
FROM public.dubai_rent
ORDER BY rent DESC
LIMIT 5;

--$0-$290 IS MIN
SELECT rent
FROM public.dubai_rent
ORDER BY rent ASC
LIMIT 20;

--OVERALL STATS EXCLUDING OUTLIERS
SELECT MAX(rent) max_rent, MIN(rent) min_rent, ROUND(AVG (rent)) avg_rent, 
       MAX(area_in_sqft) max_area, MIN(area_in_sqft) min_area, ROUND(AVG (area_in_sqft)) avg_area,
	   MAX (beds) max_beds, MIN (beds) min_beds, MAX (baths) max_baths, MIN (baths) min_baths, 
	   COUNT (rent) num_properties
FROM dubai_rent
WHERE rent>290 AND rent<55000000;

--WHAT CITIES ARE THERE ON THE LIST - RESULT: THERE ARE 8 BIGGEST CITIES OF UAE

SELECT DISTINCT(city)
FROM dubai_rent;

--2. ANALYSIS BY CATEGORIES

--WHAT TYPES OF RENTALS ARE MORE AVAILABLE - SHOWS US THAT APARTMENTS ARE LEADING ON THE MARKET

SELECT type, COUNT(type) AS num_rentals
FROM dubai_rent
GROUP BY type
ORDER BY num_rentals DESC;

--SINCE APARTMENTS ARE LEADING WE'LL SWITCH TO THE APARTMENT ANALYSIS ONLY

--3. DISTRIBUTIVE ANALYSIS
--IS THE AVAILABILITY OF APARTMENTS DISTRIBUTED EQUALLY THROUGHOUT THE CITIES OF UAE
--IN COUNTS AND PERCENTAGE

SELECT city, COUNT(type) AS num_apt_rentals, ROUND (COUNT (type)*100.0/
            (SELECT COUNT(type) FROM dubai_rent WHERE type = 'Apartment'),2) AS percentage
FROM dubai_rent
WHERE type = 'Apartment'
GROUP BY city
ORDER BY num_apt_rentals DESC;

--4.FILTER: JUST DUBAI APARTMENTS

SELECT  location, rent, beds, baths, area_in_sqft, rent_category, furnishing
FROM dubai_rent
WHERE city = 'Dubai' AND type ='Apartment';

--NUMBER OF BEDROOMS AVAILABILITY

SELECT beds, COUNT(beds)
FROM dubai_rent
GROUP BY beds
ORDER BY beds;

--FURNISHED/UNFURNISHED RATIO - RESULTS:  45% FURNISHED /54% UNFURNISHED

SELECT furnishing, COUNT(furnishing) AS num_furnishing, ROUND((COUNT(furnishing )*100.0/ 
	(SELECT COUNT(furnishing) FROM dubai_rent WHERE city = 'Dubai' AND type ='Apartment')),2) AS percentage
FROM dubai_rent
WHERE city = 'Dubai' AND type ='Apartment'
GROUP BY furnishing
ORDER BY percentage DESC;

--STATS ON THE AREA (MAX/MIN)

SELECT MAX (area_in_sqft), MIN(area_in_sqft)
FROM dubai_rent
WHERE city='Dubai' AND type ='Apartment';

--DISTRIBUTION OF DIFFERENT SIZES OF THE AREA BY AVERAGE RENT

SELECT 
    CASE
	WHEN area_in_sqft >1000 THEN 'big'
	WHEN area_in_sqft >500  THEN 'medium'
	ELSE 'small'
	END AS area_size, COUNT (*) AS count_areas_by_size,  ROUND(AVG(area_in_sqft)) avg_area_size, ROUND(AVG(rent)) avg_rent
FROM dubai_rent
WHERE city='Dubai' AND type ='Apartment'
GROUP BY area_size
ORDER BY area_size DESC;

--LOCATION BY PROFIT AND BY COUNT, MIN, MAX - RESULTS: DOWNTOWN DUBAI LOCATION IS THE MOST WANTED DESTINATION

SELECT location, SUM(rent) AS sum_rent,COUNT(rent) AS num_rentals, MAX (rent) AS max_rent, MIN (rent) AS min_rent
FROM dubai_rent
WHERE city = 'Dubai' AND type ='Apartment' AND rent >1000
GROUP BY location
ORDER BY sum_rent DESC;

--RENT OVER TIME ANALYSIS
--THE TABLE OF DUBAI_LISTING SUMMERIZING WHAT CITY IN UAE HAS THE MOST AGED LISTINGS - RESULTS: DUBAI

SELECT city, COUNT(age_of_listing_in_days) AS num_days_listed
FROM dubai_listing_days
GROUP BY city
ORDER BY num_days_listed DESC;

--CORRELATION OF THE AGE OF LISTING AND PRICE - SHOWS THAT AVG TIME FOR ANY PROPERTY TO BE RENTED IS ABOUT 70 DAYS 

SELECT ROUND(AVG(dr.rent)) avg_rent,  ROUND(AVG(dl.age_of_listing_in_days)) avg_listing, dr.rent_category FROM dubai_rent dr
LEFT JOIN dubai_listing_days dl
ON dr.num_id=dl.num_id
GROUP BY rent_category
ORDER BY avg_listing;

--AMOUNT OF LISTINGS BY MONTHS 
--INSIGHT: MONTHS IN DEMAND ARE NOVEMBER THROUGH APRIL (DUE TO COLD WEATHER IN NORTHERN COUNTRIES)

SELECT  EXTRACT (month FROM posted_date) months, COUNT (posted_date) count_of_listings
FROM dubai_listing_days 
GROUP BY months
ORDER BY count_of_listings DESC;

--THE LOWEST PRICE FOR RENT IS IN MAY AND JUNE

SELECT  EXTRACT (MONTH FROM dl.posted_date) months, 
        ROUND(AVG(dr.rent)) avg_rent, COUNT (dl.posted_date) num_rentals
FROM dubai_listing_days dl
LEFT JOIN dubai_rent dr
ON dl.num_id=dr.num_id
WHERE EXTRACT (YEAR FROM dl.posted_date) >= 2023 AND dr.city = 'Dubai' AND dr.type ='Apartment'
GROUP BY months
ORDER BY avg_rent;

--RENT BY YEAR/MONTH/DAY

SELECT EXTRACT (YEAR FROM dl.posted_date) AS year, EXTRACT (MONTH FROM dl.posted_date) AS month, 
       EXTRACT (DAY FROM dl.posted_date)AS day, dr.rent
FROM dubai_listing_days dl
LEFT JOIN dubai_rent dr
ON dl.num_ID=dr.num_ID
WHERE dr.rent>290 AND dr.rent<55000000
ORDER BY dr.rent DESC;

--INNER JOIN OF BOTH TABLES WITH THE FILTER DUBAI AND APARTMENTS ONLY

SELECT dr.location, dr.address,dr.rent, dr.beds, dr.baths, dr.area_in_sqft, 
       dr.rent_category, dr. furnishing, dl.posted_date, dl.age_of_listing_in_days FROM dubai_rent AS dr
INNER JOIN dubai_listing_days AS dl
ON dr.num_id=dl.num_id
WHERE dr.city = 'Dubai' AND dr.type ='Apartment';

--THE RANGE OF YEARS

SELECT DISTINCT(EXTRACT(YEAR FROM posted_date)) AS years
FROM dubai_listing_days
ORDER BY years;

--LET'S FIND THE PROPERTIES NOT BEING RENTED FOR A LONG TIME

SELECT dr.location, dr.age_of_listing_in_days AS age_list, dr.rent_category
FROM (SELECT dr.location, dr.address,dr.rent, dr.beds, dr.baths, dr.area_in_sqft, 
       dr.rent_category, dr.furnishing, dl.posted_date, dl.age_of_listing_in_days,dr.city, dr.type FROM dubai_rent AS dr
INNER JOIN dubai_listing_days AS dl
ON dr.num_id=dl.num_id) AS dr
WHERE dr.city = 'Dubai' AND dr.type ='Apartment'
ORDER BY age_list DESC;

--EYE CATCHING INSIGHT ON THE INTERNATIONAL CITY AGE LISTING IN A LOW RENT_CATEGORY. 
--12 LOCATIONS OF INTERNATIONAL CITY PROPERTIES HAVE LISTINGS OF MORE THEN 800 DAYS.

--ASSEMBLED TABLE TO WORK IN TABLEAU


SELECT dr.city,
       dr.location, 
       dr.address,
	   dr.type, 
	   dr.beds, 
	   dr.baths,
	   dr.rent,
	   dr.area_in_sqft, 
       dr.rent_category, 
	   dr.furnishing,
	   dl.age_of_listing_in_days,
	   dl.posted_date
FROM dubai_rent AS dr
INNER JOIN dubai_listing_days AS dl
ON dr.num_id=dl.num_id;

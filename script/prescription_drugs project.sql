--1. 
--a. Which prescriber had the highest total number of claims (totaled over all drugs)?  Report the npi and the total number of claims.
SELECT npi,sum(total_claim_count)as total_claims
FROM prescription
	LEFT JOIN prescriber
	USING(npi)
GROUP BY prescriber,npi
ORDER BY total_claims DESC;
---1 1881634483
  
-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT nppes_provider_first_name,nppes_provider_last_org_name,specialty_description,SUM(total_claim_count) AS total_claims
FROM prescription
	LEFT JOIN prescriber
	USING(npi)
GROUP BY nppes_provider_first_name,nppes_provider_last_org_name,specialty_description
ORDER BY total_claims DESC;   
----BRUCE PENDLEY
--2. 
--a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description,SUM(total_claim_count) AS total_claims
FROM prescription
	LEFT JOIN prescriber
	using(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;
-----family practice 
--b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description,opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescription
	LEFT JOIN prescriber
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY opioid_drug_flag, specialty_description 
ORDER BY total_claims DESC;

----nurse practitioner

--c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
          ---I use full join to get all possible null values.
SELECT npi,specialty_description
FROM prescription
	FULL JOIN prescriber
	USING(npi)
WHERE specialty_description is null 
ORDER BY total_claim_count;

------NO

---d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

---- to calculate percentage of total_claim count for each speciallity, I use opioid_prescriber_rate = (opioid_claim/total_all_claim)*100

SELECT specialty_description,npi,SUM(total_claim_count) AS opioid_claim_count
FROM prescription
	INNER JOIN prescriber
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
WHERE opioid_drug_flag ='Y'
GROUP BY specialty_description,npi;


WITH opioid_claim AS (SELECT specialty_description,npi,SUM(total_claim_count) AS opioid_claim_count
					  FROM prescription
					  	INNER JOIN prescriber
					  	USING(npi)
                      	INNER JOIN drug
                      	USING (drug_name)
                      WHERE opioid_drug_flag ='Y'
                      GROUP BY specialty_description,npi)
					  
SELECT specialty_description,opioid_claim_count,sum(total_claim_count)AS total_all_claim,ROUND((opioid_claim_count/(sum(total_claim_count)))*100) AS opioid_prescriber_rate
FROM prescription
	INNER JOIN opioid_claim
	USING(npi)
group by specialty_description,opioid_claim_count
order by opioid_prescriber_rate DESC;

--3. 
-- a. Which drug (generic_name) had the highest total drug cost?

SELECT prescription.drug_name,generic_name,total_drug_cost
FROM prescription
	LEFT JOIN drug
	ON prescription.drug_name = drug.drug_name
ORDER BY total_drug_cost DESC;

---ESBRIET 

--b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT prescription.drug_name,generic_name,total_drug_cost, ROUND((total_drug_cost/30),2) AS total_cost_perday
FROM prescription
	LEFT JOIN drug
	ON prescription.drug_name = drug.drug_name
GROUP BY prescription.drug_name, generic_name,total_drug_cost
ORDER BY total_cost_perday DESC;


--4. 
-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.


SELECT drug_name,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag ='Y'THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug;


--b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_name, total_drug_cost,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			WHEN antibiotic_drug_flag ='Y'THEN 'antibiotic'
			ELSE 'neither' END AS drug_type
FROM drug
	INNER JOIN prescription
	USING(drug_name)
WHERE drug_type = 'opioid'
	OR drug_type ='antibiotic'
ORDER By total_drug_cost desc;


--5. 
-- a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT count(cbsaname)
FROM cbsa
WHERE cbsaname ilike '%TN%';
---58
-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, sum(population) as total_pop
FROM population
	LEFT JOIN fips_county
	USING (fipscounty)
	LEFT JOIN cbsa
	USING(fipscounty)
GROUP BY cbsaname
ORDER BY total_pop DESC;

---Largest   Nashville-Davidson-Murfreesboro-Franklin,TN
---Smallest   MORRISTOWN,TN

--c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population
FROM population
	INNER JOIN fips_county
	USING (fipscounty)
ORDER BY population DESC;

---SHELBY 937847

--6. 
-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name,total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name,total_claim_count,opioid_drug_flag
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
WHERE total_claim_count >= 3000;

--c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug_name,total_claim_count,opioid_drug_flag,nppes_provider_last_org_name as last_name,nppes_provider_first_name as first_name
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
LEFT JOIN prescriber
USING(npi)
WHERE total_claim_count >= 3000;


---7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows
--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
	CROSS JOIN drug
WHERE nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	AND specialty_description = 'Pain Management';

--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
  

WITH PM AS(SELECT npi,drug_name
			FROM prescriber
				CROSS JOIN drug
			WHERE nppes_provider_city = 'NASHVILLE'
				AND opioid_drug_flag = 'Y'
				AND specialty_description = 'Pain Management')
	
SELECT PM.npi, PM.drug_name, total_claim_count
FROM prescription
	CROSS JOIN PM;

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT PM.npi, PM.drug_name, 
							COALESCE(total_claim_count,0)AS total_claim_count_name
FROM prescription
	CROSS JOIN PM;

--------------------------------------------------------------------------------------------
    ---- BONUS------
--1.How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT npi
FROM prescriber
EXCEPT
SELECT npi 
FROM prescription;
      
	  SELECT COUNT (npi) AS npi_count
      FROM (SELECT npi
            FROM prescriber
            EXCEPT
            SELECT npi 
            FROM prescription) AS npi_prescriber;
---4458
      
--2.
--- a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name,specialty_description,count(generic_name) as gn
FROM drug
  	LEFT JOIN prescription
	ON drug.drug_name =prescription.drug_name
	INNER JOIN prescriber
	USING(npi)
WHERE specialty_description ='Family Practice' 
GROUP BY generic_name,specialty_description
ORDER BY gn DESC
LIMIT 5;
 -----METFORMIN HCL
-- b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name,specialty_description,count(generic_name) as gn
FROM drug
	LEFT JOIN prescription
	ON drug.drug_name =prescription.drug_name
	INNER JOIN prescriber
	USING(npi)
WHERE specialty_description ='Cardiology' 
GROUP BY generic_name,specialty_description
ORDER BY gn DESC
LIMIT 5;

-- c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
 
 --(part a) union (part b)
SELECT *
FROM
	(SELECT generic_name,specialty_description,count(generic_name) as gn
	FROM drug
		LEFT JOIN prescription
		ON drug.drug_name =prescription.drug_name
		INNER JOIN prescriber
		USING(npi)
	WHERE specialty_description ='Family Practice' 
	GROUP BY generic_name,specialty_description
	ORDER BY gn DESC
	LIMIT 5)AS a
UNION 
SELECT *
FROM
	(SELECT generic_name,specialty_description,count(generic_name) as gn
	FROM drug
		LEFT JOIN prescription
		ON drug.drug_name =prescription.drug_name
		INNER JOIN prescriber
		USING(npi)
	WHERE specialty_description ='Family Practice' 
	GROUP BY generic_name,specialty_description
	ORDER BY gn DESC
	LIMIT 5)AS b
ORDER by gn DESC
LIMIT 5;
 
   --- METFORMIN HCN
 
--3.  Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
  --  a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    
SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city='NASHVILLE' 
 	AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5;


--b. Now, report the same for Memphis.-
SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city='MEMPHIS'
  AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5;	

--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city='KNOXVILLE' 
   AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5;

SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city= 'CHATTANOOGA'
   AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5;
	--combine a,b,C and D by union
	--a union b union c union d
	
(SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city='NASHVILLE'
 AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5)
UNION 	
(SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city='MEMPHIS'
  AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5)
UNION 
(SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city='KNOXVILLE' 
   AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5)
UNION 
(SELECT npi,nppes_provider_city,total_claim_count
FROM prescriber
	LEFT JOIN prescription
	USING(npi)
WHERE nppes_provider_city= 'CHATTANOOGA'
   AND total_claim_count IS NOT null
ORDER BY total_claim_count DESC 
LIMIT 5);
		
--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths	

SELECT county,count(cast(overdose_deaths as integer))AS total_overdose_deaths 
FROM (fips_county :: integer) 
	INNER JOIN overdose_deaths
	USING (fipscounty)
WHERE count(overdose_deaths) >(SELECT avg(overdose_deaths)
                               FROM overdose_deaths)
GROUP BY county;


---a. Write a query that finds the total population of Tennessee.
SELECT state,sum(population.population)
FROM population
	left JOIN fips_county
	USING(fipscounty)
WHERE state='TN'
group by state;	  
	   
---b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
(SELECT SUM(population.polulation)
FROM population
	INNER JOIN fips_county
	USING(fipscounty)
WHERE state='TN') AS total_pop_tn

SELECT county,population,(population/total_pop_tn)*100 as percentage_from_total_pop      
FROM population
	INNER JOIN fips_county
    USING(fipscounty)
GROUP BY population,county;
		  


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	









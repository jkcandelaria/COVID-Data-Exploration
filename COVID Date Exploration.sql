-- COVID DATA EXPLORATION

-- COMMON COLUMNS TO BE USED

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_portfolio..covid_deaths
ORDER BY 1,2

-- Total Cases vs Total Deaths or Death Percentage per case

SELECT location, date, total_cases, new_cases, total_deaths, population,
	   (total_deaths / total_cases)*100 AS death_percentage

FROM covid_portfolio..covid_deaths
ORDER BY 1,2

-- Percent of the population infected with COVID

SELECT location, date, total_cases, new_cases, total_deaths, population,
	   (total_cases/population)*100 AS percent_infected
FROM covid_portfolio..covid_deaths
ORDER BY 1,2

-- Top 50 Countries with the Highest Infection Rate

SELECT location, population, MAX(total_cases) as max_total_cases,
	   (MAX(total_cases/population))*100 AS percent_total_cases
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY location, population
ORDER BY percent_total_cases desc
OFFSET 0 ROWS
FETCH FIRST 50 ROWS ONLY

-- DEATH PERCENTAGE PER POPOULATION

SELECT location, population, MAX(cast(total_deaths as int)) as max_total_deaths,
	   (MAX(cast(total_deaths as int)/population))*100 AS percent_total_deaths
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY location, population
ORDER BY percent_total_deaths desc



--DEATH PERCENTAGE BY CONTINENT

SELECT continent, MAX(cast(total_deaths as int)) as total_deaths
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY continent
ORDER BY total_deaths desc;

-- CASES BY CONTINENT

SELECT continent, MAX(total_cases) as total_cases
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY continent
ORDER BY total_cases desc;

--Worldwide COVID Data

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM covid_portfolio..covid_deaths
WHERE continent is not null 

-- WITH COVID VACCINATION

-- Rolling Count of Population Vaccinated

SELECT deaths.location, deaths.date, vax.new_vaccinations, 
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_count

FROM covid_portfolio..covid_deaths deaths
JOIN covid_portfolio..covid_vaccinations vax
ON deaths.location = vax.location and
deaths.date = vax.date
WHERE deaths.continent is not null
ORDER BY 1,2

-- USING CTE TABLE (Percent of the population that received at least one vaccination)

WITH rolling_vaccine_count
AS
(
SELECT deaths.location, deaths.date, deaths.population, vax.new_vaccinations, 
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_count

FROM covid_portfolio..covid_deaths deaths
JOIN covid_portfolio..covid_vaccinations vax
ON deaths.location = vax.location and
deaths.date = vax.date
WHERE deaths.continent is not null
)

SELECT location, MAX(rolling_count) AS max_vaccinations, (MAX(rolling_count)/MAX(population))*100 as vaccination_percentage
FROM rolling_vaccine_count
GROUP BY location
ORDER BY vaccination_percentage desc

--USING TEMP TABLE to achieve the same as previous query
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_count numeric
 )
 INSERT INTO PercentPopulationVaccinated

SELECT deaths.location, deaths.date, deaths.population, vax.new_vaccinations, 
SUM(cast(vax.new_vaccinations as int)) OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS rolling_count

FROM covid_portfolio..covid_deaths deaths
JOIN covid_portfolio..covid_vaccinations vax
ON deaths.location = vax.location and
deaths.date = vax.date
WHERE deaths.continent is not null and vax.new_vaccinations is not null


SELECT location, population, MAX(rolling_count/population)*100 AS vaccination_percentage
FROM PercentPopulationVaccinated
GROUP BY location, population
ORDER BY vaccination_percentage desc


--CREATING VIEWS FOR LATER VISUALIZATION

CREATE VIEW percent_population_infected as
SELECT location, date, total_cases, new_cases, total_deaths, population,
	   (total_cases/population)*100 AS percent_infected
FROM covid_portfolio..covid_deaths;


CREATE VIEW highest_infection_rate as
SELECT location, population, MAX(total_cases) as max_total_cases,
	   (MAX(total_cases/population))*100 AS percent_total_cases
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY location, population
ORDER BY percent_total_cases desc
OFFSET 0 ROWS
FETCH FIRST 50 ROWS ONLY;

CREATE VIEW death_rate_per_case as
SELECT location, date, total_cases, new_cases, total_deaths, population,
	   (total_deaths / total_cases)*100 AS death_percentage
FROM covid_portfolio..covid_deaths;


CREATE VIEW death_count_by_continent as
SELECT continent, MAX(cast(total_deaths as int)) as total_deaths
FROM covid_portfolio..covid_deaths
WHERE continent is not null ;


CREATE VIEW cases_per_continent as
SELECT continent, MAX(total_cases) as total_cases
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY continent;


CREATE VIEW global_covid_data as
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage
FROM covid_portfolio..covid_deaths
WHERE continent is not null ;


CREATE VIEW percent_population_vaccinated as
SELECT location, population, MAX(rolling_count/population)*100 AS vaccination_percentage
FROM PercentPopulationVaccinated
GROUP BY location, population;

CREATE VIEW death_percentage_by_country as
SELECT location, population, MAX(cast(total_deaths as int)) as max_total_deaths,
	   (MAX(cast(total_deaths as int)/population))*100 AS percent_total_deaths
FROM covid_portfolio..covid_deaths
WHERE continent is not null 
GROUP BY location, population;
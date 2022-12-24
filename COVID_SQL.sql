SELECT *
FROM Project..CovidDeaths
WHERE continent is not null
Order by 3,4

SELECT *
FROM Project..CovidVaccinations
Order by 3,4

-- Selecting the Data

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathsPercentage
FROM Project..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2 

-- Total Cases vs Population
-- Percentage of Population Infected by Covid

SELECT Location, date, Population, total_cases, 
		(total_cases/population)*100 AS Infected_Percentage
FROM Project..CovidDeaths
WHERE location = 'India'
ORDER BY 1,2 

-- Highest Infection Rate of the countries

SELECT Location, Population, MAX(total_cases) AS Highest_Infection_Count,
		ROUND(MAX(total_cases/population)*100, 2) AS Highest_Infected_Percentage
FROM Project..CovidDeaths
--WHERE location = 'India'
GROUP BY location, population
ORDER BY Highest_Infected_Percentage DESC

-- Total Death Count of the Countries
SELECT Location, MAX(CAST(Total_Deaths AS INT)) AS Total_Death_Count
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY Total_Death_Count DESC

-- Total Death Count of the Continents

SELECT continent, MAX(CAST(Total_Deaths AS INT)) AS Total_Death_Count
FROM Project..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY Total_Death_Count DESC

-- Global Scenario

SELECT 
	--date,
	SUM(new_cases) AS Global_Total_Cases , 
	SUM(CAST(new_deaths AS INT))  AS Global_Total_Deaths,
	(SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS Death_Percentage
FROM Project..CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 3

-- Total Population vs Vaccinations

SELECT
	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(INT, cv.new_vaccinations))
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
FROM Project..CovidDeaths cd
JOIN Project..CovidVaccinations cv
	ON cd.location = cv.location 
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE

WITH PplnVsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVacciated)
as
(
	SELECT
	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(INT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
	FROM Project..CovidDeaths cd
	JOIN Project..CovidVaccinations cv
		ON cd.location = cv.location 
		AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL
	-- ORDER BY 2,3
)
SELECT *, (RollingPeopleVacciated/Population)*100
FROM [PplnVsVac]

-- Ctreating a TEMP Table

DROP TABLE if EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
	Continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT
	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(INT, cv.new_vaccinations)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
	FROM Project..CovidDeaths cd
	JOIN Project..CovidVaccinations cv
		ON cd.location = cv.location 
		AND cd.date = cv.date
	-- WHERE cd.continent IS NOT NULL
	-- ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PercentPopulationVaccinated

-- Creating VIEW to store data for Viz

CREATE VIEW V_PercentPopulationVaccinated as
SELECT
	cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CONVERT(INT, cv.new_vaccinations)) 
	OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingPeopleVaccinated
	FROM Project..CovidDeaths cd
	JOIN Project..CovidVaccinations cv
		ON cd.location = cv.location 
		AND cd.date = cv.date
	WHERE cd.continent IS NOT NULL

SELECT *
FROM V_PercentPopulationVaccinated
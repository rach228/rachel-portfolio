SELECT *
FROM covid.coviddeaths1
WHERE ORD(continent) > 0
ORDER BY 3, 4;

SELECT *
FROM covid.covidvaccinations1
WHERE ORD(continent) > 0
ORDER BY 3, 4;

-- Adjust date column for coviddeaths1 table
SELECT date, STR_TO_DATE(date, '%d/%m/%y') AS date1
FROM covid.coviddeaths1
ORDER BY date1;

ALTER TABLE covid.coviddeaths1
ADD COLUMN date1 DATETIME AFTER date;

UPDATE covid.coviddeaths1
SET date1 = STR_TO_DATE(date, '%d/%m/%y');

ALTER TABLE covid.coviddeaths1
DROP date;

-- Adjust date column for covidvaccinations1 table
SELECT date, STR_TO_DATE(date, '%d/%m/%y') AS date1
FROM covid.covidvaccinations1
ORDER BY date1;

ALTER TABLE covid.covidvaccinations1
ADD COLUMN date1 DATETIME AFTER date;

UPDATE covid.covidvaccinations1
SET date1 = STR_TO_DATE(date, '%d/%m/%y');

ALTER TABLE covid.covidvaccinations1
DROP date;

-- Select data to use
SELECT location, date1, total_cases, new_cases, total_deaths, population
FROM covid.coviddeaths1
WHERE ORD(continent) > 0
ORDER BY 1, 2;

-- Looking at % of Total Deaths on Total Cases or Likelihood of dying from covid
SELECT location, date1, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid.coviddeaths1
WHERE location LIKE '%singapore%'
AND ORD(continent) > 0
ORDER BY 1, 2;

-- Looking at % of Population contracting covid
SELECT location, date1, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM covid.coviddeaths1
WHERE location LIKE '%states%'
ORDER BY 1, 2;

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing Countries with the Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
WHERE ORD(continent) > 0
GROUP BY location
ORDER BY TotalDeathCount DESC;



-- Breaking down by Continent

-- Showing Continents with the Highest Death Count per Population
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
WHERE ORD(continent) > 0
-- WHERE continent = ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
WHERE ORD(continent) > 0
-- GROUP BY date1
ORDER BY 1, 2;

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least 1 Covid Vaccine
SELECT dea.continent, dea.location, dea.date1, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date1) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM covid.coviddeaths1 dea
JOIN covid.covidvaccinations1 vac
	ON dea.location = vac.location
    AND dea.date1 = vac.date1
WHERE ORD(dea.continent) > 0
ORDER BY 2, 3;

-- Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (continent, location, date1, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date1, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date1) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM covid.coviddeaths1 dea
JOIN covid.covidvaccinations1 vac
	ON dea.location = vac.location
    AND dea.date1 = vac.date1
WHERE ORD(dea.continent) > 0
-- ORDER BY 2, 3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS covid.PopvsVac2;

CREATE TABLE covid.PopvsVac2 (
	continent VARCHAR(255),
	location VARCHAR(255),
	date1 DATETIME,
	population INT,
	new_vaccinations INT,
	RollingPeopleVaccinated INT
);


SET sql_mode = '';

INSERT INTO covid.PopvsVac2
SELECT dea.continent, dea.location, dea.date1, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date1) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM covid.coviddeaths1 dea
JOIN covid.covidvaccinations1 vac
	ON dea.location = vac.location
    AND dea.date1 = vac.date1;
-- WHERE ORD(dea.continent) > 0
-- ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM covid.PopvsVac2;



-- Creating Views to store data for later visualizations

CREATE VIEW covid.PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date1, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, UNSIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date1) AS RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
FROM covid.coviddeaths1 dea
JOIN covid.covidvaccinations1 vac
	ON dea.location = vac.location
    AND dea.date1 = vac.date1
WHERE ORD(dea.continent) > 0;
-- ORDER BY 2, 3


-- 1.
-- Global Numbers
CREATE VIEW covid.GlobalNumbers AS
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
WHERE ORD(continent) > 0
-- GROUP BY date1
ORDER BY 1, 2;

-- 2.
-- Showing Total Death Count by Continent
CREATE VIEW covid.TotalDeathCount AS
SELECT continent, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeathCount
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
WHERE ORD(continent) > 0
-- WHERE continent = ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 3.
-- Looking at Countries with Highest Infection Rate compared to Population
CREATE VIEW covid.HighestInfectionRate AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- 4.
CREATE VIEW covid.HighestInfectionRateByDate AS
SELECT location, population, date1, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM covid.coviddeaths1
-- WHERE location LIKE '%states%'
GROUP BY location, population, date1
ORDER BY PercentPopulationInfected DESC;



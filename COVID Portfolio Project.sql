-- Select data that will be used

SELECT location, date, total_cases, new_cases, total_deaths, population
	FROM Covidproject.coviddeaths
	ORDER BY 1,2;

SELECT location, date, total_tests, new_tests, total_vaccinations, new_vaccinations
	FROM Covidproject.covidvaccinations
	ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths (Shows likelihood of dying if contracted in your Country) 

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	ORDER BY 1,2;

-- Total Cases vs Population (Shows percent of population that got COVID)

SELECT location, date, total_cases, population, (total_cases/population)*100 as PrecentPopulationInfected
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PrecentPopulationInfected
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY location, population
	ORDER BY PrecentPopulationInfected DESC;

-- Showing Countries with the Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY location
	ORDER BY TotalDeathCount DESC;

-- Showing the Continent with Highest Death Count

SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
	FROM Covidproject.coviddeaths
	WHERE continent is NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%World%'
	GROUP BY location
	ORDER BY TotalDeathCount DESC;

-- Total Cases, Deaths and Death Precentage (By Date)

SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeaths, 
	SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY date
	ORDER BY date;

-- Total Cases, Deaths and Death Precentage (By Country and Date)

SELECT location, date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeaths, 
	SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
    GROUP BY location, date
	ORDER BY 1,2;
    
-- Total Cases, Deaths and Death Precentage (Overall)

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeaths, 
	SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	ORDER BY 1,2;

-- Joining Deaths and Vaccinations Tables

SELECT *
	FROM Covidproject.coviddeaths AS death
	JOIN Covidproject.covidvaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date;
    
-- Total Population vs Vaccinations

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
	SUM(CAST(vaccine.new_vaccinations AS UNSIGNED)) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinated
	FROM Covidproject.coviddeaths AS death
	JOIN Covidproject.covidvaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date
	WHERE death.continent is NOT NULL
	ORDER BY 2,3;
    
-- Rolling Vaccinated Precentage of Countries Using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingVaccinated) AS 
(
	SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
		SUM(CAST(vaccine.new_vaccinations AS UNSIGNED)) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinated
	FROM Covidproject.coviddeaths AS death
	JOIN Covidproject.covidvaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date
	WHERE death.continent IS NOT NULL
)
SELECT *, (RollingVaccinated/population)*100 AS VaccinationPercentage
	FROM PopvsVac
	ORDER BY 2,3;

-- Rolling Vaccinated Precentage of Countries Using TEMP Table

DROP TABLE IF EXISTS PrecentPopulationVaccinated
;
CREATE TEMPORARY TABLE PrecentPopulationVaccinated
(
continent TEXT,
location TEXT,
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingVaccinated NUMERIC
);
INSERT INTO PrecentPopulationVaccinated
	SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
		SUM(CAST(vaccine.new_vaccinations AS UNSIGNED)) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinated
	FROM Covidproject.coviddeaths AS death
	JOIN Covidproject.covidvaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date
	WHERE death.continent IS NOT NULL;

SELECT *, (RollingVaccinated/population)*100 AS VaccinationPercentage
	FROM PrecentPopulationVaccinated
	ORDER BY 2,3;



-- Creating Views to store for later Visualations

-- Total Cases vs Total Deaths (Shows likelihood of dying if contracted in your Country) 

CREATE VIEW CasesvsDeaths AS
	SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	ORDER BY 1,2;

 -- Total Cases vs Population (Shows percent of population that got COVID)

CREATE VIEW PopulationvsCases AS
	SELECT location, date, total_cases, population, (total_cases/population)*100 as PrecentPopulationInfected
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population

CREATE VIEW InfectionRate AS 
	SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PrecentPopulationInfected
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY location, population
	ORDER BY PrecentPopulationInfected DESC;

-- Showing Countries with the Highest Death Count per Population

CREATE VIEW HighestDeathperCountry AS
	SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY location
	ORDER BY TotalDeathCount DESC;

-- Showing the Continent with Highest Death Count

CREATE VIEW HighestDeathperContinent AS
	SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
	FROM Covidproject.coviddeaths
	WHERE continent is NULL AND location NOT LIKE '%income%' AND location NOT LIKE '%World%'
	GROUP BY location
	ORDER BY TotalDeathCount DESC;

-- Total Cases, Deaths and Death Precentage Grouped by Date

CREATE VIEW TotalsbyDate AS
	SELECT date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeaths, 
		SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY date
	ORDER BY date;

-- Total Cases, Deaths and Death Precentage 

CREATE VIEW TotalsbyCountry AS
	SELECT location, date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeaths, 
		SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	GROUP BY location, date
	ORDER BY 1,2;
    
-- Total Cases, Deaths and Death Precentage 

CREATE VIEW TotalsbyContinent AS
	SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS UNSIGNED)) AS TotalDeaths, 
		SUM(CAST(new_deaths AS UNSIGNED))/SUM(new_cases)*100 AS DeathPercentage
	FROM Covidproject.coviddeaths
	WHERE continent is NOT NULL
	ORDER BY 1,2;

-- Rolling Vaccinated Precentage of Countries

CREATE VIEW PrecentPopulationVaccinated AS
	SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
		SUM(CAST(vaccine.new_vaccinations AS UNSIGNED)) 
		OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingVaccinated
	FROM Covidproject.coviddeaths AS death
	JOIN Covidproject.covidvaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date
	WHERE death.continent IS NOT NULL;

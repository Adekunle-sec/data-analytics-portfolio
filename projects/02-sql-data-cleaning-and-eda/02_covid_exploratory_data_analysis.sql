/*
================================================================================
SCRIPT 2: ADVANCED SQL EXPLORATORY DATA ANALYSIS (EDA)
Database: Microsoft SQL Server / T-SQL (Compatible with PostgreSQL / MySQL)
Dataset: Global Health & Epidemiological Telemetry
Author: Portfolio Project (AlexTheAnalyst Standard)
Skills Used: Joins, CTEs, Temp Tables, Window Functions, Aggregate Functions,
             Creating Views, Converting Data Types
================================================================================
*/

-- 1. Baseline Data Inspection
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- 2. Total Cases vs Total Deaths (Calculating Case Fatality Likelihood)
-- Shows likelihood of dying if you contract disease in your country
SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    ROUND((total_deaths * 1.0 / NULLIF(total_cases, 0)) * 100, 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Nigeria%' OR location LIKE '%States%'
  AND continent IS NOT NULL
ORDER BY 1, 2;


-- 3. Total Cases vs Population (Infection Rate Analysis)
-- Shows what percentage of population infected with disease
SELECT 
    Location, 
    date, 
    Population, 
    total_cases, 
    ROUND((total_cases * 1.0 / NULLIF(Population, 0)) * 100, 4) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;


-- 4. Countries with Highest Infection Rate compared to Population
SELECT 
    Location, 
    Population, 
    MAX(total_cases) AS HighestInfectionCount,  
    ROUND(MAX((total_cases * 1.0 / NULLIF(Population, 0))) * 100, 2) AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;


-- 5. Countries with Highest Death Count per Population
SELECT 
    Location, 
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- 6. Breakdown by Continent (Highest Death Counts)
SELECT 
    continent, 
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- 7. Global Aggregated Numbers across Time
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    ROUND(SUM(CAST(new_deaths AS INT)) * 100.0 / NULLIF(SUM(New_Cases), 0), 2) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- 8. Advanced Rolling People Vaccinated using CTE & Window Functions
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
            PARTITION BY dea.Location 
            ORDER BY dea.location, dea.Date
        ) AS RollingPeopleVaccinated
    FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *, 
    ROUND((RollingPeopleVaccinated * 1.0 / NULLIF(Population, 0)) * 100, 4) AS VaccinationPercentage
FROM PopvsVac
ORDER BY Location, Date;


-- 9. Using Temporary Table to Perform Advanced Analytical Aggregations
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.Location 
        ORDER BY dea.location, dea.Date
    ) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT 
    *, 
    ROUND((RollingPeopleVaccinated * 1.0 / NULLIF(Population, 0)) * 100, 4) AS PercentVaccinated
FROM #PercentPopulationVaccinated;


-- 10. Creating Production View to Store Data for Power BI / Tableau Visualization
CREATE OR ALTER VIEW PercentPopulationVaccinatedView AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (
        PARTITION BY dea.Location 
        ORDER BY dea.location, dea.Date
    ) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

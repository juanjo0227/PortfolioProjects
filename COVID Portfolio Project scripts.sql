select * from
PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
order by 3, 4

--select * from
--PortfolioProject..CovidVaccinations
--order by 3, 4

--select data that we are going to be using

--select Location, date, total_cases, new_cases, total_deaths, population
--from
--PortfolioProject..CovidDeaths
--order by 1, 2

-- Paso 1: Actualiza los datos a un formato compatible (opcional si ya tienes las fechas en formato válido)
--UPDATE PortfolioProject..CovidDeaths
--SET date = CONVERT(varchar, 
--            CASE 
--                WHEN LEN(date) = 8 THEN '20' + RIGHT(date, 2) + '-' + SUBSTRING(date, 4, 2) + '-' + LEFT(date, 2)
--                ELSE date
--            END, 
--            120);

---- Paso 2: Cambia el tipo de la columna a datetime
--ALTER TABLE PortfolioProject..CovidDeaths
--ALTER COLUMN date datetime;


--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, 
    CASE 
        WHEN total_cases = 0 THEN 0 
        ELSE (total_deaths * 1.0 / total_cases) * 100
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Colombia' AND continent IS NOT NULL
ORDER BY 1, 2;


--Looking at Total Cases vs Population
--Shows what percentage of population got covid

SELECT Location, date, Population, total_cases, (total_cases * 1.0 / Population) * 100 AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'United States' and continent IS NOT NULL
ORDER BY 2;


--Looking at countries with highest infection rate compared to population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, 
	CASE 
        WHEN population = 0 THEN 0
        ELSE MAX((total_cases * 1.0 / population)) * 100
    END AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
where continent IS NOT NULL
Group by Location, Population
ORDER BY PercentPopulationInfected desc;


--Showing countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent IS NOT NULL
Group by Location
ORDER BY TotalDeathCount desc;


--Let's break things down by continent


-- Showing continents with highest death count per population

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent IS NOT NULL
Group by continent
ORDER BY TotalDeathCount desc;



--GLOBAL NUMBERS


SELECT SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	CASE 
        WHEN SUM(cast(new_cases as int)) = 0 THEN 0 
        ELSE (SUM(cast(new_deaths as int)) * 1.0 / SUM(cast(new_cases as int))) * 100
    END AS DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent IS NOT NULL
--group by date
ORDER BY 1,2


-- Looking at Total Population vs Vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND ISDATE(dea.date) = 1
AND ISDATE(vac.date) = 1
AND CAST(dea.date AS datetime) = CAST(vac.date AS datetime)
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- Looking at Total Population vs Vaccinations (USE CTE)


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) 
as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
AND ISDATE(dea.date) = 1
AND ISDATE(vac.date) = 1
AND CAST(dea.date AS datetime) = CAST(vac.date AS datetime)
WHERE dea.continent IS NOT NULL
)
Select *, (CAST(RollingPeopleVaccinated AS decimal(18,2)) / CAST(Population AS decimal(18,2)))*100 as PeopleVaccinatedPercentage
from PopvsVac

-- Looking at Total Population vs Vaccinations (Using Temp Table)

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, CONVERT(bigint,vac.new_vaccinations),
SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) 
as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
AND ISDATE(dea.date) = 1
AND ISDATE(vac.date) = 1
AND CAST(dea.date AS datetime) = CAST(vac.date AS datetime)
--WHERE dea.continent IS NOT NULL

Select *, (CAST(RollingPeopleVaccinated AS decimal(18,2)) / CAST(Population AS decimal(18,2)))*100 as PeopleVaccinatedPercentage
from #PercentPopulationVaccinated


-- Looking at Total Population vs Vaccinations (Using Views)

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) 
as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
AND ISDATE(dea.date) = 1
AND ISDATE(vac.date) = 1
AND CAST(dea.date AS datetime) = CAST(vac.date AS datetime)
WHERE dea.continent IS NOT NULL


SELECT * FROM PercentPopulationVaccinated


DROP View PercentPopulationVaccinated;

SELECT name, SCHEMA_NAME(schema_id) AS schema_name, *
FROM sys.views
WHERE name = 'PercentPopulationVaccinated';

select top (1000) * from dbo.PercentPopulationVaccinated;
/*
Covid 19 Data Exploration Project
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM [Portfolio Project]..CovidDeaths
Where continent is not null
order by 3,4

--SELECT *
--FROM [Portfolio Project]..CovidVaccinations
--order by 3,4

-- Selecting Data That Is Going to be Used

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..CovidDeaths
Where continent is not null
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows Chance of Dying from Contracting Covid per Country
SELECT Location, date, total_cases, total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
Where location like '%states%'
order by 1,2

-- Examining Total Cases vs Population
--Shows Percentage of Population Affected by Covid

SELECT Location, date, population, total_cases,(total_deaths/population)*100 as PercentageofInectedPopulation
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
order by 1,2

--Examining Countries with the HIghest Infection Rate Compared to Population

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_deaths/population)*100) as PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
group by location, population
order by PercentPopulationInfected desc

-- Exploration of Countries With the Highest Death Count Per Population

SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where continent is not null
group by location
order by TotalDeathCount desc

--Drilling Down Data By Continent
--Details Contintents with the Highest Death Count Per Population

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where continent is null
group by location
order by TotalDeathCount desc

--Examining Global Numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by date
order by 1,2

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM [Portfolio Project]..CovidDeaths
--Where location like '%states%'
Where continent is not null
Group by date
order by 1,2

--Examining the Total Population VS Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinationsCount
--,(RollingVaccinationsCount/population)*100
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Executing CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationsCount)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinationsCount
--,(RollingVaccinationsCount/population)*100
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVacinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by2,3
)
SELECT *, (RollingVaccinationsCount/Population)*100
FROM PopvsVac

-- Utilizing Temp Table to perform Calculation on Partition By In Previous Query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric, 
New_Vaccinations numeric,
RollingVaccinationsCount numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinationsCount
--,(RollingVaccinationsCount/population)*100
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by2,3

SELECT *, (RollingVaccinationsCount/Population)*100
FROM #PercentPopulationVaccinated

---- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int,vac.new_vaccinations)) over (Partition by dea.location Order by dea.location, dea.date) as RollingVaccinationsCount
--,(RollingVaccinationsCount/population)*100
FROM [Portfolio Project]..CovidDeaths dea
JOIN [Portfolio Project]..CovidVaccinations vac
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select *
From PercentPopulationVaccinated

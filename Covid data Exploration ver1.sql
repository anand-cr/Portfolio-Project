--check the tables

select * 
from [Portfolio Project]..covidDeaths
where continent is not null
order by 3,4;


select * 
from [Portfolio Project]..covidVaccination
order by 3,4;

--Select data we need
--ordering by Location and date
select Location , date ,total_cases , new_cases , total_deaths, population
from [Portfolio Project]..covidDeaths
order by 1,2


--Total cases vs Total Deaths 
--LikelyHood of dying if you contract covid
--For a particular country
select Location , date ,total_cases , total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from [Portfolio Project]..covidDeaths
order by 1,2

select Location , date ,total_cases , total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from [Portfolio Project]..covidDeaths
where location like '%states%'
order by 1,2

--total cases vs population
select Location , date ,total_cases , population, (total_cases/population)*100 as TotalCasesPerPopulation
from [Portfolio Project]..covidDeaths
where location like '%India%'
order by 1,2


--Countries with Highest infection rate
select Location ,population, MAX(total_cases) as HighestInfectionCount , (MAX(total_cases)/population)*100 as InfectionRate
from [Portfolio Project]..covidDeaths
Group by location,population
order by InfectionRate desc

--Countries with highest Death count per population
--here the death data looks inaccurate ,check the dataType and cast it as int
--where continent not null so we onlt get countruy wise data aand not continent

select Location , MAX(cast(total_deaths as int)) as HighestDeathCount 
from [Portfolio Project]..covidDeaths
where continent is not null
Group by location
order by HighestDeathCount desc


--Data wrt to continents
-- some innaccuracies here as data from canada etc is not added

select continent , MAX(cast(total_deaths as int)) as HighestDeathCount 
from [Portfolio Project]..covidDeaths
where continent is not null
Group by continent
order by HighestDeathCount desc

--instead use this
--if continent is null, then it is data related to continent
select location , MAX(cast(total_deaths as int)) as HighestDeathCount 
from [Portfolio Project]..covidDeaths
where continent is null
Group by location
order by HighestDeathCount desc

--GLOBAL NUMBERS
--using continent data
select Date, SUM(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,sum(cast(new_deaths as int))/sum(new_cases)*100 as deathrate --, SUM(cast(total_deaths as int)), (cast(total_deaths as int)/Sum(total_cases))*100 as DeathPercentage
from [Portfolio Project]..covidDeaths
where continent is  null and new_cases <> 0
group by date
order by 1,2

--using country data
select Date, SUM(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,
 sum(cast(new_deaths as int))/sum(new_cases)*100 as deathrate --, SUM(cast(total_deaths as int)), (cast(total_deaths as int)/Sum(total_cases))*100 as DeathPercentage
from [Portfolio Project]..covidDeaths
where continent is not null
group by date
order by 1,2


--TOTAL across globe

select SUM(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,
 sum(cast(new_deaths as int))/sum(new_cases)*100 as deathrate --, SUM(cast(total_deaths as int)), (cast(total_deaths as int)/Sum(total_cases))*100 as DeathPercentage
from [Portfolio Project]..covidDeaths
where continent is not null
--group by date
order by 1,2

--VACCINATION

--view table
select ROW_NUMBER() Over(Partition by location order by date)
from [Portfolio Project].dbo.covidVaccination

--Join tables

Select * 
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location


--Total population of world that is vaccinated

--new vaccination per day
Select CD.location ,CD.date,CV.new_vaccinations --sum(cast(new_vaccinations as bigint))
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location
where CD.continent is not null
order by 1,2

--to assign a row number to each col

select Date,ROW_NUMBER() Over(Partition by location order by date)
from [Portfolio Project].dbo.covidVaccination

--add total vaccintion till that day  Cumulative total
Select CD.location ,CD.date,population,CV.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) Over (partition by CD.location order by CD.population,CD.date) as CumulativeVaccinationCount  
	--ordering by date alone might suffice
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location
where CD.continent is not null 
order by 1,2


-- THIS WILL GIVE AN ERROR-

Select CD.location ,CD.date,population,CV.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) Over (partition by CD.location order by CD.population,CD.date) as CumulativeVaccinationCount,
	(CumulativeVaccinationCount / population) -- we cant use a row we just created , use CTE or temmp tables
	--ordering by date alone might suffice
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location
where CD.continent is not null 
order by 1,2



--USING CTE

WITH popVsVac(continent,location,date,population,New_vaccinations,CumulativeVaccinationCount)
as
(Select CD.continent,CD.location ,CD.date,population,CV.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) Over (partition by CD.location order by CD.population,CD.date) as CumulativeVaccinationCount  
	--ordering by date alone might suffice
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location
where CD.continent is not null 
)

select  continent,location,date,population,
		New_vaccinations,CumulativeVaccinationCount,
		(CumulativeVaccinationCount/population)*100

from popVsVac
	

--Using temp table

--How to drop tables without using drop
IF OBJECT_ID(N'tempdb..#percentagePopVaccinated') IS NOT NULL
    DROP TABLE #percentagePopVaccinated;
GO

--DROP TABLE IF EXISTS  #popVsVac

Create Table #percentagePopVaccinated (
continent nvarchar(255),
location nvarchar(255),
date DATETIME,
population numeric,
New_vaccinations numeric,
CumulativeVaccinationCount numeric)

Insert into #percentagePopVaccinated
Select CD.continent,CD.location ,CD.date,population,CV.new_vaccinations,
	sum(cast(new_vaccinations as int)) Over (partition by CD.location order by CD.population,CD.date) as CumulativeVaccinationCount  
	--ordering by date alone might suffice
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location
where CD.continent is not null 


select  continent,location,date,population,
		New_vaccinations,CumulativeVaccinationCount,
		(CumulativeVaccinationCount/population)*100 as percentVaccinated

from #percentagePopVaccinated
order by 2,3




--creating view to store data for visualisation
--cant use order by in view or temp table

Create view PercentPopulationVaccinated as 
Select CD.location ,CD.date,population,CV.new_vaccinations,
	sum(cast(new_vaccinations as bigint)) Over (partition by CD.location order by CD.population,CD.date) as CumulativeVaccinationCount  
from [Portfolio Project]..covidDeaths CD
Join [Portfolio Project]..covidVaccination CV
	on CD.date = CV.date
	and CD.location = CV.location
where CD.continent is not null 
--order by 1,2


select * 
from PercentPopulationVaccinated
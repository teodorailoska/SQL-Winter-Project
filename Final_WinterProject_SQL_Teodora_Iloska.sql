create database winter_project

use winter_project

--Creating tables without foreign keys

create table dbo.SeniorityLevel
(
	Id int identity(1,1) not null,
	Name nvarchar(100) not null,
	constraint pk_primaryKeySeniotiryLevel primary key clustered (Id asc)
)
go


create table dbo.Location
(
	Id int identity(1,1) not null,
	CountryName nvarchar(100) null,
	Continent nvarchar(100) null,
	Region nvarchar(100) null,
	constraint pk_primaryKeyLocation primary key (Id asc)
)
go

create table dbo.Department
(
	Id int identity(1,1) not null,
	Name nvarchar(100) not null,
	constraint pk_primaryKeyDepartment primary key clustered (Id asc)
)
go

-- Creating tables that have foreign keys
create table dbo.Employee
(
	Id int identity(1,1) not null,
	FirstName nvarchar(100) not null,
	LasName nvarchar(100) not null,
	LocationID int not null,
	SeniorityLevelID int not null,
	DepartmentID int not null,
	constraint pk_primaryKeyEmployee primary key clustered (Id asc),

	constraint fk_LocationID foreign key (LocationID) references dbo.Location (Id),
	constraint fk_SeniorityLevelId foreign key (SeniorityLevelID) references dbo.SeniorityLevel (Id),
	constraint fk_DepartmentId foreign key (DepartmentID) references dbo.Department (Id)
)
go


create table dbo.Salary
(
	Id int identity(1,1) not null,
	EmployeeID int not null,
	Month smallint not null,
	Year smallint not null,
	GrossAmount decimal(18,2) not null,
	NetAmount decimal(18,2) not null,
	RegularWorkAmount decimal(18,2) not null,
	BonusAmount decimal(18,2) not null,
	OvertimeAmount decimal(18,2) not null,
	VacationDays smallint not null,
	SickLeaveDays smallint not null,

	constraint pk_primaryKeySalary primary key clustered (Id),
	constraint fk_EmployeeID foreign key (EmployeeID) references dbo.Employee (Id)

)
go

-- Population Tables


-- Polpulating SneiorityLevel table
create or alter procedure PopulationSeniorityLevel
as
begin
insert into dbo.SeniorityLevel (Name)
values	('Junior'),
		('Intermediate'),
		('Senior'),
		('Lead'),
		('Project Manager'),
		('Division Manager'),
		('Office Manager'),
		('CEO'),
		('CTO'),
		('CIO')
end

exec PopulationSeniorityLevel

select * from dbo.SeniorityLevel
go

-- Populating Location

create or alter procedure PopulatingLocation
as
begin
insert into dbo.Location(CountryName, Continent, Region)

select wac.CountryName as CountryName, wac.Continent as Continent, wac.Region as Region
from WideWorldImporters.Application.Countries as wac
end

exec PopulatingLocation

select * from dbo.Location
go

-- Population Department Table

create or alter procedure PopulatingDepartment 
as
begin
insert into dbo.Department(Name)
values	('Personal Banking & Operations'),
		('Digital Banking Department'),
		('Retail Banking & Marketing Depratment'),
		('Wealth Management & Third Party Products'),
		('International Banking Division & DFB'),
		('Treasury'),
		('Information Technology'),
		('Corporate Comunications'),
		('Support Services & Branch Expansion'),
		('Human Resources')
end

exec  PopulatingDepartment

select * from dbo.Department
go

-- Populating Employee table

/*
ntile(10) over (order by wap.FullName) as SeniorityLevelID, ntile(10) over (order by wap.FullName) as DepartmentID,
ntile(190) over (order by wap.FullName) as LocationID
*/

create or alter procedure PopulatingEmployee
as
begin
insert into dbo.Employee (FirstName, LasName, LocationID, SeniorityLevelID, DepartmentID)

select left(wap.FullName,charindex(' ',wap.FullName)-1) as FirstName,right(wap.FullName,len(wap.FullName)-charindex(' ',wap.FullName)) as LastName,
ntile(190) over (order by wap.FullName) as LocationID,ntile(10) over (order by wap.FullName) as SeniorityLevelID,
ntile(10) over (order by wap.FullName) as DepartmentID
from WideWorldImporters.Application.People as wap

end

exec PopulatingEmployee

select * 
from dbo.Employee as e
inner join dbo.Location as l on e.LocationID = l.Id
inner join dbo.SeniorityLevel as s on e.SeniorityLevelID = s.Id
inner join dbo.Department as d on e.DepartmentID  = d.Id

go

-- For populating Dates I used the date table form the BrainsterDW database and I created it in this database
-- I will make cross join with Employee Table

-- Creating date table

CREATE TABLE dbo.[Date](
	[DateKey] [date] NOT NULL,
	[Day] [tinyint] NOT NULL,
	[DaySuffix] [char](2) NOT NULL,
	[Weekday] [tinyint] NOT NULL,
	[WeekDayName] [varchar](10) NOT NULL,
	[IsWeekend] [bit] NOT NULL,
	[IsHoliday] [bit] NOT NULL,
	[HolidayText] [varchar](64) SPARSE  NULL,
	[DOWInMonth] [tinyint] NOT NULL,
	[DayOfYear] [smallint] NOT NULL,
	[WeekOfMonth] [tinyint] NOT NULL,
	[WeekOfYear] [tinyint] NOT NULL,
	[ISOWeekOfYear] [tinyint] NOT NULL,
	[Month] [tinyint] NOT NULL,
	[MonthName] [varchar](10) NOT NULL,
	[Quarter] [tinyint] NOT NULL,
	[QuarterName] [varchar](6) NOT NULL,
	[Year] [int] NOT NULL,
	[MMYYYY] [char](6) NOT NULL,
	[MonthYear] [char](7) NOT NULL,
	[FirstDayOfMonth] [date] NOT NULL,
	[LastDayOfMonth] [date] NOT NULL,
	[FirstDayOfQuarter] [date] NOT NULL,
	[LastDayOfQuarter] [date] NOT NULL,
	[FirstDayOfYear] [date] NOT NULL,
	[LastDayOfYear] [date] NOT NULL,
	[FirstDayOfNextMonth] [date] NOT NULL,
	[FirstDayOfNextYear] [date] NOT NULL,
 CONSTRAINT [PK_Date] PRIMARY KEY CLUSTERED ([DateKey] ASC)
)
GO


-- populating Date Table

CREATE or ALTER PROCEDURE PopulateDateTable
AS
BEGIN
	DECLARE
		@StartDate DATE = '2000-01-01'
	,	@NumberOfYears INT = 30
	,	@CutoffDate DATE;
	SET @CutoffDate = DATEADD(YEAR, @NumberOfYears, @StartDate);

	-- prevent set or regional settings from interfering with 
	-- interpretation of dates / literals
	SET DATEFIRST 7;
	SET DATEFORMAT mdy;
	SET LANGUAGE US_ENGLISH;

	-- this is just a holding table for intermediate calculations:
	CREATE TABLE #dim
	(
		[Date]       DATE        NOT NULL, 
		[day]        AS DATEPART(DAY,      [date]),
		[month]      AS DATEPART(MONTH,    [date]),
		FirstOfMonth AS CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, [date]), 0)),
		[MonthName]  AS DATENAME(MONTH,    [date]),
		[week]       AS DATEPART(WEEK,     [date]),
		[ISOweek]    AS DATEPART(ISO_WEEK, [date]),
		[DayOfWeek]  AS DATEPART(WEEKDAY,  [date]),
		[quarter]    AS DATEPART(QUARTER,  [date]),
		[year]       AS DATEPART(YEAR,     [date]),
		FirstOfYear  AS CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, [date]), 0)),
		Style112     AS CONVERT(CHAR(8),   [date], 112),
		Style101     AS CONVERT(CHAR(10),  [date], 101)
	);

	-- use the catalog views to generate as many rows as we need
	--DECLARE @StartDate DATE = '2000-01-01',  @CutoffDate  DATE = '2010-01-01'
	-- SELECT @StartDate , @StartDate DATEDIFF(DAY, @StartDate, @CutoffDate)
	-- 10 godini * 365 -> 3653
	INSERT INTO #dim ([date]) 
	SELECT
		DATEADD(DAY, rn - 1, @StartDate) as [date]
	FROM 
	(
		SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
			rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
		FROM
			-- on my system this would support > 5 million days
			sys.all_objects AS s1
			CROSS JOIN sys.all_objects AS s2
		ORDER BY
			s1.[object_id]
	) AS x;
	-- SELECT * FROM #dim

	INSERT [Date] ([DateKey], [Day], [DaySuffix], [Weekday], [WeekDayName], [IsWeekend], 
	[IsHoliday], [HolidayText], [DOWInMonth], [DayOfYear], [WeekOfMonth], [WeekOfYear], 
	[ISOWeekOfYear], [Month], [MonthName], [Quarter], [QuarterName], [Year], [MMYYYY], [MonthYear], 
	[FirstDayOfMonth], [LastDayOfMonth], [FirstDayOfQuarter], [LastDayOfQuarter], [FirstDayOfYear],
	[LastDayOfYear], [FirstDayOfNextMonth], [FirstDayOfNextYear])
	SELECT
		--DateKey     = CONVERT(INT, Style112),
		[DateKey]        = [date],
		[Day]         = CONVERT(TINYINT, [day]),
		DaySuffix     = CONVERT(CHAR(2), CASE WHEN [day] / 10 = 1 THEN 'th' ELSE 
						CASE RIGHT([day], 1) WHEN '1' THEN 'st' WHEN '2' THEN 'nd' 
						WHEN '3' THEN 'rd' ELSE 'th' END END),
		[Weekday]     = CONVERT(TINYINT, [DayOfWeek]),
		[WeekDayName] = CONVERT(VARCHAR(10), DATENAME(WEEKDAY, [date])),
		[IsWeekend]   = CONVERT(BIT, CASE WHEN [DayOfWeek] IN (1,7) THEN 1 ELSE 0 END),
		[IsHoliday]   = CONVERT(BIT, 0),
		HolidayText   = CONVERT(VARCHAR(64), NULL),
		[DOWInMonth]  = CONVERT(TINYINT, ROW_NUMBER() OVER 
						(PARTITION BY FirstOfMonth, [DayOfWeek] ORDER BY [date])),
		[DayOfYear]   = CONVERT(SMALLINT, DATEPART(DAYOFYEAR, [date])),
		WeekOfMonth   = CONVERT(TINYINT, DENSE_RANK() OVER 
						(PARTITION BY [year], [month] ORDER BY [week])),
		WeekOfYear    = CONVERT(TINYINT, [week]),
		ISOWeekOfYear = CONVERT(TINYINT, ISOWeek),
		[Month]       = CONVERT(TINYINT, [month]),
		[MonthName]   = CONVERT(VARCHAR(10), [MonthName]),
		[Quarter]     = CONVERT(TINYINT, [quarter]),
		QuarterName   = CONVERT(VARCHAR(6), CASE [quarter] WHEN 1 THEN 'First' 
						WHEN 2 THEN 'Second' WHEN 3 THEN 'Third' WHEN 4 THEN 'Fourth' END), 
		[Year]        = [year],
		MMYYYY        = CONVERT(CHAR(6), LEFT(Style101, 2)    + LEFT(Style112, 4)),
		MonthYear     = CONVERT(CHAR(7), LEFT([MonthName], 3) + LEFT(Style112, 4)),
		FirstDayOfMonth     = FirstOfMonth,
		LastDayOfMonth      = MAX([date]) OVER (PARTITION BY [year], [month]),
		FirstDayOfQuarter   = MIN([date]) OVER (PARTITION BY [year], [quarter]),
		LastDayOfQuarter    = MAX([date]) OVER (PARTITION BY [year], [quarter]),
		FirstDayOfYear      = FirstOfYear,
		LastDayOfYear       = MAX([date]) OVER (PARTITION BY [year]),
		FirstDayOfNextMonth = DATEADD(MONTH, 1, FirstOfMonth),
		FirstDayOfNextYear  = DATEADD(YEAR,  1, FirstOfYear)
	FROM #dim
END
GO


exec PopulateDateTable

select * from dbo.Date
go


-- Populating Salary Table

create or alter procedure PopulateSalary
as
begin
-- Here I created temporary table #TempDate for better visibility

create table #TempDate
(
	Month smallint not null,
	Year smallint not null,
)

-- Populating TemDate with cartesian product

insert into #TempDate (Month,Year)
select distinct d.Month as Month, d.Year as Year
from dbo.Date as d
where d.DateKey between ('2001-01-01') and ('2020-12-31')
order by d.Year,d.Month asc

;with CTE1 
as
(
	select e.Id as EmployeeId, td.Month as Month, td.Year as Year,
	CAST(ABS(CHECKSUM(NEWID())) % (30000-60000) AS decimal(18,2)) + 30000 as GrossAmount
	from  #TempDate as td
	cross join Employee as e
)
, CTE2 as (select EmployeeId,Month,Year,GrossAmount,GrossAmount * 0.9 as NetAmount
from CTE1)

insert into dbo.Salary(EmployeeID, Month, Year, GrossAmount, NetAmount, RegularWorkAmount, BonusAmount, OvertimeAmount, VacationDays, SickLeaveDays)

select EmployeeId,Month,Year,GrossAmount,NetAmount,NetAmount * 0.8 as RegularWorkAmount,
isnull(null,0.00) as BonusAmount, isnull(null,0.00) as OvertimeAmount,isnull(null,0) as VacationDays, isnull(null,0) as SickLeaveDays

from CTE2


-- Updating BonusAmount
update dbo.Salary set BonusAmount =  NetAmount - RegularWorkAmount
where Month in ('01','03','05','07','09','11')

--Updating OvertimeAmount

update dbo.Salary set OvertimeAmount = NetAmount - RegularWorkAmount
where Month in ('02','04','06','08','10','12')


-- updating vacation days columns
update dbo.Salary set VacationDays = 10
where Month in ('07','12')

--Generating random Vacation days and Sickened leave days with the script from the Project Description

update dbo.salary set vacationDays = vacationDays + (EmployeeId % 2)
where  (EmployeeID + Month + Year)%5 = 1

update dbo.salary set SickLeaveDays = EmployeeId%8, vacationDays = vacationDays + (EmployeeId % 3)
where  (EmployeeID + Month + Year)%5 = 2

end
go

exec PopulateSalary

select * from dbo.Salary
go


-- The following querry should work fine

select * from dbo.Salary 
where NetAmount <> (RegularWorkAmount + BonusAmount + OvertimeAmount)
go

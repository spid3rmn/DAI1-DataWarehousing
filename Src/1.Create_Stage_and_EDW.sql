IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'H1AW')
BEGIN
  CREATE DATABASE H1AW;
END;
GO

USE H1AW
GO 

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'EDW')
BEGIN
  EXEC('CREATE SCHEMA [EDW]');
END;
GO

--			CREATE THE EDW TABLES

DROP TABLE IF EXISTS edw."FactSales";
DROP TABLE IF EXISTS edw."DimDate";
DROP TABLE IF EXISTS edw."DimCustomer";
DROP TABLE IF EXISTS edw."DimEmployee";
DROP TABLE IF EXISTS edw."DimTerritory";
DROP TABLE IF EXISTS edw."DimProduct";

CREATE TABLE edw."DimDate" (
	[D_ID] [int] NOT NULL,
	[Date] [datetime] NOT NULL,
	[Day] [int] NOT NULL,
	[Month] [int] NOT NULL,
    [MonthName] [nvarchar](9),
	[Week] [int] NOT NULL,
	[Quarter] [int] NOT NULL,
	[Year] [int] NOT NULL,
	[DayofWeek] [int] NOT NULL,
	[WeekDayName] [nvarchar](9) NOT NULL,

	CONSTRAINT [Pk_DimDate] PRIMARY KEY CLUSTERED (
		[D_ID] ASC
	)
)

DECLARE @StartDate DATETIME;
DECLARE @EndDate DATETIME;

SET @StartDate = '1996-01-01'
SET @EndDate = DATEADD(YEAR, 100, @StartDate)

TRUNCATE TABLE [edw].[DimDate]
WHILE @StartDate <= @EndDate
	BEGIN
		INSERT INTO [edw].[DimDate]
				   ([D_ID]
				   ,[Date]
				   ,[Day]
				   ,[Month]
				   ,[MonthName]
				   ,[Week]
				   ,[Quarter]
				   ,[Year]
				   ,[DayofWeek]
				   ,[WeekDayName])
			SELECT
				CONVERT(CHAR(8), @StartDate, 112) AS D_ID,
				@StartDate as [Date],
				DATEPART(day, @StartDate) AS Day,
				DATEPART(month, @StartDate) AS Month,
				DATENAME(month, @StartDate) AS MonthName,
				DATEPART(week, @StartDate) AS Week,
				DATEPART(QUARTER, @StartDate) AS Quarter,
				DATEPART(year, @StartDate) AS Year,
				DATEPART(WEEKDAY, @StartDate) AS DayOfWeek,
				DATENAME(WEEKDAY, @StartDate) AS WeekdayName
		SET @StartDate = DATEADD(dd, 1, @StartDate)
	END

CREATE TABLE edw."DimCustomer" (
	"C_ID" "int" IDENTITY (1, 1) NOT NULL ,
	"CustomerID" "int" NOT NULL,
	"Type" char(2) NOT NULL,
	"Name" nvarchar (50) NOT NULL,
	"CountryCode" nvarchar (3) NOT NULL,
	"TerritoryName" nvarchar (50) NOT NULL,

	CONSTRAINT "PK_DimCustomer" PRIMARY KEY  CLUSTERED 
	(
		"C_ID"
	)
)

CREATE TABLE edw."DimEmployee" (
	"E_ID" "int" IDENTITY (1, 1) NOT NULL ,
	"EmployeeID" "int" NOT NULL,
	"Name" nvarchar (25) NOT NULL,
	"Age" "int" NOT NULL,
	"YearsOfExperience" "int" NOT NULL,
	"Gender" char NOT NULL,

	CONSTRAINT "PK_DimEmployee" PRIMARY KEY  CLUSTERED 
	(
		"E_ID"
	)
)


CREATE TABLE edw."DimProduct" (
	"P_ID" "int" IDENTITY (1, 1) NOT NULL ,
	"ProductID" "int" NOT NULL,
	"Name" nvarchar (50) NOT NULL,
	"Model" nvarchar (50) NOT NULL,
	"SaleCost" "float" NOT NULL,
	"ProductionCost" "float" NOT NULL

	CONSTRAINT "PK_DimProduct" PRIMARY KEY  CLUSTERED 
	(
		"P_ID"
	),
	CONSTRAINT "CK_Costs" 
	CHECK (ProductionCost > 0 AND SaleCost > 0)
)

CREATE TABLE edw."DimTerritory" (
	"T_ID" "int" IDENTITY (1, 1) NOT NULL ,
	"TerritoryID" "int" NOT NULL,
	"Name" nvarchar (50) NOT NULL,
	"CountryCode" nvarchar (3) NOT NULL,
	"Group" nvarchar (50) NOT NULL

	CONSTRAINT "PK_DimTerritory" PRIMARY KEY CLUSTERED
	(
		"T_ID"
	)
)

CREATE TABLE edw."FactSales" (
	/*"CustomerID" "int" NOT NULL ,
	"ProductID" "int" NOT NULL ,
	"EmployeeID" "int"  NULL ,
	"TerritoryID" "int" NOT NULL ,*/
	"C_ID" "int" NOT NULL,
	"P_ID" "int" NOT NULL,
	"E_ID" "int"  NULL,
	"T_ID" "int" NOT NULL,
	"D_ID" "int" NOT NULL,
	"Total" "float" NOT NULL ,
	"Profit" "float" NOT NULL ,
	"Quantity" "int" NOT NULL ,
	
	/*CONSTRAINT "PK_FactSales" PRIMARY KEY  CLUSTERED 
	(
		"C_ID",
		"P_ID",
		"E_ID",
		"T_ID",
		"D_ID"
	),*/
	CONSTRAINT "FK_Date" FOREIGN KEY 
	(
		"D_ID"
	) REFERENCES edw."DimDate" (
		"D_ID"
	),
	CONSTRAINT "FK_Employee" FOREIGN KEY 
	(
		"E_ID"
	) REFERENCES edw."DimEmployee" (
		"E_ID"
	),
	CONSTRAINT "FK_DimCustomer" FOREIGN KEY 
	(
		"C_ID"
	) REFERENCES edw."DimCustomer" (
		"C_ID"
	),
	CONSTRAINT "FK_DimTerritory" FOREIGN KEY 
	(
		"T_ID"
	) REFERENCES edw."DimTerritory" (
		"T_ID"
	),
	CONSTRAINT "FK_DimProduct" FOREIGN KEY 
	(
		"P_ID"
	) REFERENCES edw."DimProduct" (
		"P_ID"
	),
	CONSTRAINT "CK_Quantity" CHECK (Quantity > 0)
)


--			CREATE THE STAGE TABLES

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stage')
BEGIN
  EXEC('CREATE SCHEMA [stage]');
END;
GO

/*			CREATE DimCustomer TABLE			*/
DROP TABLE IF EXISTS stage."DimCustomer";
CREATE TABLE stage."DimCustomer" (
	"CustomerID" "int" NULL,
	"Type" char(2) NULL,
	"FirstName" nvarchar (50) NULL,
	"LastName" nvarchar (50) NULL,
	"ConcatName" nvarchar (50) NULL,
	"StoreName" nvarchar (50) NULL,
	"CountryCode" nvarchar (3) NULL,
	"TerritoryName" nvarchar (50) NULL

)

/*			CREATE DimEmployee TABLE			*/
DROP TABLE IF EXISTS stage."DimEmployee";
CREATE TABLE stage."DimEmployee" (
	"EmployeeID" "int" NULL,
	"FirstName" nvarchar (50) NULL,
	"LastName" nvarchar (50) NULL,
	"ConcatName" nvarchar (50) NULL,
	"DOB" datetime NULL,
	"Age" "int" NULL,
	"HireDate" datetime NULL,
	"YearsOfExperience" "int" NULL,
	"Gender" char NULL,
)

/*			CREATE DimProduct TABLE			*/
DROP TABLE IF EXISTS stage."DimProduct";
CREATE TABLE stage."DimProduct" (
	"ProductID" "int" NULL,
	"Name" nvarchar (50) NULL,
	"Model" nvarchar (50) NULL,
	"SaleCost" "float" NULL,
	"ProductionCost" "float" NULL
)

/*			CREATE DimTerritory TABLE			*/
DROP TABLE IF EXISTS stage."DimTerritory";
CREATE TABLE stage."DimTerritory" (
	"TerritoryID" "int" NULL,
	"Name" nvarchar (50) NULL,
	"CountryCode" nvarchar (3) NULL,
	"Group" nvarchar (50) NULL
)

/*			CREATE FactSales TABLE			*/
DROP TABLE IF EXISTS stage."FactSales";
CREATE TABLE stage."FactSales" (
	"CustomerID" "int" NULL ,
	"ProductID" "int" NULL ,
	"EmployeeID" "int" NULL ,
	"TerritoryID" "int" NULL ,
	"OrderDate" "datetime" NULL,
	"CID" "int" NULL ,
	"PID" "int" NULL ,
	"EID" "int" NULL ,
	"TID" "int" NULL ,
	"DID" "int" NULL ,
	"Total" "float" NULL ,
	"Profit" "float" NULL ,
	"Quantity" "int" NULL ,
)
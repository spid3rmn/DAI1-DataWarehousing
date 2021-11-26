USE [H1AW]
GO

--			LOAD DATA INTO THE STAGE DIMENSIONS

--		CUSTOMER DIMENSION

USE [H1AW]
GO
TRUNCATE TABLE [stage].[DimCustomer]

--	PERSONS

INSERT INTO [stage].[DimCustomer]
           ([CustomerID]
           ,[FirstName]
           ,[LastName]
           ,[CountryCode]
           ,[TerritoryName])

SELECT 
	c.CustomerID,
	pe.FirstName,
	pe.LastName,
	ster.[CountryRegionCode] as [CountryCode],
	ster.[Name] as [TerritoryName]

	FROM [AdventureWorks2019].[Sales].Customer c
	inner JOIN [AdventureWorks2019].[Sales].SalesTerritory ster
	ON c.TerritoryID=ster.TerritoryID
	inner join [AdventureWorks2019].[Person].Person pe
	on c.PersonID=pe.BusinessEntityID
GO

--	STORES

INSERT INTO [stage].[DimCustomer]
           ([CustomerID]
           ,[StoreName]
           ,[CountryCode]
           ,[TerritoryName])

SELECT 
	c.CustomerID,
	st.Name,
	ster.[CountryRegionCode] as [CountryCode],
	ster.[Name] as [TerritoryName]

	FROM [AdventureWorks2019].[Sales].Customer c
	inner JOIN [AdventureWorks2019].[Sales].SalesTerritory ster
	ON c.TerritoryID=ster.TerritoryID
	inner join [AdventureWorks2019].[Sales].Store st
	on c.StoreID=st.BusinessEntityID
GO

--		PRODUCT DIMENSION
TRUNCATE TABLE [stage].[DimProduct]
INSERT INTO [stage].[DimProduct]
           ([ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
           ,[ProductionCost])
SELECT 
			p.ProductID,
			p.Name,
			pm.Name,
			p.ListPrice,
			p.StandardCost

FROM [AdventureWorks2019].[Production].Product p
inner join [AdventureWorks2019].[Production].ProductModel pm
on p.ProductModelID=pm.ProductModelID
GO

--		EMPLOYEE DIMENSION
TRUNCATE TABLE [stage].[DimEmployee]
INSERT INTO [stage].[DimEmployee]
           ([EmployeeID]
		   ,[FirstName]
		   ,[LastName]
           ,[DOB]
           ,[HireDate]
           ,[Gender])
SELECT 
	emp.BusinessEntityID,
	p.[FirstName],
	p.[LastName],
	emp.BirthDate,
	emp.HireDate,
	emp.Gender

FROM  [AdventureWorks2019].[HumanResources].Employee emp
inner join [AdventureWorks2019].[Person].Person as p
on emp.BusinessEntityID=p.BusinessEntityID
GO

--		TERRITORY DIMENSION
TRUNCATE TABLE [stage].[DimTerritory]
INSERT INTO [stage].[DimTerritory]
           ([TerritoryID]
		   ,[Name]
           ,[CountryCode]
           ,[Group])
SELECT 
			[TerritoryID],
			[Name],
			[CountryRegionCode],
			[Group]
FROM [AdventureWorks2019].[Sales].SalesTerritory
GO




--			UPDATE STAGE DIMENSIONS

UPDATE stage.DimCustomer
SET ConcatName = CONCAT(FirstName, ' ' , LastName),
	Type = 'IN'
WHERE StoreName IS NULL

UPDATE stage.DimCustomer
SET ConcatName = StoreName,
	Type = 'ST'
WHERE FirstName IS NULL AND LastName IS NULL


--			UPDATE EMPLOYEE DIMENSIONS

UPDATE stage.DimEmployee
SET ConcatName = CONCAT(FirstName, ' ', LastName),
	Age = DATEDIFF(hour, DOB, GETDATE())/8766,
	YearsOfExperience = DATEDIFF(hour, HireDate, GETDATE())/8766



--			LOAD STAGE DIMENSIONS INTO EDW

--		CUSTOMER DIMENSION

INSERT INTO [edw].[DimCustomer]
           ([CustomerID]
           ,[Type]
           ,[Name]
           ,[CountryCode]
           ,[TerritoryName])
SELECT 
	CustomerID,
	Type,
	ConcatName,
	CountryCode,
	TerritoryName
FROM [stage].DimCustomer
GO

--		PRODUCT DIMENSION

USE [H1AW]
GO

INSERT INTO [edw].[DimProduct]
           ([ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
           ,[ProductionCost])
SELECT 
	ProductID,
	Name,
	Model,
	SaleCost,
	ProductionCost
FROM [stage].DimProduct
GO

--		EMPLOYEE DIMENSION
INSERT INTO [edw].[DimEmployee]
           ([EmployeeID]
           ,[Name]
           ,[Age]
           ,[YearsOfExperience]
           ,[Gender])
SELECT 
	EmployeeID,
	ConcatName,
	Age,
	YearsOfExperience,
	Gender
FROM [stage].DimEmployee
GO

--		TERRITORY DIMENSION

INSERT INTO [edw].[DimTerritory]
           ([TerritoryID]
           ,[Name]
           ,[CountryCode]
           ,[Group])
SELECT 
	TerritoryID,
	Name,
	CountryCode,
	[Group]
FROM stage.DimTerritory
GO


--			LOAD STAGE FACT TABLE

USE [H1AW]
GO
TRUNCATE TABLE [stage].[FactSales]
INSERT INTO [stage].[FactSales]
           ([CustomerID]
           ,[ProductID]
           ,[EmployeeID]
           ,[TerritoryID]
           ,[OrderDate]
           ,[Total]
           ,[Profit]
           ,[Quantity])
SELECT 
			soh.CustomerID,
			sod.ProductID,
			soh.SalesPersonID,
			soh.TerritoryID,
			soh.OrderDate,
			sod.LineTotal,
			sod.LineTotal - (sod.OrderQty * prod.StandardCost) as [Profit],
			sod.OrderQty
FROM [AdventureWorks2019].[Sales].SalesOrderDetail sod
inner join [AdventureWorks2019].[Sales].SalesOrderHeader soh
on sod.SalesOrderID=soh.SalesOrderID
inner join [AdventureWorks2019].[Production].Product prod
on sod.ProductID=prod.ProductID
GO

--		KEY LOOKUP

USE [H1AW]
GO

UPDATE stage.FactSales
SET stage.FactSales.CID = edwCust.C_ID
from stage.FactSales stgFact
right join  
edw.DimCustomer edwCust
on stgFact.CustomerID = edwCust.CustomerID


UPDATE stage.FactSales
SET stage.FactSales.PID = edwProd.P_ID
from stage.FactSales stgFact
right join  
edw.DimProduct edwProd
on stgFact.ProductID = edwProd.ProductID

UPDATE stage.FactSales
SET stage.FactSales.EID = edwEmp.E_ID
from stage.FactSales stgFact
right join  
edw.DimEmployee edwEmp
on stgFact.EmployeeID = edwEmp.EmployeeID

/*UPDATE stage.FactSales
SET EmployeeID = -1 , EID = -1
WHERE EmployeeID is null*/

UPDATE stage.FactSales
SET stage.FactSales.TID = edwTer.T_ID
from stage.FactSales stgFact
right join  
edw.DimTerritory edwTer
on stgFact.TerritoryID = edwTer.TerritoryID

UPDATE stage.FactSales
SET stage.FactSales.DID = edwDate.D_ID
from stage.FactSales stgFact
right join  
edw.DimDate edwDate
on stgFact.OrderDate = edwDate.Date



--			INSERT FACT TABLE FROM STAGE TO EDW

USE [H1AW]
GO

INSERT INTO [edw].[FactSales]
           ([C_ID]
           ,[P_ID]
           ,[E_ID]
           ,[T_ID]
           ,[D_ID]
           ,[Total]
           ,[Profit]
           ,[Quantity])
SELECT [CID]
      ,[PID]
      ,[EID]
      ,[TID]
      ,[DID]
      ,[Total]
      ,[Profit]
      ,[Quantity]
  FROM [stage].[FactSales]

GO


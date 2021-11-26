/*				FACT TABLE				*/

USE [H1AW]
GO

/*		get LastLoadDate		*/
DECLARE @LastLoadDate datetime
SET @LastLoadDate = (SELECT [Date] FROM edw.DimDate
					 WHERE D_ID in (SELECT MAX(LastLoadDate) FROM ETL.LogUpdate WHERE [Table]='FactSales'))


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
where soh.OrderDate > (@LastLoadDate)
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
where edwCust.ValidTo = 99991231


UPDATE stage.FactSales
SET stage.FactSales.PID = edwProd.P_ID
from stage.FactSales stgFact
right join  
edw.DimProduct edwProd
on stgFact.ProductID = edwProd.ProductID
where edwProd.ValidTo = 99991231

UPDATE stage.FactSales
SET stage.FactSales.EID = edwEmp.E_ID
from stage.FactSales stgFact
right join  
edw.DimEmployee edwEmp
on stgFact.EmployeeID = edwEmp.EmployeeID
where edwEmp.ValidTo = 99991231

UPDATE stage.FactSales
SET stage.FactSales.TID = edwTer.T_ID
from stage.FactSales stgFact
right join  
edw.DimTerritory edwTer
on stgFact.TerritoryID = edwTer.TerritoryID
where edwTer.ValidTo = 99991231

UPDATE stage.FactSales
SET stage.FactSales.DID = edwDate.D_ID
from stage.FactSales stgFact
right join  
edw.DimDate edwDate
on stgFact.OrderDate = edwDate.Date



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

use H1AW
DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)
insert into etl.LogUpdate("Table", "LastLoadDate") values ('FactSales', @NewLoadDate)
GO




select * from edw.DimTerritory
where ValidTo = 20211108
USE [H1AW]
GO

/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimProduct')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get new	*/
INSERT INTO [edw].[DimProduct]
           ([ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
           ,[ValidFrom]
           ,[ValidTo])
     
	SELECT  [ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
		   ,@NewLoadDate
		   ,@FutureDate
	FROM stage.DimProduct
	WHERE ProductID in (SELECT ProductID
						  FROM stage.DimProduct 
						  EXCEPT 
						  SELECT ProductID FROM edw.DimProduct
						  WHERE ValidTo=99991231)


INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimProduct', @NewLoadDate)
go
/*	stop get new	*/


/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimProduct')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get changed	*/
drop table if exists #tmp


SELECT [ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
  INTO #tmp
  FROM [stage].[DimProduct] 
  EXCEPT
  SELECT [ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
  FROM edw.DimProduct
  WHERE ValidTo=99991231
  EXCEPT
  SELECT [ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
  FROM stage.DimProduct WHERE ProductID in (SELECT ProductID from stage.DimProduct
												except
												select ProductID from edw.DimProduct
												where ValidTo=99991231)

INSERT INTO [edw].[DimProduct]
           ([ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
            ,[ValidFrom]
            ,[ValidTo])
     
	SELECT  [ProductID]
           ,[Name]
           ,[Model]
           ,[SaleCost]
		   ,[ProductionCost]
			 ,@NewLoadDate
			 ,@FutureDate
		FROM #tmp

update edw.DimProduct
set ValidTo = @NewLoadDate-1
where ProductID in (select ProductID from #tmp) and edw.DimProduct.ValidFrom<@NewLoadDate

drop table if exists #tmp

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimProduct', @NewLoadDate)
go

/*	stop get changed	*/


/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimProduct')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231


/*	start get deleted	*/


update edw.DimProduct
set ValidTo = @NewLoadDate-1
where ProductID in (select ProductID
					  from edw.DimProduct
					  where ProductID in (select ProductID
											from edw.DimProduct
											except 
											select ProductID
											from stage.DimProduct))
					  and ValidTo=99991231

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimProduct', @NewLoadDate)
go

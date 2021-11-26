USE [H1AW]
GO

/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimCustomer')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get new	*/
INSERT INTO [edw].[DimCustomer]
           ([CustomerID]
           ,[Type]
           ,[Name]
           ,[CountryCode]
		   ,[TerritoryName]
           ,[ValidFrom]
           ,[ValidTo])
     
	SELECT  [CustomerID]
           ,[Type]
           ,[ConcatName]
           ,[CountryCode]
		   ,[TerritoryName]
		   ,@NewLoadDate
		   ,@FutureDate
	FROM stage.DimCustomer
	WHERE CustomerID in (SELECT CustomerID
						  FROM stage.DimCustomer 
						  EXCEPT 
						  SELECT CustomerID FROM edw.DimCustomer
						  WHERE ValidTo=99991231)


INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimCustomer', @NewLoadDate)
go
/*	stop get new	*/


/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimCustomer')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get changed	*/
drop table if exists #tmp

SELECT [CustomerID]
      ,[Type]
      ,[ConcatName]
      ,[CountryCode]
	  ,[TerritoryName]
  INTO #tmp
  FROM [stage].[DimCustomer] 
  EXCEPT
  SELECT [CustomerID]
		,[Type]
		,[Name]
		,[CountryCode]
		,[TerritoryName]
  FROM edw.DimCustomer
  WHERE ValidTo=99991231
  EXCEPT
  SELECT [CustomerID]
		,[Type]
		,[ConcatName]
		,[CountryCode]
		,[TerritoryName]
  FROM stage.DimCustomer WHERE CustomerID in (SELECT CustomerID from stage.DimCustomer
												except
												select CustomerID from edw.DimCustomer
												where ValidTo=99991231)

INSERT INTO [edw].[DimCustomer]
           ([CustomerID]
			,[Type]
			,[Name]
			,[CountryCode]
			,[TerritoryName]
            ,[ValidFrom]
            ,[ValidTo])
     
	SELECT  [CustomerID]
			 ,[Type]
			 ,[ConcatName]
			 ,[CountryCode]
			 ,[TerritoryName]
			 ,@NewLoadDate
			 ,@FutureDate
		FROM #tmp

update edw.DimCustomer
set ValidTo = @NewLoadDate-1
where CustomerID in (select CustomerID from #tmp) and edw.DimCustomer.ValidFrom<@NewLoadDate

drop table if exists #tmp

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimCustomer', @NewLoadDate)
go

/*	stop get changed	*/


/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimCustomer')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231


/*	start get deleted	*/


update edw.DimCustomer
set ValidTo = @NewLoadDate-1
where CustomerID in (select CustomerID
					  from edw.DimCustomer
					  where CustomerID in (select CustomerID
											from edw.DimCustomer
											except 
											select CustomerID
											from stage.DimCustomer))
					  and ValidTo=99991231

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimCustomer', @NewLoadDate)
go

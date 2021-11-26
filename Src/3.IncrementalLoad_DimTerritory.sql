/*				Terrirory dimension				*/

USE [H1AW]
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ETL')
BEGIN
  EXEC('CREATE SCHEMA [ETL]');
END;
GO

DROP TABLE IF EXISTS ETL.LogUpdate;
CREATE TABLE ETL."LogUpdate" (
	"Table" nvarchar(50) NULL,
	"LastLoadDate" int NULL,
)

INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimCustomer', 20140630)
INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimProduct', 20140630)
INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimEmployee', 20140630)
INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimTerritory', 20140630)
INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('FactSales', 20140630)


alter table edw.DimCustomer 
add ValidFrom int, ValidTo int

alter table edw.DimProduct
add ValidFrom int, ValidTo int

alter table edw.DimEmployee
add ValidFrom int, ValidTo int

alter table edw.DimTErritory
add ValidFrom int, ValidTo int


update edw.DimCustomer
set ValidFrom = 20110531, ValidTo = 99991231

update edw.DimEmployee
set ValidFrom = 20110531, ValidTo = 99991231

update edw.DimProduct
set ValidFrom = 20110531, ValidTo = 99991231

update edw.DimTerritory
set ValidFrom = 20110531, ValidTo = 99991231


/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimTerritory')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get new	*/
INSERT INTO [edw].[DimTerritory]
           ([TerritoryID]
           ,[Name]
           ,[CountryCode]
           ,[Group]
           ,[ValidFrom]
           ,[ValidTo])
     
	SELECT  [TerritoryID]
           ,[Name]
           ,[CountryCode]
           ,[Group]
		   ,@NewLoadDate
		   ,@FutureDate
	FROM stage.DimTerritory
	WHERE TerritoryID in (SELECT TerritoryID
						  FROM stage.DimTerritory 
						  EXCEPT 
						  SELECT TerritoryID FROM edw.DimTerritory
						  WHERE ValidTo=99991231)

INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimTerritory', @NewLoadDate)
go
/*	stop get new	*/



/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimTerritory')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get changed	*/
SELECT [TerritoryID]
      ,[Name]
      ,[CountryCode]
      ,[Group]
  INTO #tmp
  FROM [stage].[DimTerritory] 
  EXCEPT
  SELECT [TerritoryID]
      ,[Name]
      ,[CountryCode]
      ,[Group]
  FROM edw.DimTerritory
  WHERE ValidTo=99991231
  EXCEPT
  SELECT [TerritoryID]
      ,[Name]
      ,[CountryCode]
      ,[Group]
  FROM stage.DimTerritory WHERE TerritoryID in (SELECT TerritoryID from stage.DimTerritory 
												except
												select TerritoryID from edw.DimTerritory
												where ValidTo=99991231)

INSERT INTO [edw].[DimTerritory]
           ([TerritoryID]
           ,[Name]
           ,[CountryCode]
           ,[Group]
           ,[ValidFrom]
           ,[ValidTo])
		SELECT 
			[TerritoryID]
		   ,[Name]
           ,[CountryCode]
		   ,[Group]
		   ,@NewLoadDate
		   ,@FutureDate
		FROM #tmp

update edw.DimTerritory 
set ValidTo = @NewLoadDate-1
where TerritoryID in (select TerritoryID from #tmp) and edw.DimTerritory.ValidFrom<@NewLoadDate

drop table if exists #tmp

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimTerritory', @NewLoadDate)
go

/*	stop get changed	*/



/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimTerritory')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231


/*	start get deleted	*/


update edw.DimTerritory
set ValidTo = @NewLoadDate-1
where TerritoryID in (select TerritoryID
					  from edw.DimTerritory 
					  where TerritoryID in (select TerritoryID 
											from edw.DimTerritory 
											except 
											select TerritoryID 
											from stage.DimTerritory))
					  and ValidTo=99991231

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimTerritory', @NewLoadDate)
go

/*	stop get deleted	*/
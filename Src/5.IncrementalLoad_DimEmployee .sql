USE [H1AW]
GO

/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimEmployee')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get new	*/
INSERT INTO [edw].[DimEmployee]
           ([EmployeeID]
           ,[Name]
           ,[Age]
           ,[YearsOfExperience]
		   ,[Gender]
           ,[ValidFrom]
           ,[ValidTo])
     
	SELECT  [EmployeeID]
           ,[ConcatName]
           ,[Age]
           ,[YearsOfExperience]
		   ,[Gender]
		   ,@NewLoadDate
		   ,@FutureDate
	FROM stage.DimEmployee
	WHERE EmployeeID in (SELECT EmployeeID
						  FROM stage.DimEmployee 
						  EXCEPT 
						  SELECT EmployeeID FROM edw.DimEmployee
						  WHERE ValidTo=99991231)


INSERT INTO ETL."LogUpdate" ("Table", "LastLoadDate") VALUES ('DimEmployee', @NewLoadDate)
go
/*	stop get new	*/



/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimEmployee')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231

/*	start get changed	*/
drop table if exists #tmp

SELECT [EmployeeID]
      ,[ConcatName]
      ,[Age]
      ,[YearsOfExperience]
	  ,[Gender]
  INTO #tmp
  FROM [stage].[DimEmployee] 
  EXCEPT
  SELECT [EmployeeID]
		,[Name]
		,[Age]
		,[YearsOfExperience]
		,[Gender]
  FROM edw.DimEmployee
  WHERE ValidTo=99991231
  EXCEPT
  SELECT [EmployeeID]
		,[ConcatName]
		,[Age]
		,[YearsOfExperience]
		,[Gender]
  FROM stage.DimEmployee WHERE EmployeeID in (SELECT EmployeeID from stage.DimEmployee 
												except
												select EmployeeID from edw.DimEmployee
												where ValidTo=99991231)

INSERT INTO [edw].[DimEmployee]
           ([EmployeeID]
           ,[Name]
           ,[Age]
           ,[YearsOfExperience]
		   ,[Gender]
           ,[ValidFrom]
           ,[ValidTo])
     
	SELECT  [EmployeeID]
           ,[ConcatName]
           ,[Age]
           ,[YearsOfExperience]
		   ,[Gender]
		   ,@NewLoadDate
		   ,@FutureDate
		FROM #tmp

update edw.DimEmployee
set ValidTo = @NewLoadDate-1
where EmployeeID in (select EmployeeID from #tmp) and edw.DimEmployee.ValidFrom<@NewLoadDate

drop table if exists #tmp

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimEmployee', @NewLoadDate)
go

/*	stop get changed	*/



/*		declare variables		*/
DECLARE @LastLoadDate int
SET @LastLoadDate = (SELECT MAX([LastLoadDate]) FROM etl."LogUpdate" WHERE "Table" = 'DimEmployee')

DECLARE @NewLoadDate int
SET @NewLoadDate = CONVERT(CHAR(8), GETDATE(), 112)

DECLARE @FutureDate int
SET @FutureDate = 99991231


/*	start get deleted	*/


update edw.DimEmployee
set ValidTo = @NewLoadDate-1
where EmployeeID in (select EmployeeID
					  from edw.DimEmployee
					  where EmployeeID in (select EmployeeID
											from edw.DimEmployee
											except 
											select EmployeeID
											from stage.DimEmployee))
					  and ValidTo=99991231

insert into etl.LogUpdate("Table", "LastLoadDate") values ('DimEmployee', @NewLoadDate)
go



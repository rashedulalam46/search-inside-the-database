-- =============================================
-- Author:		Rashedul Alam Rashed
-- Create date: January, 2022
-- Description:	Search a string inside the entire database
-- Execute dbo.SearchTheString 'john'
-- =============================================
CREATE PROCEDURE [dbo].[SearchTheString]	
	@SearchString NVARCHAR(200)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Create results table
	DECLARE @StringLocations table(
	  table_name NVARCHAR(1000),
	  FieldName NVARCHAR(1000),
	  FieldValue VARCHAR(8000)
	)

	-- Variable declaration
	DECLARE
	  @table_name varchar(1000),
	  @FieldName varchar(1000)


	SET @table_name = ''

	SET @SearchString = QUOTENAME('%' + @SearchString + '%','''')

	--For each table
	WHILE @table_name is not null
	BEGIN
	  SET @FieldName = ''
	  SET @table_name = (
		SELECT MIN(QUOTENAME(table_schema) + '.' + QUOTENAME(table_name))
		FROM INFORMATION_SCHEMA.TABLES
		where 
		  table_type = 'BASE TABLE' and
		  QUOTENAME(table_schema) + '.' + QUOTENAME(table_name) > @table_name and
		  OBJECTPROPERTY(OBJECT_ID(QUOTENAME(table_schema) + '.' + QUOTENAME(table_name)), 'IsMSShipped') = 0
	  )

	--For each string is Feld
	  WHILE (@table_name is not null) and (@FieldName is not null)
	  BEGIN
		SET @FieldName = (
		  SELECT MIN(QUOTENAME(column_name))
		  FROM INFORMATION_SCHEMA.COLUMNS
		  where 
			table_schema    = PARSENAME(@table_name, 2) and
			table_name  = PARSENAME(@table_name, 1) and
			data_type in ('char', 'varchar', 'nchar', 'nvarchar', 'text', 'ntext') and
			QUOTENAME(column_name) > @FieldName
		)

		--Search that Feld for the string supplied
		if @FieldName is not null
		BEGIN
		  insert into @StringLocations
		  exec(
			'SELECT ''' + @table_name + ''',''' + @FieldName + ''',' + @FieldName + 
			'FROM ' + @table_name + ' (nolock) ' +
			'where patindex(' + @SearchString + ',' + @FieldName + ') > 0'  
		  )
		END
	  END
	END
	--End of table loop
	--Return output 
	SELECT 
		table_name As TableName, 
		FieldName,
		FieldValue  
	FROM @StringLocations     
	
END

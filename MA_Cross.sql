USE [ncu_database]
GO
/****** Object:  StoredProcedure [dbo].[MA_Cross]    Script Date: 3/27/2022 11:14:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MA_Cross] 
	-- Add the parameters for the stored procedure here
	@MA1_input varchar(10),	
	@MA2_input varchar(10),
	@trend_input int,-- 1:cross up,-1:cross down
	@duration int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @date date
	DECLARE @id varchar(10)
	DECLARE @sqlText nvarchar(1000)
	DECLARE @ParmDefinition nvarchar(500) 
	SELECT @date=max(date) from stock_data 

	DECLARE @company varchar(10)
	DECLARE @i int
	DECLARE @MA1_value real
	DECLARE @MA2_value real
	DECLARE @MA1_prevalue real
	DECLARE @MA2_prevalue real
	CREATE Table #stock_temp(
		id int IDENTITY(1,1),
		date date Not Null,
		company varchar(10) Not Null,
		MA_1 real Not null,
		MA_2 real Not null
	)
	CREATE Table #stock(
		company varchar(10)
	)

	declare cur CURSOR LOCAL for
    select distinct company from stock_data

	open cur

	fetch next from cur into @id

	WHILE @@FETCH_STATUS = 0 BEGIN
		--execute your sproc on each row
	
		SET @sqlText = N'SELECT date, company,' + @MA1_input + ',' + @MA2_input + ' FROM dbo.stock_data WHERE date in (SELECT date FROM find_date( @date_input, @duration_input)) AND company = @id_input order by date'
		SET @ParmDefinition = N'@date_input date, @duration_input int, @id_input varchar(10)';
		DELETE FROM #stock_temp
		INSERT #stock_temp exec sp_executesql @sqlText, @ParmDefinition, @date_input=@date, @duration_input=@duration, @id_input=@id
	
		SELECT TOP(1) @i= id, @MA1_prevalue = MA_1, @MA2_prevalue = MA_2 FROM #stock_temp
		DELETE #stock_temp WHERE id = @i

		WHILE EXISTS(SELECT * FROM #stock_temp)
			BEGIN
				SELECT TOP(1) @i= id, @company = company, @MA1_value = MA_1, @MA2_value = MA_2 FROM #stock_temp

				IF (@trend_input=1 AND @MA1_prevalue < @MA2_prevalue AND @MA1_value > @MA2_value) OR
					(@trend_input=-1 AND @MA1_prevalue > @MA2_prevalue AND @MA1_value < @MA2_value)
					BEGIN
						INSERT INTO #stock (company)
						VALUES(@company)
						break
					END

				SET @MA1_prevalue=@MA1_value
				SET @MA2_prevalue=@MA2_value

				DELETE #stock_temp WHERE id = @i
			END

		fetch next from cur into @id
	END

	close cur
	deallocate cur
	SELECT * FROM #stock
END
GO

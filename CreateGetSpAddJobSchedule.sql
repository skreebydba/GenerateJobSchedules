SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Frank Gill
-- Create date: 2017-12-11
-- Description:	Creates a sp_add_jobschedule execution for reuse
-- =============================================
CREATE OR ALTER PROCEDURE GetSpAddJobSchedule 
	-- Add the parameters for the stored procedure here
	@jobname SYSNAME,
	@schedulename SYSNAME,
	@enabled TINYINT = 1,
	@occurs NVARCHAR(10), 
	@recurs NVARCHAR(27) = NULL,
	@runtime INT = NULL,
	@frequency INT = 1,
	@frequencyunit NVARCHAR(10) = N'HOUR',
	@starttime INT,
	@endtime INT,
	@startdate INT = NULL,
	@enddate INT = NULL,
	@noexec INT = 1
AS
BEGIN

BEGIN TRY

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/* Create temp table to calculate the @freq_interval parm for sp_add_jobschedule */

	DROP TABLE IF EXISTS #recurrence;

	CREATE TABLE #recurrence
	(rowid INT IDENTITY(1,1)
	,recurday NVARCHAR(3)
	,recurnum INT);

	/* Declare and initialize local variables 
	   NOTE: sp_add_jobschedule date format is YYYYMMDD and time format is HHMMMSS */

	DECLARE @sqlstr NVARCHAR(MAX),
	@freqtype INT,
	@freqinterval INT = 1,
	@freqsubdaytype INT = 1,
	@freqsubdayinterval INT = 0,
	@freqrelativeinterval INT = 0,
	@freqrecurrencefactor INT = 1, 
	@activestartdate INT = NULL,
	@activeenddate INT = NULL,
	@activestarttime INT = NULL,
	@activeendtime INT = NULL,
	@defaultstartdate INT = CAST(CAST(DATEPART(YYYY, CURRENT_TIMESTAMP) AS CHAR(4)) + CAST(DATEPART(MM, CURRENT_TIMESTAMP) AS CHAR(2)) + CAST(DATEPART(DD, CURRENT_TIMESTAMP) AS CHAR(2)) AS INT),
	@defaultenddate INT = 99991231,
	@defaultstarttime INT = 000000,
	@defaultendtime INT = 235959;

	/* The @recurs parm is pass in using the following format:
	   N'MON,TUE,WED,THU,FRI,SAT,SUN' 
	   Values passed in are parsed and inserted into the #recurrence temp table */

	INSERT INTO #recurrence
	(recurday)
	SELECT value
	FROM string_split(@recurs,',');

	/* Update the temp table with the associated hex value for each day */
	UPDATE #recurrence
	SET recurnum=(
	CASE 
		WHEN recurday=N'SUN' THEN 1
		WHEN recurday=N'MON' THEN 2
		WHEN recurday=N'TUE' THEN 4
		WHEN recurday=N'WED' THEN 8
		WHEN recurday=N'THU' THEN 16
		WHEN recurday=N'FRI' THEN 32
		WHEN recurday=N'SAT' THEN 64
	END);

	/* Set the date and time values for sp_add_jobschedule 
	   Use default values if parameters not passed in */		
	SELECT @activestartdate = ISNULL(@startdate, @defaultstartdate),
	@activeenddate = ISNULL(@enddate, @defaultenddate),
	@activestarttime = ISNULL(@starttime, @defaultstarttime),
	@activeendtime = ISNULL(@endtime, @defaultendtime);

	/* Check that the job exists and raise an error if it does not */
	IF(SELECT 1 FROM msdb.dbo.sysjobs WHERE [name] = @jobname) IS NULL
	BEGIN

		RAISERROR ('The @jobname input does not exist on this instance. Please check the job name and resubmit.', -- Message text.  
				   16, -- Severity.  
				   1 -- State.  
				   );  

	END;

	/* Check if the schedule already exists on the instance. If it does, raise an error. */
	IF(SELECT 1 FROM msdb.dbo.sysschedules WHERE [name] = @schedulename) IS NOT NULL
	BEGIN

		RAISERROR ('The @schedulename input already exists on this instance. 
					This procedure creates new schedules.  
					Please check the schedule name and resubmit.', -- Message text.  
				   16, -- Severity.  
				   1 -- State.  
				   );  

	END;

	/* Check to see if the job will run daily or weekly and set parameters.
	   If job is weekly and the @recurs parm is NULL, set @freqinterval to 127
	   which will run Monday-Sunday */
	IF UPPER(@occurs) = N'DAILY'
	BEGIN

		SELECT @freqtype = 4, @freqsubdayinterval = @frequency;

	END
	ELSE IF UPPER(@occurs) = N'WEEKLY'
	BEGIN

		SELECT @freqtype = 8;
		SELECT @freqinterval = ISNULL(SUM(recurnum), 127) FROM #recurrence;

	END

	/* If @runtime is passed in, set the schedule to execute once at the @runtime specified*/
	IF @runtime IS NOT NULL
	BEGIN
		
		SELECT @freqsubdaytype = 1, @activestarttime = @runtime, @activeendtime = @defaultendtime;

	END
	/* If @runtime is not passed in, check the @frequencyunit value and set @freqsubdaytype.
	   If it is not SECOND, MINUTE, or HOUR raise an error. */
	ELSE 
	BEGIN

		SELECT @freqsubdaytype =
		CASE
			WHEN @frequencyunit = N'SECOND' THEN 2
			WHEN @frequencyunit = N'MINUTE' THEN 4
			WHEN @frequencyunit = N'HOUR' THEN 8
			ELSE 99
		END, @freqsubdayinterval = @frequency;

		IF @freqsubdaytype = 99
		BEGIN
		    RAISERROR ('The @frequencyunit input is invalid. Please resubmit with a valid value: N''HOUR'', N''MINUTE'', N''SECOND''.', -- Message text.  
               16, -- Severity.  
               1 -- State.  
               );  
		END

		/* If @frequencyunit is seconds and the @freqsubdayinterval is less than 10, raise an error. */
		IF (@freqsubdaytype = 2) AND (@freqsubdayinterval < 10)
		BEGIN

		    RAISERROR ('For @frequencyunit = N''SECOND'' @frequency must be greater than or equal to 10. Please resubmit with a valid value.', -- Message text.  
               16, -- Severity.  
               1 -- State.  
               );
			     
		END

	END

	/* Generate the dynamic SQL string to add the job schedule. */
	SELECT @sqlstr = N'USE [msdb]
	GO
	DECLARE @schedule_id int
	EXEC msdb.dbo.sp_add_jobschedule @job_name=N''' + @jobname + ''', @name=N''' + @schedulename + ''', 
			@enabled=' + CAST(@enabled AS NVARCHAR(10)) + ', 
			@freq_type=' + CAST(@freqtype AS NVARCHAR(10)) + ', 
			@freq_interval=' + CAST(@freqinterval AS NVARCHAR(10)) + ', 
			@freq_subday_type=' + CAST(@freqsubdaytype AS NVARCHAR(10)) + ', 
			@freq_subday_interval=' + CAST(@freqsubdayinterval AS NVARCHAR(10)) + ', 
			@freq_relative_interval=' + CAST(@freqrelativeinterval AS NVARCHAR(10)) + ', 
			@freq_recurrence_factor=' + CAST(@freqrecurrencefactor AS NVARCHAR(10)) + ', 
			@active_start_date=' + CAST(@activestartdate AS NVARCHAR(10))+ ', 
			@active_end_date=' + CAST(@activeenddate AS NVARCHAR(10)) + ', 
			@active_start_time=' + CAST(@activestarttime AS NVARCHAR(10)) + ', 
			@active_end_time=' + CAST(@activeendtime AS NVARCHAR(10)) + ', @schedule_id = @schedule_id OUTPUT
	select @schedule_id';

	/* If @noexec is 0, execute the dynamic SQL. Otherwise print it. */
	IF @noexec = 0
	BEGIN

		EXEC sp_executesql @sqlstr;

	END
	ELSE
	BEGIN

		PRINT @sqlstr;

	END

END TRY
BEGIN CATCH

    DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  

    SELECT   
        @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE();  

    -- Use RAISERROR inside the CATCH block to return error  
    -- information about the original error that caused  
    -- execution to jump to the CATCH block.  
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  

END CATCH
END
GO


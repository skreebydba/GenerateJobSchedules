-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
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
	@jobname SYSNAME = N'IndexOptimize - USER_DATABASES',
	@schedulename SYSNAME = N'Index Maintenance Sunday 06:00',
	@enabled TINYINT = 1,
	@occurs NVARCHAR(10) = Daily, 
	@recurs NVARCHAR(27) = N'MON,WED,SAT',
	@runtime INT = NULL,
	@frequency INT = NULL,
	@frequencyunit NVARCHAR(10),
	@starttime INT = NULL,
	@endtime INT = NULL,
	@startdate INT = NULL,
	@enddate INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DROP TABLE IF EXISTS #recurrence;

	CREATE TABLE #recurrence
	(rowid INT IDENTITY(1,1)
	,recurday NVARCHAR(3)
	,recurnum INT);

	DECLARE @sqlstr NVARCHAR(MAX),
	@freqtype INT,
	@freqinterval INT = 1,
	@freqsubdaytype INT = 1,
	@freqsubdayinterval INT = 0,
	@freqrelativeinterval INT = 0,
	@freqrecurrencefactor INT = 1, 
	@activestartdate INT = 20171211,
	@activeenddate INT = 99991231,
	@activestarttime INT = 60000,
	@activeendtime INT = 235959;

	INSERT INTO #recurrence
	(recurday)
	SELECT value
	FROM string_split(@recurs,',');

	UPDATE #recurrence
	SET recurnum=(
	CASE 
		WHEN recurday=N'MON' THEN 1
		WHEN recurday=N'TUE' THEN 2
		WHEN recurday=N'WED' THEN 4
		WHEN recurday=N'THU' THEN 8
		WHEN recurday=N'FRI' THEN 16
		WHEN recurday=N'SAT' THEN 32
		WHEN recurday=N'SUN' THEN 64
	END);

	IF UPPER(@occurs) = N'DAILY'
	BEGIN

		SELECT @freqtype = 4;

	END
	ELSE IF UPPER(@occurs) = N'WEEKLY'
	BEGIN

		SELECT @freqtype = 8;
		SELECT @freqinterval = SUM(recurnum) FROM #recurrence;

	END

	IF @runtime IS NOT NULL
	BEGIN
		
		SELECT @freqsubdaytype = 1, @activestarttime = @runtime;

	END
	ELSE 
	BEGIN

		SELECT @freqsubdaytype =
		CASE
			WHEN @frequencyunit = N'MINUTE' THEN 4
			WHEN @frequencyunit = N'HOUR' THEN 8
		END, @freqsubdayinterval = @frequency;

		SELECT @freqsubdayinterval AS SubdayInterval;

	END

	SELECT @jobname AS JobName,
	@schedulename AS ScheduleName,
	@enabled AS [Enabled],
	@freqtype AS FreqType,
	@freqinterval AS FreqInterval,
	@freqsubdaytype AS FeqSubdayType,
	@freqsubdayinterval AS freqsubdayinterval,
	@freqrelativeinterval AS freqrelativeinterval,
	@freqrecurrencefactor AS freqrecurrencefactor,
	@activestartdate AS activestartdate,
	@activeenddate AS activeenddate,
	@activestarttime AS activestarttime,
	@activeendtime AS activeendtime;

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

	PRINT @sqlstr;

END
GO

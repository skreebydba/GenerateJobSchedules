USE [master]
GO

SET NOCOUNT ON;

DECLARE	@return_value int

/* This will create a schedule to execute the DatabaseBackup - USER_DATABASES - FULL from Ola Hallengren's
   Maintenance Solution every Sunday at 02:00 */
EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'WEEKLY', 
@recurs = N'SUN', 
@runtime = 020000,
@jobname = N'DatabaseBackup - USER_DATABASES - FULL', 
@schedulename = N'User DB Full Backup Sunday 02:00',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO

/* This will create a schedule to execute the DatabaseBackup - USER_DATABASES - DIFF from Ola Hallengren's
   Maintenance Solution Monday through Saturday at 02:00 */
DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'WEEKLY', 
@recurs = N'MON,TUE,WED,THU,FRI,SAT', 
@runtime = 020000,
@jobname = N'DatabaseBackup - USER_DATABASES - DIFF', 
@schedulename = N'User DB Diff Backup Monday-Saturday 02:00',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO

/* This will create a schedule to execute the DatabaseBackup - USER_DATABASES - LOG from Ola Hallengren's
   Maintenance Solution every 30 minutes */
DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'DAILY', 
@frequencyunit = N'MINUTE', 
@frequency = 30, 
@jobname = N'DatabaseBackup - USER_DATABASES - LOG', 
@schedulename = N'User DB Log Backup Every 30 Minutes',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO

/* This will create a schedule to execute the DatabaseBackup - SYSTEM_DATABASES - FULL from Ola Hallengren's
   Maintenance Solution every morning at 03:00 */
DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'WEEKLY', 
@recurs = N'MON,TUE,WED,THU,FRI,SAT,SUN', 
@runtime = 030000,
@jobname = N'DatabaseBackup - SYSTEM_DATABASES - FULL', 
@schedulename = N'System DB Full Backup Nightly 02:00',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO

/* This will create a schedule to execute the DatabaseIntegrityCheck - SYSTEM_DATABASES from Ola Hallengren's
   Maintenance Solution Sunday at 04:00 */
DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'WEEKLY', 
@recurs = N'SUN', 
@runtime = 040000,
@jobname = N'DatabaseIntegrityCheck - SYSTEM_DATABASES', 
@schedulename = N'System DB Integrity Check 04:00',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO

/* This will create a schedule to execute the DatabaseIntegrityCheck - USER_DATABASES from Ola Hallengren's
   Maintenance Solution every night at 23:00 */
DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'WEEKLY', 
@recurs = N'MON,TUE,WED,THU,FRI,SAT,SUN', 
@runtime = 230000,
@jobname = N'DatabaseIntegrityCheck - USER_DATABASES', 
@schedulename = N'User DB Integrity Check Nightly 23:00',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO

/* This will create a schedule to execute the IndexOptimize - USER_DATABASES from Ola Hallengren's
   Maintenance Solution every morning at 00:00 */
DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] 
@occurs = N'WEEKLY', 
@recurs = N'MON,TUE,WED,THU,FRI,SAT,SUN', 
@runtime = 000000,
@jobname = N'IndexOptimize - USER_DATABASES', 
@schedulename = N'User DB Index Optimize Nightly 00:00',
@noexec = 0;

SELECT	'Return Value' = @return_value

GO


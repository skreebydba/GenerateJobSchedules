USE [master]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[GetSpAddJobSchedule] @occurs = N'DAILY', @frequencyunit = N'HOUR', @frequency = 4;

SELECT	'Return Value' = @return_value

GO

CREATE FUNCTION [dbo].[ElapsedBDays] (@Start smalldatetime, @End smalldatetime)
RETURNS int 
AS
BEGIN
/*
Description:
 Function designed to calculate the number of business days (In hours)
between two dates.
*/
DECLARE 
 @Days int
 ,@WeekDays int
 ,@Holidays int
 ,@Hours int


SELECT @Hours = DATEDIFF(Hour,@Start,@End)
WHILE (DATEPART(WeekDay,@Start)-1) % 6 = 0
BEGIN
 SELECT @Start = DATEADD(Day,1,@Start)
 SELECT @Hours = @Hours - 24
END
WHILE (DATEPART(WeekDay,@End)-1) % 6 = 0
BEGIN
 SELECT @End = DATEADD(Day,1,@End)
 SELECT @Hours = @Hours - 24
END

SELECT @WeekDays = @Hours -ABS(DATEDIFF(Week,@End,@Start) * 48)


SELECT @Holidays = COUNT(*) FROM tblHolidays WHERE (HolidayDate BETWEEN @Start AND @End) 
AND DATEPART(Weekday,HolidayDate)-1 % 6 <> 0 *24

SELECT @Hours = @WeekDays - @Holidays
RETURN(@Hours)

END 
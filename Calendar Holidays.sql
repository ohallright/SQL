CREATE TABLE tblHolidays (
	HolidayDate DATETIME
	,HolidayName varchar (50)
)

INSERT INTO tblHolidays
SELECT 
DT as HolidayDate
,HolidayName as HolidayName
FROM [dbo].[Calendar]
WHERE [IsHoliday] = 1
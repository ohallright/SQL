--===== Drop and rebuild the Calendar table just to make reruns in SSMS easier
     IF OBJECT_ID('dbo.Calendar','U') IS NOT NULL
        DROP TABLE dbo.Calendar
;
GO
--===== Declare some obviously named variables
DECLARE @StartYear DATETIME
,       @EndYear   DATETIME
,       @TotalDays INT
;
--===== Preset the start and end years
 SELECT @StartYear = '2000'
,       @EndYear   = '2100'
,       @EndYear   = DATEADD(yy,1,@EndYear) -- Since we want ALL of the end year, add 1 to the end year.
,       @TotalDays = DATEDIFF(dd,@StartYear,@EndYear) -- Figure out the # of days we have NOT including the last day.
;
--=====================================================================================================================
--      Build the empty Calendar Table
--=====================================================================================================================
 CREATE TABLE dbo.Calendar
(
        DT          DATETIME    NOT NULL
,       DTNext      DATETIME    NOT NULL
,       DTInt       INT         NOT NULL
,       YY          SMALLINT    NOT NULL
,       MM          TINYINT     NOT NULL
,       DD          TINYINT     NOT NULL
,       DW          TINYINT     NOT NULL
,       ISOWk       TINYINT     NOT NULL
,       DWMonth     TINYINT     NOT NULL
,       IsWorkDay   TINYINT     NOT NULL
,       IsHoliday   TINYINT     NOT NULL
,       WD#Prev     INT         NOT NULL
,       WD#Next     INT         NOT NULL
,       HolidayName VARCHAR(50) NOT NULL
)
;
--=====================================================================================================================
--      Add the basic date information to the Calendar Table
--=====================================================================================================================
--===== Build the basis of the Calendar table
WITH
cteDates AS
( --=== Create all of the dates we need using a CROSS JOIN as a row source
     -- that I refer to as a "Pseudo-Cursor".
 SELECT TOP (@TotalDays)
        Date = DATEADD(dd,ROW_NUMBER() OVER (ORDER BY (SELECT NULL))-1,@StartYear)
   FROM sys.all_columns ac1, 
        sys.all_columns ac2
),
cteDateParts AS
( --=== Calculate the most of the important date parts that we'll search on
 SELECT DT     = Date
,       DTNext = DATEADD(dd,1,Date)
,       DTInt  = YEAR(Date)*10000 + MONTH(Date)*100 + DAY(Date)
,       YY     = YEAR(Date)
,       MM     = MONTH(Date)
,       DD     = DAY(Date)
,       DW     = DATEDIFF(dd,0,DATE)%7+1
,       ISOWk  = (DATEPART(dy,DATEADD(dd,DATEDIFF(dd,'17530101',Date)/7*7,'17530104'))+6)/7
   FROM cteDates
) --=== Calculate a few other date parts we couldn't calculate above and preset some rows we can't calculate yet.
 INSERT INTO dbo.Calendar
 SELECT DT,DTNext,DTInt,YY,MM,DD,DW,ISOWk
,       DWMonth     = ROW_NUMBER() OVER (PARTITION BY YY,MM,DW ORDER BY DT)
,       IsWorkDay   = CASE WHEN DW IN (6,7) THEN 0 ELSE 1 END
,       IsHoliday   = 0  --We'll calculate this later
,       WD#Prev     = 0  --We'll calculate this later
,       WD#Next     = 0  --We'll calculate this later
,       HolidayName = '' --We'll calculate this later 
   FROM cteDateParts
;
--=====================================================================================================================
--      Add the Holidays
--=====================================================================================================================
--===== New Years Day (Specific Day)
 UPDATE dbo.Calendar
    SET HolidayName = 'New Year''s Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE MM          = 1 
    AND DD          = 1
;
--===== Thanksgiving (4th Thursday in November)
 UPDATE dbo.Calendar
    SET HolidayName = 'Thanksgiving Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE MM          = 11
    AND DW          = 4
    AND DWMonth     = 4
;
/*
--===== Thanksgiving Friday (The day after ThanksGiving)
 UPDATE dbo.Calendar
    SET HolidayName = 'Thanksgiving Friday',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE DT IN
            (--==== Finds ThanksGiving and adds a day
             SELECT DATEADD(dd,1,DT)
               FROM dbo.Calendar
              WHERE MM      = 11
                AND DW      = 4
                AND DWMonth = 4
            )
;
*/
--===== Christmas (Specific Day)
 UPDATE dbo.Calendar
    SET HolidayName = 'Christmas Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE MM          = 12 
    AND DD          = 25
;
/*
--===== Christmas Eve (Specific Day only on weekdays)
 UPDATE dbo.Calendar
    SET HolidayName = 'Christmas Eve',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE MM          = 12 
    AND DD          = 24
    AND DW     NOT IN (6,7)
;
*/
--===== American Independence Day (Specific Day)
 UPDATE dbo.Calendar
    SET HolidayName = 'Independance Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE MM          = 7 
    AND DD          = 4
;
--===== Memorial Day (Last Monday of May) could be 4th or 5th Monday of the month.
 UPDATE dbo.Calendar
    SET HolidayName = 'Memorial Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
   FROM dbo.Calendar
  WHERE DT IN 
            (--=== Finds first Monday of June and subtracts a week
             SELECT DATEADD(wk,-1,DT)
               FROM dbo.Calendar
              WHERE MM      = 6
                AND DW      = 1
                AND DWMonth = 1
            )
;
--===== Labor Day (First Monday in September)
 UPDATE dbo.Calendar
    SET HolidayName = 'Labor Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE MM          = 9
    AND DW          = 1
    AND DWMonth     = 1
;
--===== MLK jr Day (Third Monday in Jan)
 UPDATE dbo.Calendar
    SET HolidayName = 'MLK Jr Day',
        IsWorkDay   = 0,
        IsHoliday   = 1
  WHERE DT IN
              (--=== Finds third Monday of Jan 
             SELECT DATEADD(wk,2,DT)
               FROM dbo.Calendar
              WHERE MM      = 1
                AND DD      = 1
                AND DWMonth = 1
            )
;
--=====================================================================================================================
--      Update Holidays that occur on the weekend.
--      If the holiday occurs on Saturday, mark the Friday before as a holiday.
--      If the holiday occurs on Sunday, mark the Monday after as a holiday.
--      When either occurs, at the notation '(Observed)' to the holiday name.
--=====================================================================================================================
 UPDATE cal
    SET HolidayName = d.MovedHolidayName,
        IsWorkday   = 0,
        IsHoliday   = 1
   FROM dbo.Calendar cal
  INNER JOIN
        (
         SELECT MovedDate        = CASE WHEN DW = 6 THEN DATEADD(dd,-1,DT) ELSE DATEADD(dd,+1,DT) END,
                MovedHolidayName = HolidayName + ' (Observed)'
           FROM dbo.Calendar
          WHERE IsHoliday = 1
            AND DW IN (6,7)
        ) d
     ON cal.DT = d.MovedDate
;
--=====================================================================================================================
--      Now that all of the variable length columns have been calculated, build the clustered index and pack the
--      table as tightly as possible just to help performance a bit when the clustered index is used.
--=====================================================================================================================
  ALTER TABLE dbo.Calendar
    ADD CONSTRAINT PK_Calendar PRIMARY KEY CLUSTERED (DT) WITH FILLFACTOR = 100
;
--=====================================================================================================================
--      Calculate "running" workdays as a "WorkDayNumber" (WD#).
--=====================================================================================================================
--===== Calculate the running workday numbers excluding weekends and holidays
WITH
cteEnumerate AS
(
 SELECT WD# = ROW_NUMBER() OVER (ORDER BY DT)
,       WD#Prev
,       WD#Next
   FROM dbo.Calendar
  WHERE IsWorkDay = 1
)
 UPDATE cteEnumerate
    SET WD#Prev = WD#,
        WD#Next = WD#
;
--===== "Smear" the "last" workday numbers just prior to groups of non-workdays "down"
     -- into the non-workdays. The update ripples back through both CTEs to pull this 
     -- off and it's very quick. 
WITH 
cteGroup AS 
( --=== This creates groupings of the non-workdays by subtracting an ascending
     -- number from the ascending non-workday dates. The grouping dates don't mean
     -- anything... they just form groups of adjacent non-workdays.
 SELECT DT
,       PrevWorkDayGroup = DATEADD(dd,-ROW_NUMBER() OVER (ORDER BY DT),DT)
,       WD#Prev
   FROM dbo.Calendar
  WHERE IsWorkDay = 0
),
cteDates AS
( --=== This numbers the dates within each group and then subtracts that number from the DT
     -- column to come up with the last workday that occurred just before the non-workday group.
 SELECT DT, PrevWorkDayGroup
,       PrevWorkDayDate = DATEADD(dd,-DENSE_RANK()OVER(PARTITION BY PrevWorkDayGroup ORDER BY DT),DT)
,       WD#Prev
   FROM cteGroup
) --=== This joins the dates we came up with for each grouping above back to the calendar table
     -- and updates the "workday" column with the related workday we find for each date.
 UPDATE d
    SET d.WD#Prev = c.WD#Prev
   FROM cteDates d
   JOIN dbo.Calendar c ON c.DT = d.PrevWorkDayDate
;
--===== "Smear" the "next" workday numbers just after groups on non-workdays "up"
     -- into the non-workdays. The update ripples back through both CTEs to pull this 
     -- off and it's very quick. 
WITH 
cteGroup AS 
( --=== This creates groupings of the non-workdays by adding an ascending
     -- number to the descending non-workday dates. The grouping dates don't mean
     -- anything... they just form groups of adjacent non-workdays.
 SELECT DT
,       NextWorkDayGroup = DATEADD(dd,ROW_NUMBER() OVER (ORDER BY DT DESC),DT)
,       WD#Next
   FROM dbo.Calendar
  WHERE IsWorkDay = 0 
)
,
cteDates AS
( --=== This numbers the dates within each group and then subtracts that number from the DT
     -- column to come up with the "next" workday that occurred just after the non-workday group.
 SELECT DT, NextWorkDayGroup
,       NextWorkDayDate = DATEADD(dd,DENSE_RANK()OVER(PARTITION BY NextWorkDayGroup ORDER BY DT DESC),DT)
,       WD#Next
   FROM cteGroup
) --=== This joins the dates we came up with for each grouping above back to the calendar table
     -- and updates the "workday" column with the related workday we find for each date.
 UPDATE d
    SET d.WD#Next = c.WD#Next
   FROM cteDates d
   JOIN dbo.Calendar c ON c.DT = d.NextWorkDayDate
;
--===== Add an index for workday based date differences
 CREATE INDEX IX_Calendar_WD#Next
     ON dbo.Calendar (WD#Next ASC)
;

USE [TeamMate]
GO
/****** Object:  UserDefinedFunction [dbo].[udf_StripHTML]    Script Date: 1/16/2018 10:12:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[udf_StripHTML] (@HTMLText VARCHAR(MAX))

RETURNS VARCHAR(MAX) 

AS

BEGIN

--===========================================================================--
	/**
					This section strips out the <> tags
																		**/
--===========================================================================--

    DECLARE @TagStart INT
    DECLARE @TagEnd INT
    DECLARE @TagLength INT
    
    SET @TagStart = CHARINDEX('<',@HTMLText)
    SET @TagEnd = CHARINDEX('>',@HTMLText,CHARINDEX('<',@HTMLText))
    SET @TagLength = (@TagEnd - @TagStart) + 1
    
    WHILE @TagStart > 0 AND @TagEnd > 0 AND @TagLength > 0
    
		BEGIN
			
			SET @HTMLText = STUFF(@HTMLText,@TagStart,@TagLength,'')
			SET @TagStart = CHARINDEX('<',@HTMLText)
			SET @TagEnd = CHARINDEX('>',@HTMLText,CHARINDEX('<',@HTMLText))
			SET @TagLength = (@TagEnd - @TagStart) + 1
			
		END
		
--===========================================================================--
	/**
					This section strips out the {} tags
																		**/
--===========================================================================--
		
	SET @TagStart = CHARINDEX('{',@HTMLText)
    SET @TagEnd = CHARINDEX('}',@HTMLText,CHARINDEX('{',@HTMLText))
    SET @TagLength = (@TagEnd - @TagStart) + 1
    
    WHILE @TagStart > 0 AND @TagEnd > 0 AND @TagLength > 0    
		BEGIN			
			SET @HTMLText = STUFF(@HTMLText,@TagStart,@TagLength,'')
			SET @TagStart = CHARINDEX('{',@HTMLText)
			SET @TagEnd = CHARINDEX('}',@HTMLText,CHARINDEX('}',@HTMLText))
			SET @TagLength = (@TagEnd - @TagStart) + 1
			
		END

--MISC cuts
	SET @TagStart = CHARINDEX('P',@HTMLText)
    SET @TagEnd = CHARINDEX('.TableNormal',@HTMLText,CHARINDEX('P',@HTMLText))
    SET @TagLength = (@TagEnd - @TagStart) + 1
    
    WHILE @TagStart > 0 AND @TagEnd > 0 AND @TagLength > 0
    
		BEGIN
			
			SET @HTMLText = STUFF(@HTMLText,@TagStart,@TagLength,'')
			SET @TagStart = CHARINDEX('P',@HTMLText)
			SET @TagEnd = CHARINDEX('.TableNormal',@HTMLText,CHARINDEX('P',@HTMLText))
			SET @TagLength = (@TagEnd - @TagStart) + 1
			
		END


	SET @TagStart = CHARINDEX('.ListParagraphCharacter',@HTMLText)
    SET @TagEnd = CHARINDEX('.1Char',@HTMLText,CHARINDEX('.ListParagraphCharacter',@HTMLText))
    SET @TagLength = (@TagEnd - @TagStart) + 1
    
    WHILE @TagStart > 0 AND @TagEnd > 0 AND @TagLength > 0
    
		BEGIN
			
			SET @HTMLText = STUFF(@HTMLText,@TagStart,@TagLength,'')
			SET @TagStart = CHARINDEX('.ListParagraphCharacter',@HTMLText)
			SET @TagEnd = CHARINDEX('.1Char',@HTMLText,CHARINDEX('.ListParagraphCharacter',@HTMLText))
			SET @TagLength = (@TagEnd - @TagStart) + 1
			
		END
		    
	SET @HTMLText = REPLACE(@HTMLText, '._tgc', '')
--underscores
	SET @TagStart = CHARINDEX('_',@HTMLText)
    SET @TagEnd = CHARINDEX(' ',@HTMLText,CHARINDEX('_',@HTMLText))
    SET @TagLength = (@TagEnd - @TagStart) + 1
    
    WHILE @TagStart > 0 AND @TagEnd > 0 AND @TagLength > 0
    
		BEGIN
			
			SET @HTMLText = STUFF(@HTMLText,@TagStart,@TagLength,'')
			SET @TagStart = CHARINDEX('_',@HTMLText)
			SET @TagEnd = CHARINDEX(' ',@HTMLText,CHARINDEX('_',@HTMLText))
			SET @TagLength = (@TagEnd - @TagStart) + 1
			
		END

	SET @HTMLText = REPLACE(@HTMLText, '.ListParagraphCharacter', '')
	SET @HTMLText = REPLACE(@HTMLText, '.ListParagraphParagraph', '')
	SET @HTMLText = REPLACE(@HTMLText, '.ListParagraph', '')
	SET @HTMLText = REPLACE(@HTMLText, 'TableNormal', '')
	SET @HTMLText = REPLACE(@HTMLText, 'Untitled', '')
	SET @HTMLText = REPLACE(@HTMLText, '1Char', '')
	SET @HTMLText = REPLACE(@HTMLText, 'Char', '')
	SET @HTMLText = REPLACE(@HTMLText, '.BodyTextReport', '')
	SET @HTMLText = REPLACE(@HTMLText, '.DefaultParagraphFont', '')
	SET @HTMLText = REPLACE(@HTMLText, '.BodyTextReportChar', '')
	SET @HTMLText = REPLACE(@HTMLText, '.FISBODYCOPY', '')
	SET @HTMLText = REPLACE(@HTMLText, '.NoSpacing', '')
	SET @HTMLText = REPLACE(@HTMLText, '.FISBULLET', '')
	SET @HTMLText = REPLACE(@HTMLText, '.Default', '')
	SET @HTMLText = REPLACE(@HTMLText, ',SubHeading1.1.1', '')
	SET @HTMLText = REPLACE(@HTMLText, ',SubHeading1.1.', '')
	SET @HTMLText = REPLACE(@HTMLText, char(149), '')
	
	SET @HTMLText = REPLACE(@HTMLText, '.s', '')
	SET @HTMLText = REPLACE(@HTMLText, '.p', '')
	SET @HTMLText = REPLACE(@HTMLText, '.tbl', '')
	SET @HTMLText = REPLACE(@HTMLText, '.tr', '')
	SET @HTMLText = REPLACE(@HTMLText, '.tc', '')
	SET @HTMLText = REPLACE(@HTMLText, 'B&amp;P', '')

	
  
--===========================================================================--
	/**
					This section replaces the &nbsp;
																		**/
--===========================================================================--
		
	SELECT @HTMLText = REPLACE(@HTMLText, '&nbsp;', '')
	
	SET @HTMLText = REPLACE(@HTMLText, CHAR(10), ' ')
	SET @HTMLText = REPLACE(@HTMLText, CHAR(13), ' ')
	SET @HTMLText = REPLACE(@HTMLText, CHAR(32), ' ')


    RETURN LTRIM(RTRIM(@HTMLText))
    
END


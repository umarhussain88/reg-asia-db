CREATE PROCEDURE [etl].[p_InsertDimCalendar]
	@jobKey	int
AS
BEGIN

	/* ==================================================================================================================
	Description:	Rebuilds the Calendar Dim
	================================================================================================================== */

    SET NOCOUNT ON;							-- Eliminate any dataset counts
	SET DATEFORMAT DMY;						-- Set dateformat for correct string interpretation
	SET DATEFIRST 1;						-- Set which day is the first day of week (1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun)

    DECLARE @jobLogKey	int				-- Identity for Job Log Table
    ,		@section	nvarchar(2048)	-- document your steps by setting this variable
	,       @proc		sysname;        -- Name of this procedure
	SET     @proc		= '[etl].[p_InsertDimCalendar]';

	-- Log the start time of the Procedure
    EXEC [etl_audit].[p_InsertJobLog] @procName = @proc, @jobKey = @jobKey, @jobLogKey = @jobLogKey OUTPUT;

    BEGIN TRY
			-- Declare variables
			DECLARE @FirstDate                      date
			,		@LastDate                       date
			,		@CurrentReportingDate			date
			,		@CurrentReportingMonth			int
			,		@CurrentReportingYear			int
			,		@UnspecifiedDate				date
		
			-- Set the date range to generate based on the configuration and the current year.
			SET @FirstDate = (SELECT [CalendarStartDate] FROM [etl_config].[Configuration]);
			SET @LastDate =	(SELECT DATEADD(YEAR, 2, CAST('31/12/'+ DATENAME(YYYY, GETDATE()) AS date)));

			-- Assume current reporting date is yesterday. May require modification for individual projects.
			-- For example, If processing is weekly rather than nightly, the requirement may be different.
			-- This is used to set the current status (Past/Current/Future) of all the time period attributes
			SELECT	@CurrentReportingDate = DATEADD(DAY, -1, GETDATE())
			,		@CurrentReportingMonth = DATEPART(YEAR, @CurrentReportingDate) * 100 + DATEPART(MONTH, @CurrentReportingDate)
			,		@CurrentReportingYear = DATEPART(YEAR, @CurrentReportingDate);

			-- For SSAS tabular the dates should be contiguous, so use the day before the first date as unknown member.
			SET @UnspecifiedDate = DATEADD(DAY, -1, @FirstDate);

		SET @section = 'Insert calendar records'
		EXEC [etl_audit].[p_UpdateJobLog_EndSection] @section = @section, @jobLogKey = @jobLogKey OUTPUT;
		
			WITH a(n)		AS (SELECT 1 UNION ALL SELECT 1)
				,b(n)		AS (SELECT 1 FROM a CROSS JOIN a t2)
				,c(n)		AS (SELECT 1 FROM b CROSS JOIN b t2)
				,d(n)		AS (SELECT 1 FROM c CROSS JOIN c t2)
				,e(n)		AS (SELECT 1 FROM d CROSS JOIN d t2)
				,N(n)		AS (SELECT ROW_NUMBER() OVER (ORDER BY n) -1 FROM e)
				,DateRange	AS (SELECT	DATEADD(DAY, N, @FirstDate) AS [ActualDate]
								FROM	N
								WHERE	DATEADD(DAY, N, @FirstDate) <= @LastDate
								UNION ALL
								SELECT	@UnspecifiedDate AS [ActualDate]
								)
				,DateParts	AS (SELECT	[ActualDate]
								,		DATEPART(DW, [ActualDate])				AS [WeekDayNumber]
								,		LEFT(DATENAME(WEEKDAY, [ActualDate]),3)	AS [WeekDayNameShort]
								,		DATENAME(WEEKDAY, [ActualDate])			AS [WeekDayNameFull]
								,		DATEPART(ISO_WEEK, [ActualDate])		AS [WeekNumber]
								,		DATEPART(DAY, [ActualDate])				AS [MonthDayNumber]
								,		DATEPART(MONTH, [ActualDate])			AS [MonthNumber]
								,		LEFT(DATENAME(MONTH, [ActualDate]), 3)	AS [MonthNameShort]
								,		DATENAME(MONTH, [ActualDate])			AS [MonthNameFull]
								,		DATEPART(QUARTER, [ActualDate])			AS [QuarterNumber]
								,		DATEPART(YEAR, [ActualDate])			AS [YearNumber]
								FROM	DateRange
								)
				,DateNames	AS (SELECT		dk.[DateKey]
								,			dp.[ActualDate]
								,			pn1.[DisplayDate]
								,			dp.[WeekDayNumber]
								,			dp.[WeekDayNameShort]
								,			dp.[WeekDayNameFull]
								,			dp.[WeekNumber]
								,			pn1.[WeekKey]
								,			pn2.[WeekKeyName]
								,			pn1.[WeekdayStatus]
								,			pn1.[WeekdayStatusName]
								,			dp.[MonthDayNumber]
								,			dp.[MonthNumber]
								,			pn1.[MonthKey]
								,			dp.[MonthNameShort]
								,			dp.[MonthNameFull]
								,			pn2.[MonthKeyName]
								,			dp.[QuarterNumber]
								,			pn1.[QuarterKey]
								,			pn1.[QuarterName]
								,			pn2.[QuarterKeyCode]
								,			pn2.[QuarterKeyName]
								,			dp.[YearNumber]
								,			pn1.[YearNameShort]
								,			pn1.[YearNameFull]
								,			os.[OffsetWeekCount]
								,			os.[OffsetMonthCount]
								,			os.[OffsetQuarterCount]
								,			os.[OffsetYearCount]
								FROM		DateParts dp
								CROSS APPLY (SELECT CASE	WHEN dp.[ActualDate] = @UnspecifiedDate THEN -1
															ELSE CAST(CONVERT(nvarchar(8),dp.[ActualDate],112) AS int) 
															END AS [DateKey]
											) dk
								CROSS APPLY (SELECT CONVERT(nvarchar(20), dp.[ActualDate], 106)														AS [DisplayDate]
											,		CASE WHEN dp.[WeekDayNameShort] IN ('Sat', 'Sun') THEN 0 ELSE 1 END								AS [WeekdayStatus]
											,		CASE WHEN dp.[WeekDayNameShort] IN ('Sat', 'Sun') THEN 'Weekend' ELSE 'Weekday' END				AS [WeekdayStatusName]
											,		dp.[YearNumber] * 100 + dp.[WeekNumber]															AS [WeekKey]
											,		dp.[YearNumber] * 100 + dp.[MonthNumber]														AS [MonthKey]
											,		dp.[YearNumber] * 10 +  dp.[QuarterNumber]														AS [QuarterKey]
											,		'Q' + CAST(dp.[QuarterNumber] AS char(1))														AS [QuarterName]
											,		RIGHT(CAST(dp.[YearNumber] AS char(4)),2)														AS [YearNameShort]
											,		CAST(dp.[YearNumber] AS char(4))																AS [YearNameFull]
											) pn1
								CROSS APPLY (SELECT 'wk' + RIGHT('0' + RTRIM(CAST(dp.[WeekNumber] AS char(2))), 2)	+ '-' + pn1.[YearNameFull]		AS [WeekKeyName]
											,		dp.[MonthNameShort] + '''' + pn1.[YearNameShort]												AS [MonthKeyName]
											,		pn1.[YearNameFull] + 'Q' + CAST(dp.[QuarterNumber] AS char(1))									AS [QuarterKeyCode]
											,		'Q' + CAST(dp.[QuarterNumber] AS char(1))						+ '-' + pn1.[YearNameFull]		AS [QuarterKeyName]
											) pn2
								CROSS APPLY (SELECT DATEDIFF(WEEK	,@CurrentReportingDate	,DATEADD(DAY, 7-1, dp.[ActualDate])		)				AS [OffsetWeekCount] --DATEDIFF doesn't respect DATEFISRT
											,		DATEDIFF(MONTH	,@CurrentReportingDate	,dp.[ActualDate]						)				AS [OffsetMonthCount]
											,		DATEDIFF(QUARTER,@CurrentReportingDate	,dp.[ActualDate]						)				AS [OffsetQuarterCount]
											,		DATEDIFF(YEAR	,@CurrentReportingDate	,dp.[ActualDate]						)				AS [OffsetYearCount]
											) os
								)
				,src		AS (SELECT		dn.[DateKey]
								,			dn.[ActualDate]
								,			dn.[DisplayDate]
								,			dn.[WeekDayNumber]
								,			dn.[WeekDayNameShort]
								,			dn.[WeekDayNameFull]
								,			dn.[WeekNumber]
								,			dn.[WeekKey]
								,			dn.[WeekKeyName]
								,			dn.[WeekdayStatus]
								,			dn.[WeekdayStatusName]
								,			dn.[MonthDayNumber]
								,			dn.[MonthNumber]
								,			dn.[MonthKey]
								,			dn.[MonthNameShort]
								,			dn.[MonthNameFull]
								,			dn.[MonthKeyName]
								,			dn.[QuarterNumber]
								,			dn.[QuarterKey]
								,			dn.[QuarterName]
								,			dn.[QuarterKeyCode]
								,			dn.[QuarterKeyName]
								,			dn.[YearNumber]
								,			dn.[YearNameShort]
								,			dn.[YearNameFull]
								,			dn.[OffsetWeekCount]
								,			dn.[OffsetMonthCount]
								,			dn.[OffsetQuarterCount]
								,			dn.[OffsetYearCount]
								,			ch.[ChangeHash]
								FROM		DateNames dn
								CROSS APPLY (SELECT CAST(HASHBYTES	( 'SHA2_512'
																	, ISNULL(CAST(dn.[ActualDate] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[DisplayDate] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekDayNumber] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekDayNameShort] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekDayNameFull] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekNumber] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekKey] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekKeyName] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekdayStatus] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[WeekdayStatusName] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[MonthDayNumber] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[MonthNumber] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[MonthKey] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[MonthNameShort] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[MonthNameFull] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[MonthKeyName] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[QuarterNumber] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[QuarterKey] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[QuarterName] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[QuarterKeyCode] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[QuarterKeyName] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[YearNumber] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[YearNameShort] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[YearNameFull] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[OffsetWeekCount]  AS nvarchar), '')
																	+ ISNULL(CAST(dn.[OffsetMonthCount] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[OffsetQuarterCount] AS nvarchar), '')
																	+ ISNULL(CAST(dn.[OffsetYearCount] AS nvarchar), '')
																	) AS binary(64)
														) AS [ChangeHash]
											) ch
								)

			MERGE		[dim].[Calendar] AS tgt
			USING		src
			ON			tgt.[DateKey]	= src.[DateKey]

			WHEN MATCHED AND tgt.[ChangeHash] != src.[ChangeHash] THEN
				UPDATE
				SET		[ActualDate]			= src.[ActualDate]
				,		[DisplayDate]			= src.[DisplayDate]
				,		[WeekDayNumber]			= src.[WeekDayNumber]
				,		[WeekDayNameShort]		= src.[WeekDayNameShort]
				,		[WeekDayNameFull]		= src.[WeekDayNameFull]
				,		[WeekNumber]			= src.[WeekNumber]
				,		[WeekKey]				= src.[WeekKey]
				,		[WeekKeyName]			= src.[WeekKeyName]
				,		[WeekdayStatus]			= src.[WeekdayStatus]
				,		[WeekdayStatusName]		= src.[WeekdayStatusName]
				,		[MonthDayNumber]		= src.[MonthDayNumber]
				,		[MonthNumber]			= src.[MonthNumber]
				,		[MonthKey]				= src.[MonthKey]
				,		[MonthNameShort]		= src.[MonthNameShort]
				,		[MonthNameFull]			= src.[MonthNameFull]
				,		[MonthKeyName]			= src.[MonthKeyName]
				,		[QuarterNumber]			= src.[QuarterNumber]
				,		[QuarterKey]			= src.[QuarterKey]
				,		[QuarterName]			= src.[QuarterName]
				,		[QuarterKeyCode]		= src.[QuarterKeyCode]
				,		[QuarterKeyName]		= src.[QuarterKeyName]
				,		[YearNumber]			= src.[YearNumber]
				,		[YearNameShort]			= src.[YearNameShort]
				,		[YearNameFull]			= src.[YearNameFull]
				,		[OffsetWeekCount]		= src.[OffsetWeekCount]
				,		[OffsetMonthCount]		= src.[OffsetMonthCount]
				,		[OffsetQuarterCount]	= src.[OffsetQuarterCount]
				,		[OffsetYearCount]		= src.[OffsetYearCount]
				,		[ChangeHash]			= src.[ChangeHash]
				,		[UpdatedJobKey]			= @jobKey

			WHEN NOT MATCHED THEN
				INSERT 	
				(		[DateKey]
				,		[ActualDate]
				,		[DisplayDate]
				,		[WeekDayNumber]
				,		[WeekDayNameShort]
				,		[WeekDayNameFull]
				,		[WeekNumber]
				,		[WeekKey]
				,		[WeekKeyName]
				,		[WeekdayStatus]
				,		[WeekdayStatusName]
				,		[MonthDayNumber]
				,		[MonthNumber]
				,		[MonthKey]
				,		[MonthNameShort]
				,		[MonthNameFull]
				,		[MonthKeyName]
				,		[QuarterNumber]
				,		[QuarterKey]
				,		[QuarterName]
				,		[QuarterKeyCode]
				,		[QuarterKeyName]
				,		[YearNumber]
				,		[YearNameShort]
				,		[YearNameFull]
				,		[OffsetWeekCount]
				,		[OffsetMonthCount]
				,		[OffsetQuarterCount]
				,		[OffsetYearCount]
				,		[ChangeHash]
				,		[CreatedJobKey]
				,		[UpdatedJobKey]
				)
				VALUES
				(		src.[DateKey]
				,		src.[ActualDate]
				,		src.[DisplayDate]
				,		src.[WeekDayNumber]
				,		src.[WeekDayNameShort]
				,		src.[WeekDayNameFull]
				,		src.[WeekNumber]
				,		src.[WeekKey]
				,		src.[WeekKeyName]
				,		src.[WeekdayStatus]
				,		src.[WeekdayStatusName]
				,		src.[MonthDayNumber]
				,		src.[MonthNumber]
				,		src.[MonthKey]
				,		src.[MonthNameShort]
				,		src.[MonthNameFull]
				,		src.[MonthKeyName]
				,		src.[QuarterNumber]
				,		src.[QuarterKey]
				,		src.[QuarterName]
				,		src.[QuarterKeyCode]
				,		src.[QuarterKeyName]
				,		src.[YearNumber]
				,		src.[YearNameShort]
				,		src.[YearNameFull]
				,		src.[OffsetWeekCount]
				,		src.[OffsetMonthCount]
				,		src.[OffsetQuarterCount]
				,		src.[OffsetYearCount]
				,		src.[ChangeHash]
				,		@jobKey
				,		@jobKey
				);
				
    END TRY

    BEGIN CATCH

		-- Log the error and raise it again
		EXEC [etl_audit].[p_LogAndRaiseSqlError] @jobLogKey = @jobLogKey;

    END CATCH

    -- Log the end of the Procedure Run, success or otherwise    
    EXEC [etl_audit].[p_UpdateJobLog_EndProcedure] @jobLogKey = @jobLogKey;

END
CREATE VIEW [etl_audit].[v_JobLog]
AS 

SELECT		jl.[JobLogKey]
,			jl.[JobKey]
,			DENSE_RANK() 
					OVER (ORDER BY jl.[JobKey] DESC) AS [JobSeqD]
,			jl.[Procedure]
,			jl.[StepNo]
,			jl.[Section]
,			er.[ErrorMessage]
,			jl.[StartTime]
,			jl.[EndTime]
,			DATEDIFF(SECOND
					,jl.[StartTime]
					,ISNULL	(jl.[EndTime]
							,GETDATE()
							)
					) AS ElapsedSeconds
,			CONVERT (char(8)
					,DATEADD(SECOND
							,DATEDIFF	(SECOND
										,jl.[StartTime]
										,ISNULL	(jl.[EndTime]
												,GETDATE()
												)
										)
							,'00:00'
							)
					,108
					) AS ElapsedTime
FROM		[etl_audit].[JobLog] jl
LEFT JOIN	[etl_audit].[Error] er
ON			jl.[ErrorKey] = er.[ErrorKey]
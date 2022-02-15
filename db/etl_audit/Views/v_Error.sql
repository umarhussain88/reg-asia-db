CREATE VIEW [etl_audit].[v_Error]
AS

SELECT		jl.[JobKey]
,			DENSE_RANK() 
					OVER (ORDER BY jl.[JobKey] DESC) AS [JobSeqD]
,			jl.[Procedure]
,			jl.[Section]
,			e.[ErrorKey]
,			e.[ErrorMessage]
,			e.[UserName]
,			e.[DateCreated]
FROM		[etl_audit].[Error] e
LEFT JOIN	[etl_audit].[JobLog] jl
ON			e.[ErrorKey] = jl.[ErrorKey]
GO

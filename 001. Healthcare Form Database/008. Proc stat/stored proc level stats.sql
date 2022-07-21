USE PatientEnrollment
GO

SELECT OBJECT_ID, 
	OBJECT_NAME(OBJECT_ID) AS objectName, 
	cached_time, 
	last_execution_time, 
	execution_count, 
	total_worker_time, 
	total_elapsed_time, 
	last_elapsed_time, 
	min_elapsed_time, 
	max_elapsed_time 
	FROM sys.dm_exec_procedure_stats 
	WHERE database_id = DB_ID() 
	AND
	OBJECT_ID IN 
	(
		SELECT OBJECT_ID FROM sys.sql_modules WHERE uses_native_compilation = 1
	) 
	ORDER BY total_worker_time DESC
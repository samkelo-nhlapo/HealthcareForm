USE HealthcareForm
GO

-- This table handles errors that are raised during program execution 

CREATE TABLE Exceptions.Errors
	(
		ExceptionsID INT NOT NULL PRIMARY KEY IDENTITY (1,1),
		UserName VARCHAR (250) NOT NULL, 
		ErrorSchema VARCHAR (250) NOT NULL, 
		ErrorProcedure VARCHAR (250) NOT NULL, 
		ErrorNumber INT NOT NULL, 
		ErrorState INT NOT NULL, 
		ErrorSeverity INT NOT NULL, 
		ErrorLine INT NOT NULL, 
		ErrorMessage VARCHAR (500) NOT NULL, 
		ErrorDateTime DATETIME NOT NULL
	)
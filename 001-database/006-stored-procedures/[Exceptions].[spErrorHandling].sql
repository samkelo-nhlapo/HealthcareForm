USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Centralized error sink used by the legacy SQL CRUD procedures.
-- Messages are trimmed here to fit the Exceptions.Errors table contract.
CREATE OR ALTER PROC [Exceptions].[spErrorHandling]
(
    @UserName VARCHAR(200),
    @ErrorSchema VARCHAR(200),
    @ErrorProc VARCHAR(200),
    @ErrorNumber INT,
    @ErrorState INT,
    @ErrorSeverity INT,
    @ErrorLine INT,
    @ErrorMessage VARCHAR(MAX),
    @ErrorDateTime DATETIME
)
AS
BEGIN
    INSERT INTO Exceptions.Errors
    (
        UserName,
        ErrorSchema,
        ErrorProcedure,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorMessage,
        ErrorDateTime
    )
    VALUES
    (
        @UserName, @ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState,
        @ErrorSeverity, @ErrorLine, LEFT(@ErrorMessage, 500), @ErrorDateTime
    );
END
GO

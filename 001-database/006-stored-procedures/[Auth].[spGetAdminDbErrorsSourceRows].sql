USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns recent database errors for the admin diagnostics view.
-- Supports a bounded row count and an optional lower-bound timestamp filter.
CREATE OR ALTER PROC [Auth].[spGetAdminDbErrorsSourceRows]
(
    @MaxRows INT = 200,
    @SinceDate DATETIME = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaxRows IS NULL OR @MaxRows < 1
    BEGIN
        SET @MaxRows = 200;
    END

    IF @MaxRows > 1000
    BEGIN
        SET @MaxRows = 1000;
    END

    SELECT TOP (@MaxRows)
        ErrorID,
        UserName,
        ErrorSchema,
        ErrorProcedure,
        ErrorNumber,
        ErrorState,
        ErrorSeverity,
        ErrorLine,
        ErrorMessage,
        ErrorDateTime
    FROM Auth.DB_Errors
    WHERE (@SinceDate IS NULL OR ErrorDateTime >= @SinceDate)
    ORDER BY COALESCE(ErrorDateTime, GETDATE()) DESC, ErrorID DESC;

    SET NOCOUNT OFF;
END
GO

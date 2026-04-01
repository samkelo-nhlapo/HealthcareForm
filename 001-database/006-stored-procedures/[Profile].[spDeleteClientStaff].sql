USE HealthcareForm
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Soft-deletes a client-staff row by ID or staff code.
-- Deleting also clears the primary-contact flag so the client can promote another contact later.
CREATE OR ALTER PROC [Profile].[spDeleteClientStaff]
(
    @ClientStaffId UNIQUEIDENTIFIER = NULL,
    @StaffCode VARCHAR(50) = '',
    @UpdatedBy VARCHAR(250) = NULL,
    @StatusCode INT OUTPUT,
    @Message VARCHAR(250) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @StatusCode = -1;
    SET @Message = '';

    IF @ClientStaffId IS NULL AND LTRIM(RTRIM(@StaffCode)) = ''
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'ClientStaffId or StaffCode is required.';
        RETURN;
    END

    IF EXISTS
    (
        SELECT 1
        FROM Profile.ClientStaff
        WHERE ((@ClientStaffId IS NOT NULL AND ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND StaffCode = @StaffCode))
          AND IsDeleted = 0
    )
    BEGIN
        UPDATE Profile.ClientStaff
        SET IsDeleted = 1,
            IsActive = 0,
            IsPrimaryContact = 0,
            UpdatedDate = GETDATE(),
            UpdatedBy = COALESCE(NULLIF(@UpdatedBy, ''), SUSER_SNAME())
        WHERE ((@ClientStaffId IS NOT NULL AND ClientStaffId = @ClientStaffId)
               OR (@ClientStaffId IS NULL AND StaffCode = @StaffCode))
          AND IsDeleted = 0;

        SET @StatusCode = 0;
        SET @Message = '';
    END
    ELSE
    BEGIN
        SET @StatusCode = 1;
        SET @Message = 'Client staff not found or already deleted.';
    END

    SET NOCOUNT OFF;
END
GO

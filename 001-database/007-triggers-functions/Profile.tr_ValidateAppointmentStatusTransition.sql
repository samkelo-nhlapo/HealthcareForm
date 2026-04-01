USE HealthcareForm
GO

-- Guards the small appointment-status state machine directly at the table boundary.
CREATE OR ALTER TRIGGER [Profile].[tr_ValidateAppointmentStatusTransition]
ON [Profile].[Appointments]
AFTER UPDATE
AS
BEGIN
    IF (ROWCOUNT_BIG() = 0)
        RETURN;

    SET NOCOUNT ON;

    -- Prevent invalid status values.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        WHERE I.Status NOT IN ('Scheduled', 'In Progress', 'Completed', 'Cancelled', 'No-show', 'Rescheduled')
    )
    BEGIN
        RAISERROR('Invalid appointment status value.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Do not allow moving away from terminal statuses.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE D.Status IN ('Completed', 'Cancelled', 'No-show')
          AND I.Status <> D.Status
    )
    BEGIN
        RAISERROR('Cannot transition from terminal appointment status.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Require cancellation metadata when cancelling.
    IF EXISTS
    (
        SELECT 1
        FROM inserted I
        INNER JOIN deleted D ON D.AppointmentId = I.AppointmentId
        WHERE I.Status = 'Cancelled'
          AND D.Status <> 'Cancelled'
          AND (NULLIF(LTRIM(RTRIM(ISNULL(I.CancellationReason, ''))), '') IS NULL
               OR NULLIF(LTRIM(RTRIM(ISNULL(I.CancelledBy, ''))), '') IS NULL
               OR I.CancelledDate IS NULL)
    )
    BEGIN
        RAISERROR('Cancelled appointments require CancellationReason, CancelledBy and CancelledDate.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

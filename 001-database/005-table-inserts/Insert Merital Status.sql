USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Profile.MaritalStatus (MaritalStatusDescription, IsActive, UpdateDate)
SELECT V.MaritalStatusDescription, V.IsActive, @DefaultDate
FROM (
    VALUES
        ('Single', 1),
        ('Married', 1),
        ('Widowed', 1),
        ('Divorced', 1),
        ('Separated', 1),
        ('Domestic Partnership', 1)
) V(MaritalStatusDescription, IsActive)
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.MaritalStatus MS
    WHERE MS.MaritalStatusDescription = V.MaritalStatusDescription
);
GO

PRINT 'Marital status lookup table populated successfully'
GO

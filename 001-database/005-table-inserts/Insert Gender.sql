USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Profile.Gender (GenderDescription, IsActive, UpdateDate)
SELECT V.GenderDescription, V.IsActive, @DefaultDate
FROM (
    VALUES
        ('Male', 1),
        ('Female', 1),
        ('Other', 1),
        ('Prefer Not to Say', 1)
) V(GenderDescription, IsActive)
WHERE NOT EXISTS
(
    SELECT 1
    FROM Profile.Gender G
    WHERE G.GenderDescription = V.GenderDescription
);
GO

PRINT 'Gender lookup table populated successfully'
GO

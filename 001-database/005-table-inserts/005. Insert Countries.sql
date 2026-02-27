USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Location.Countries (CountryName, Alpha2Code, Alpha3Code, Numeric, IsActive, UpdateDate)
SELECT V.CountryName, V.Alpha2Code, V.Alpha3Code, V.Numeric, V.IsActive, @DefaultDate
FROM (
    VALUES
        ('South Africa', 'ZA', 'ZAF', 710, 1),
        ('Botswana', 'BW', 'BWA', 72, 1),
        ('Lesotho', 'LS', 'LSO', 426, 1),
        ('Namibia', 'NA', 'NAM', 516, 1),
        ('Eswatini', 'SZ', 'SWZ', 748, 1),
        ('Zimbabwe', 'ZW', 'ZWE', 716, 1),
        ('Mozambique', 'MZ', 'MOZ', 508, 1),
        ('Angola', 'AO', 'AGO', 24, 1),
        ('Zambia', 'ZM', 'ZMB', 894, 1),
        ('Malawi', 'MW', 'MWI', 454, 1),
        ('United States', 'US', 'USA', 840, 1),
        ('United Kingdom', 'GB', 'GBR', 826, 1),
        ('Canada', 'CA', 'CAN', 124, 1),
        ('Australia', 'AU', 'AUS', 36, 1),
        ('Germany', 'DE', 'DEU', 276, 1),
        ('France', 'FR', 'FRA', 250, 1),
        ('India', 'IN', 'IND', 356, 1),
        ('Brazil', 'BR', 'BRA', 76, 1),
        ('Japan', 'JP', 'JPN', 392, 1),
        ('China', 'CN', 'CHN', 156, 1)
) V(CountryName, Alpha2Code, Alpha3Code, Numeric, IsActive)
WHERE NOT EXISTS
(
    SELECT 1
    FROM Location.Countries C
    WHERE C.Alpha2Code = V.Alpha2Code
);
GO

PRINT 'Countries lookup table populated successfully';
GO

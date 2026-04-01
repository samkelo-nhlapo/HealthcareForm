USE HealthcareForm;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Returns invoice rows for the revenue claims board.
-- The join picks the most relevant active insurance row per patient before resolving payer details.
CREATE OR ALTER PROC [Profile].[spGetRevenueClaimsSourceRows]
(
    @MaxRows INT = 400
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @MaxRows IS NULL OR @MaxRows < 1
    BEGIN
        SET @MaxRows = 400;
    END

    SELECT TOP (@MaxRows)
        I.InvoiceId,
        I.InvoiceNumber,
        I.InvoiceDate,
        I.ServiceDate,
        I.TotalAmount,
        I.InsuranceCoverage,
        I.Status,
        I.Notes,
        I.UpdatedDate,
        P.FirstName,
        P.LastName,
        P.ID_Number AS IdNumber,
        IP.ProviderName AS PayerName,
        BC.Code AS BillingCode
    FROM Profile.Invoices I
    INNER JOIN Profile.Patient P
        ON P.PatientId = I.PatientIdFK
    -- Prefer the current primary insurance row and fall back to the most recently updated active row.
    LEFT JOIN
    (
        SELECT
            PI.PatientIdFK,
            PI.InsuranceProviderIdFK,
            ROW_NUMBER() OVER
            (
                PARTITION BY PI.PatientIdFK
                ORDER BY
                    CASE WHEN PI.IsPrimary = 1 THEN 0 ELSE 1 END,
                    COALESCE(PI.UpdatedDate, PI.CreatedDate, GETDATE()) DESC
            ) AS RowNum
        FROM Profile.PatientInsurance PI
        WHERE PI.Status = 'Active'
    ) ActiveInsurance
        ON ActiveInsurance.PatientIdFK = P.PatientId
       AND ActiveInsurance.RowNum = 1
    LEFT JOIN Profile.InsuranceProviders IP
        ON IP.InsuranceProviderId = ActiveInsurance.InsuranceProviderIdFK
    LEFT JOIN Profile.BillingCodes BC
        ON BC.BillingCodeId = I.BillingCodeIdFK
    ORDER BY COALESCE(I.UpdatedDate, I.InvoiceDate) DESC;
END
GO

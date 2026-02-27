USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE();

INSERT INTO Auth.Permissions
(
    PermissionId,
    PermissionName,
    Description,
    Category,
    Module,
    ActionType,
    IsActive,
    CreatedDate,
    CreatedBy
)
SELECT NEWID(), V.PermissionName, V.Description, V.Category, V.Module, V.ActionType, 1, @DefaultDate, 'SYSTEM'
FROM (
    VALUES
        ('Patient_Create', 'Create new patient record', 'CLINICAL', 'PATIENT', 'CREATE'),
        ('Patient_Read', 'View patient information', 'CLINICAL', 'PATIENT', 'READ'),
        ('Patient_Update', 'Modify patient information', 'CLINICAL', 'PATIENT', 'UPDATE'),
        ('Patient_Delete', 'Delete patient record', 'CLINICAL', 'PATIENT', 'DELETE'),
        ('Patient_ViewAll', 'View all patients in system', 'CLINICAL', 'PATIENT', 'READ'),
        ('MedicalHistory_Create', 'Add medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'CREATE'),
        ('MedicalHistory_Read', 'View medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'READ'),
        ('MedicalHistory_Update', 'Modify medical history', 'CLINICAL', 'MEDICAL_HISTORY', 'UPDATE'),
        ('MedicalHistory_Delete', 'Delete medical history entry', 'CLINICAL', 'MEDICAL_HISTORY', 'DELETE'),
        ('Appointment_Create', 'Create appointment', 'CLINICAL', 'APPOINTMENT', 'CREATE'),
        ('Appointment_Read', 'View appointments', 'CLINICAL', 'APPOINTMENT', 'READ'),
        ('Appointment_Update', 'Modify appointment', 'CLINICAL', 'APPOINTMENT', 'UPDATE'),
        ('Appointment_Cancel', 'Cancel appointment', 'CLINICAL', 'APPOINTMENT', 'CANCEL'),
        ('Appointment_ViewAll', 'View all appointments', 'CLINICAL', 'APPOINTMENT', 'READ'),
        ('Medication_Create', 'Add medication record', 'CLINICAL', 'MEDICATION', 'CREATE'),
        ('Medication_Read', 'View medication history', 'CLINICAL', 'MEDICATION', 'READ'),
        ('Medication_Update', 'Modify medication record', 'CLINICAL', 'MEDICATION', 'UPDATE'),
        ('Medication_Delete', 'Remove medication record', 'CLINICAL', 'MEDICATION', 'DELETE'),
        ('Medication_Manage', 'Manage all medications in system', 'CLINICAL', 'MEDICATION', 'MANAGE'),
        ('ConsultationNotes_Create', 'Create consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'CREATE'),
        ('ConsultationNotes_Read', 'View consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'READ'),
        ('ConsultationNotes_Update', 'Modify consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'UPDATE'),
        ('ConsultationNotes_Delete', 'Delete consultation notes', 'CLINICAL', 'CONSULTATION_NOTES', 'DELETE'),
        ('Form_Create', 'Create form template', 'OPERATIONS', 'FORM', 'CREATE'),
        ('Form_Read', 'View forms', 'OPERATIONS', 'FORM', 'READ'),
        ('Form_Update', 'Modify form template', 'OPERATIONS', 'FORM', 'UPDATE'),
        ('Form_Delete', 'Delete form', 'OPERATIONS', 'FORM', 'DELETE'),
        ('Form_Submit', 'Submit form', 'OPERATIONS', 'FORM', 'SUBMIT'),
        ('Form_Review', 'Review submitted forms', 'OPERATIONS', 'FORM', 'REVIEW'),
        ('Invoice_Create', 'Create invoice', 'FINANCE', 'INVOICE', 'CREATE'),
        ('Invoice_Read', 'View invoices', 'FINANCE', 'INVOICE', 'READ'),
        ('Invoice_Update', 'Modify invoice', 'FINANCE', 'INVOICE', 'UPDATE'),
        ('Invoice_Delete', 'Delete invoice', 'FINANCE', 'INVOICE', 'DELETE'),
        ('Payment_Process', 'Process payment', 'FINANCE', 'PAYMENT', 'PROCESS'),
        ('Payment_View', 'View payment history', 'FINANCE', 'PAYMENT', 'READ'),
        ('Insurance_Create', 'Create insurance record', 'FINANCE', 'INSURANCE', 'CREATE'),
        ('Insurance_Read', 'View insurance information', 'FINANCE', 'INSURANCE', 'READ'),
        ('Insurance_Update', 'Modify insurance record', 'FINANCE', 'INSURANCE', 'UPDATE'),
        ('Insurance_Delete', 'Delete insurance record', 'FINANCE', 'INSURANCE', 'DELETE'),
        ('Allergy_Create', 'Add allergy record', 'CLINICAL', 'ALLERGY', 'CREATE'),
        ('Allergy_Read', 'View allergy information', 'CLINICAL', 'ALLERGY', 'READ'),
        ('Allergy_Update', 'Modify allergy record', 'CLINICAL', 'ALLERGY', 'UPDATE'),
        ('Allergy_Delete', 'Delete allergy record', 'CLINICAL', 'ALLERGY', 'DELETE'),
        ('LabResults_Create', 'Create lab results', 'CLINICAL', 'LAB_RESULTS', 'CREATE'),
        ('LabResults_Read', 'View lab results', 'CLINICAL', 'LAB_RESULTS', 'READ'),
        ('LabResults_Update', 'Modify lab results', 'CLINICAL', 'LAB_RESULTS', 'UPDATE'),
        ('LabResults_Delete', 'Delete lab results', 'CLINICAL', 'LAB_RESULTS', 'DELETE'),
        ('SystemAdmin_User', 'Manage users and roles', 'ADMIN', 'SYSTEM', 'MANAGE'),
        ('SystemAdmin_Audit', 'View audit logs', 'ADMIN', 'SYSTEM', 'READ'),
        ('SystemAdmin_Reports', 'Generate system reports', 'ADMIN', 'SYSTEM', 'EXECUTE'),
        ('SystemAdmin_Settings', 'Modify system settings', 'ADMIN', 'SYSTEM', 'UPDATE'),
        ('SystemAdmin_Database', 'Database administration', 'ADMIN', 'SYSTEM', 'ADMIN'),
        ('Referral_Create', 'Create referral', 'CLINICAL', 'REFERRAL', 'CREATE'),
        ('Referral_Read', 'View referrals', 'CLINICAL', 'REFERRAL', 'READ'),
        ('Referral_Update', 'Update referral status', 'CLINICAL', 'REFERRAL', 'UPDATE'),
        ('Referral_Delete', 'Delete referral', 'CLINICAL', 'REFERRAL', 'DELETE')
) V(PermissionName, Description, Category, Module, ActionType)
WHERE NOT EXISTS (
    SELECT 1 FROM Auth.Permissions P WHERE P.PermissionName = V.PermissionName
);
GO

PRINT 'Auth permissions inserted/verified successfully';
GO

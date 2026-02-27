USE HealthcareForm
GO

DECLARE @DefaultDate DATETIME = GETDATE(),
        @RoleId_ADMIN UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'ADMIN'),
        @RoleId_DOCTOR UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'DOCTOR'),
        @RoleId_NURSE UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'NURSE'),
        @RoleId_RECEPTIONIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'RECEPTIONIST'),
        @RoleId_PATIENT UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PATIENT'),
        @RoleId_BILLING UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'BILLING'),
        @RoleId_PHARMACIST UNIQUEIDENTIFIER = (SELECT RoleId FROM Auth.Roles WHERE RoleName = 'PHARMACIST');

;WITH RolePermissionSource AS
(
    SELECT @RoleId_ADMIN AS RoleId, P.PermissionId
    FROM Auth.Permissions P

    UNION ALL
    SELECT @RoleId_DOCTOR, P.PermissionId FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
        'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update', 'MedicalHistory_Delete',
        'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
        'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
        'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update', 'ConsultationNotes_Delete',
        'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
        'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
        'Referral_Create', 'Referral_Read', 'Referral_Update',
        'Insurance_Read', 'Payment_View'
    )

    UNION ALL
    SELECT @RoleId_NURSE, P.PermissionId FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
        'MedicalHistory_Create', 'MedicalHistory_Read', 'MedicalHistory_Update',
        'Appointment_Read', 'Appointment_ViewAll',
        'Medication_Read', 'Medication_Update',
        'ConsultationNotes_Create', 'ConsultationNotes_Read', 'ConsultationNotes_Update',
        'Allergy_Create', 'Allergy_Read', 'Allergy_Update', 'Allergy_Delete',
        'LabResults_Create', 'LabResults_Read', 'LabResults_Update',
        'Form_Read', 'Form_Submit', 'Form_Review',
        'Payment_View'
    )

    UNION ALL
    SELECT @RoleId_RECEPTIONIST, P.PermissionId FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Create', 'Patient_Read', 'Patient_Update', 'Patient_ViewAll',
        'Appointment_Create', 'Appointment_Read', 'Appointment_Update', 'Appointment_Cancel', 'Appointment_ViewAll',
        'Form_Read', 'Form_Submit',
        'Payment_View'
    )

    UNION ALL
    SELECT @RoleId_PATIENT, P.PermissionId FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_Update',
        'MedicalHistory_Read',
        'Appointment_Create', 'Appointment_Read', 'Appointment_Cancel',
        'Medication_Read',
        'ConsultationNotes_Read',
        'Allergy_Read',
        'LabResults_Read',
        'Form_Read', 'Form_Submit',
        'Insurance_Read',
        'Payment_View'
    )

    UNION ALL
    SELECT @RoleId_BILLING, P.PermissionId FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_ViewAll',
        'Appointment_Read', 'Appointment_ViewAll',
        'Invoice_Create', 'Invoice_Read', 'Invoice_Update', 'Invoice_Delete',
        'Payment_Process', 'Payment_View',
        'Insurance_Create', 'Insurance_Read', 'Insurance_Update', 'Insurance_Delete'
    )

    UNION ALL
    SELECT @RoleId_PHARMACIST, P.PermissionId FROM Auth.Permissions P
    WHERE P.PermissionName IN (
        'Patient_Read', 'Patient_ViewAll',
        'Medication_Create', 'Medication_Read', 'Medication_Update', 'Medication_Delete', 'Medication_Manage',
        'Allergy_Read'
    )
)
INSERT INTO Auth.RolePermissions (RolePermissionId, RoleIdFK, PermissionIdFK, CreatedDate, CreatedBy)
SELECT NEWID(), S.RoleId, S.PermissionId, @DefaultDate, 'SYSTEM'
FROM RolePermissionSource S
WHERE S.RoleId IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM Auth.RolePermissions RP
      WHERE RP.RoleIdFK = S.RoleId
        AND RP.PermissionIdFK = S.PermissionId
  );
GO

PRINT 'Auth role permissions mapped/verified successfully';
GO

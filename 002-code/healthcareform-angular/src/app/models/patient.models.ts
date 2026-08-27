export interface LookupOptionDto {
  Id: number;
  Name: string;
}

export interface PatientClientLookupItemDto {
  ClientId: string;
  ClientCode: string;
  ClientName: string;
  ClientClinicCategoryName: string;
}

export interface PatientClientAssignmentDto {
  ClientId: string;
  ClientCode: string;
  ClientName: string;
  ClientClinicCategoryName: string;
  IsPrimary: boolean;
}

export interface PatientCreateRequestDto {
  PrimaryClientId: string;
  SecondaryClientIds: string[];
  FirstName: string;
  LastName: string;
  IdNumber: string;
  DateOfBirth: string;
  GenderId: number;
  PhoneNumber: string;
  Email: string;
  Line1: string;
  Line2: string;
  CityId: number;
  ProvinceId: number;
  CountryId: number;
  MaritalStatusId: number;
  EmergencyName: string;
  EmergencyLastName: string;
  EmergencyPhoneNumber: string;
  Relationship: string;
  EmergencyDateOfBirth: string;
  MedicationList: string;
}

export interface PatientRecordDto {
  ClientId: string | null;
  ClientCode: string;
  ClientName: string;
  ClientClinicCategoryName: string;
  Clients: PatientClientAssignmentDto[];
  IdNumber: string;
  FirstName: string;
  LastName: string;
  DateOfBirth: string;
  GenderId: number;
  PhoneNumber: string;
  Email: string;
  Line1: string;
  Line2: string;
  CityId: number;
  ProvinceId: number;
  CountryId: number;
  MaritalStatusId: number;
  MedicationList: string;
  EmergencyName: string;
  EmergencyLastName: string;
  EmergencyPhoneNumber: string;
  Relationship: string;
  EmergencyDateOfBirth: string;
}

export interface PatientCommandResultDto {
  Success: boolean;
  Message: string;
  StatusCode: number | null;
  PatientId: string | null;
}

export interface PatientLookupResultDto {
  Found: boolean;
  Message: string;
  Patient: PatientRecordDto | null;
}

export interface PatientMedicationDto {
  MedicationId: string;
  MedicationName: string;
  Dosage: string;
  Frequency: string;
  Route: string;
  Indication: string;
  PrescribedBy: string;
  PrescriptionDate: string;
  StartDate: string;
  EndDate: string | null;
  Status: string;
  SideEffects: string;
  Notes: string;
  IsActive: boolean;
  UpdatedDate: string | null;
}

export interface PatientPendingOrderDto {
  LabResultId: string;
  TestName: string;
  TestCode: string;
  SpecimenType: string;
  Status: string;
  OrderedBy: string;
  Lab: string;
  CollectionDate: string | null;
  ResultDate: string | null;
}

export interface PatientLabResultDto {
  LabResultId: string;
  TestName: string;
  TestCode: string;
  ResultValue: string;
  Unit: string;
  ReferenceRange: string;
  Severity: string;
  OrderedBy: string;
  Lab: string;
  Interpretation: string;
  Notes: string;
  CollectionDate: string | null;
  ResultDate: string | null;
}

export interface PatientOrdersResultsSnapshotDto {
  PendingOrders: PatientPendingOrderDto[];
  Results: PatientLabResultDto[];
}

export interface PatientDirectoryQueryDto {
  SearchTerm?: string;
  GenderId?: number;
  MaritalStatusId?: number;
  ClientId?: string;
  IsDeleted?: boolean;
  PageNumber?: number;
  PageSize?: number;
}

export interface PatientDirectoryItemDto {
  PatientId: string;
  FirstName: string;
  LastName: string;
  IdNumber: string;
  DateOfBirth: string | null;
  GenderId: number;
  MaritalStatusId: number;
  ClientId: string | null;
  ClientCode: string;
  ClientName: string;
  ClientClinicCategoryName: string;
  Clients: PatientClientAssignmentDto[];
  MedicationList: string;
  IsDeleted: boolean;
  Email: string;
  PhoneNumber: string;
  Line1: string;
  Line2: string;
  CityId: number;
  CityName: string;
  ProvinceId: number;
  ProvinceName: string;
  CountryId: number;
  CountryName: string;
  CreatedDate: string;
  UpdatedDate: string;
}

export interface PatientDirectorySnapshotDto {
  Patients: PatientDirectoryItemDto[];
  TotalRecords: number;
}

export interface PatientWorklistItemDto {
  IdNumber: string;
  Patient: string;
  Status: string;
  Clinic: string;
  Risk: string;
  UpdatedOn: string;
}

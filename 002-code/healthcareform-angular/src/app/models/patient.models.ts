export interface LookupOptionDto {
  Id: number;
  Name: string;
}

export interface PatientCreateRequestDto {
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

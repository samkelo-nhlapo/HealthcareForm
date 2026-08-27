export interface ClientCreateRequestDto {
  ClientCode: string;
  FirstName: string;
  LastName: string;
  DateOfBirth?: string | null;
  IdNumber?: string;
  Email?: string;
  PhoneNumber?: string;
  Line1?: string;
  Line2?: string;
  CityId?: number | null;
  ClientClinicCategoryId?: number | null;
}

export interface ClientUpdateRequestDto {
  ClientCode: string;
  FirstName: string;
  LastName: string;
  DateOfBirth?: string | null;
  IdNumber?: string;
  Email?: string;
  PhoneNumber?: string;
  Line1?: string;
  Line2?: string;
  CityId?: number | null;
  ClientClinicCategoryId?: number | null;
  IsActive: boolean;
}

export interface ClientCommandResultDto {
  Success: boolean;
  Message: string;
  StatusCode: number | null;
  ClientId: string | null;
}

export interface ClientDepartmentCreateRequestDto {
  DepartmentName: string;
  DepartmentCode?: string;
  DepartmentType: string;
}

export interface ClientDepartmentUpdateRequestDto {
  DepartmentName: string;
  DepartmentCode?: string;
  DepartmentType: string;
  IsActive: boolean;
}

export interface ClientDepartmentCommandResultDto {
  Success: boolean;
  Message: string;
  StatusCode: number | null;
  ClientDepartmentId: string | null;
}

export interface ClientStaffCreateRequestDto {
  StaffCode: string;
  FirstName: string;
  LastName: string;
  Email?: string;
  PhoneNumber?: string;
  JobTitle?: string;
  Department?: string;
  StaffType: string;
  EmploymentType: string;
  HireDate?: string | null;
  IsPrimaryContact: boolean;
  PrimaryDepartmentId?: string | null;
}

export interface ClientStaffUpdateRequestDto {
  StaffCode: string;
  FirstName: string;
  LastName: string;
  Email?: string;
  PhoneNumber?: string;
  JobTitle?: string;
  Department?: string;
  StaffType: string;
  EmploymentType: string;
  HireDate?: string | null;
  TerminationDate?: string | null;
  IsPrimaryContact: boolean;
  IsActive: boolean;
  PrimaryDepartmentId?: string | null;
}

export interface ClientStaffCommandResultDto {
  Success: boolean;
  Message: string;
  StatusCode: number | null;
  ClientStaffId: string | null;
}

export interface ClientClinicCategoryDto {
  ClientClinicCategoryId: number;
  CategoryName: string;
  ClinicSize: string;
  OwnershipType: string;
  IsActive: boolean;
  CreatedDate: string;
  UpdatedDate: string;
}

export interface ClientDirectoryQueryDto {
  SearchTerm?: string;
  ClientClinicCategoryId?: number;
  IsActive?: boolean;
  IsDeleted?: boolean;
  PageNumber?: number;
  PageSize?: number;
}

export interface ClientDirectoryItemDto {
  ClientId: string;
  PatientId: string | null;
  RegisteredPatientCount: number;
  ActivePatientCount: number;
  ClientClinicCategoryId: number | null;
  ClientClinicCategoryName: string;
  ClinicSize: string;
  OwnershipType: string;
  ClientCode: string;
  DisplayName: string;
  OrganizationType: string;
  GroupOperator: string;
  NetworkSources: string;
  DirectoryExternalKey: string;
  FirstName: string;
  LastName: string;
  DateOfBirth: string | null;
  IdNumber: string;
  Email: string;
  PhoneNumber: string;
  AddressId: string | null;
  Line1: string;
  Line2: string;
  CityId: number | null;
  FacilityCityId: number | null;
  FacilityTownName: string;
  FacilityProvinceName: string;
  FacilityCountryName: string;
  FacilityAddressText: string;
  IsActive: boolean;
  IsDeleted: boolean;
  CreatedDate: string;
  UpdatedDate: string;
}

export interface ClientDirectorySnapshotDto {
  Clients: ClientDirectoryItemDto[];
  TotalRecords: number;
}

export interface ClientRecordDto {
  ClientId: string;
  PatientId: string | null;
  RegisteredPatientCount: number;
  ActivePatientCount: number;
  ClientClinicCategoryId: number | null;
  ClientClinicCategoryName: string;
  ClinicSize: string;
  OwnershipType: string;
  ClientCode: string;
  DisplayName: string;
  OrganizationType: string;
  GroupOperator: string;
  NetworkSources: string;
  DirectoryExternalKey: string;
  FirstName: string;
  LastName: string;
  DateOfBirth: string | null;
  IdNumber: string;
  Email: string;
  PhoneNumber: string;
  AddressId: string | null;
  Line1: string;
  Line2: string;
  CityId: number | null;
  FacilityCityId: number | null;
  FacilityTownName: string;
  FacilityProvinceName: string;
  FacilityCountryName: string;
  FacilityAddressText: string;
  IsActive: boolean;
  IsDeleted: boolean;
  CreatedDate: string;
  CreatedBy: string;
  UpdatedDate: string;
  UpdatedBy: string;
}

export interface ClientLookupResultDto {
  Found: boolean;
  Message: string;
  Client: ClientRecordDto | null;
}

export interface ClientDepartmentQueryDto {
  ClientId?: string;
  DepartmentType?: string;
  SearchTerm?: string;
  IsActive?: boolean;
  IsDeleted?: boolean;
  PageNumber?: number;
  PageSize?: number;
}

export interface ClientDepartmentDto {
  ClientDepartmentId: string;
  ClientId: string;
  ClientCode: string;
  ClientFirstName: string;
  ClientLastName: string;
  DepartmentCode: string;
  DepartmentName: string;
  DepartmentType: string;
  IsActive: boolean;
  IsDeleted: boolean;
  CreatedDate: string;
  CreatedBy: string;
  UpdatedDate: string;
  UpdatedBy: string;
}

export interface ClientDepartmentSnapshotDto {
  Departments: ClientDepartmentDto[];
  TotalRecords: number;
}

export interface ClientStaffQueryDto {
  ClientId?: string;
  SearchTerm?: string;
  RoleId?: string;
  StaffType?: string;
  IsActive?: boolean;
  IsDeleted?: boolean;
  PageNumber?: number;
  PageSize?: number;
}

export interface ClientStaffDto {
  ClientStaffId: string;
  ClientId: string;
  ClientCode: string;
  RoleId: string | null;
  RoleName: string;
  UserId: string | null;
  Username: string;
  ProviderId: string | null;
  StaffCode: string;
  FirstName: string;
  LastName: string;
  Email: string;
  PhoneNumber: string;
  JobTitle: string;
  Department: string;
  StaffDesignationId: string | null;
  StaffDesignation: string;
  PrimaryDepartmentId: string | null;
  PrimaryDepartmentName: string;
  StaffType: string;
  EmploymentType: string;
  HireDate: string | null;
  TerminationDate: string | null;
  IsPrimaryContact: boolean;
  IsActive: boolean;
  IsDeleted: boolean;
  CreatedDate: string;
  CreatedBy: string;
  UpdatedDate: string;
  UpdatedBy: string;
}

export interface ClientStaffSnapshotDto {
  Staff: ClientStaffDto[];
  TotalRecords: number;
}

export interface ClientStaffLookupResultDto {
  Found: boolean;
  Message: string;
  Staff: ClientStaffDto | null;
}

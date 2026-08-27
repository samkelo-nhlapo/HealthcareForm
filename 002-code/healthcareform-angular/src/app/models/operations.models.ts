export interface SchedulingProviderLoadDto {
  ClientProviderAffiliationId: string;
  ClientStaffId: string;
  ClientId: string;
  ClientName: string;
  ProviderId: string;
  Provider: string;
  Clinic: string;
  Room: string;
  Booked: number;
  Capacity: number;
  NextSlot: string;
}

export interface SchedulingResourceLoadDto {
  Resource: string;
  Clinic: string;
  Allocated: number;
  Available: number;
  TurnaroundMinutes: number;
}

export interface SchedulingTimeBlockDto {
  Time: string;
  General: number;
  Cardiology: number;
  Pediatrics: number;
  Oncology: number;
}

export interface SchedulingSnapshotDto {
  Providers: SchedulingProviderLoadDto[];
  Resources: SchedulingResourceLoadDto[];
  Blocks: SchedulingTimeBlockDto[];
}

export interface SchedulingAppointmentCreateRequestDto {
  ClientId: string;
  PatientIdNumber: string;
  ClientProviderAffiliationId: string;
  ClientStaffId?: string;
  AppointmentDateTime: string;
  DurationMinutes: number;
  AppointmentType: string;
  Reason?: string;
  Location?: string;
}

export interface SchedulingAppointmentCommandResultDto {
  Success: boolean;
  Message: string;
  StatusCode?: number;
  AppointmentId?: string;
}

export interface SchedulingBookingClientDto {
  ClientId: string;
  ClientName: string;
  ClientCode: string;
  ClientCategory: string;
}

export interface SchedulingBookingProviderDto {
  ClientProviderAffiliationId: string;
  ClientStaffId: string;
  ProviderId: string;
  ClientId: string;
  Provider: string;
  Clinic: string;
}

export interface SchedulingBookingOptionsDto {
  Clients: SchedulingBookingClientDto[];
  Providers: SchedulingBookingProviderDto[];
}

export interface TaskQueueItemDto {
  TaskId: string;
  Title: string;
  Team: string;
  Owner: string;
  Patient: string;
  IdNumber: string;
  Priority: string;
  Status: string;
  DueAt: string;
  SlaMinutes: number;
  ElapsedMinutes: number;
}

export interface TaskQueueSnapshotDto {
  Tasks: TaskQueueItemDto[];
}

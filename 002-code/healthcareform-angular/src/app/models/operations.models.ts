export interface SchedulingProviderLoadDto {
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

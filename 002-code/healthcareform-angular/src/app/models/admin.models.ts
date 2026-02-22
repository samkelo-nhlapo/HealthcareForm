export interface AdminAccessUserDto {
  Username: string;
  FullName: string;
  Email: string;
  Roles: string[];
  Status: string;
  Mfa: string;
  LastLogin: string;
}

export interface AdminPermissionMatrixRowDto {
  PermissionName: string;
  Module: string;
  Action: string;
  Roles: string[];
}

export interface AdminAccessControlSnapshotDto {
  RoleColumns: string[];
  Users: AdminAccessUserDto[];
  Permissions: AdminPermissionMatrixRowDto[];
}

export interface AdminAuditEventDto {
  OccurredAtUtc: string;
  Actor: string;
  ActorRole: string;
  Category: string;
  EventName: string;
  Resource: string;
  Outcome: string;
  IpAddress: string;
  CorrelationId: string;
  Privileged: boolean;
}

export interface AdminAuditLogSnapshotDto {
  ActorOptions: string[];
  Events: AdminAuditEventDto[];
  Page?: number;
  PageSize?: number;
  TotalCount?: number;
  TotalPages?: number;
}

export interface AdminAuditLogQueryDto {
  actor?: string;
  category?: string;
  outcome?: string;
  fromUtc?: string;
  toUtc?: string;
  search?: string;
  privilegedOnly?: boolean;
  page?: number;
  pageSize?: number;
}

export interface AdminConfigurationItemDto {
  Key: string;
  Scope: string;
  CurrentValue: string;
  BaselineValue: string;
  LastUpdated: string;
  Owner: string;
  State: string;
}

export interface AdminTemplateGovernanceItemDto {
  TemplateName: string;
  Version: string;
  Status: string;
  Owner: string;
  LastApproved: string;
  NextReview: string;
}

export interface AdminLookupHealthItemDto {
  Name: string;
  Records: number;
  Source: string;
  RefreshCadence: string;
  LastSync: string;
  State: string;
}

export interface AdminDataGovernanceSnapshotDto {
  ConfigurationItems: AdminConfigurationItemDto[];
  TemplateItems: AdminTemplateGovernanceItemDto[];
  LookupItems: AdminLookupHealthItemDto[];
}

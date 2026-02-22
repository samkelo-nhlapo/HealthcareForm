import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { AdminAccessControlSnapshotDto } from '../../models/admin.models';
import { AuthService } from '../../services/auth.service';
import { AdminApiService } from '../../services/admin-api.service';

type UserStatus = 'Active' | 'Locked' | 'Inactive';
type MfaState = 'Enrolled' | 'Pending';

type AccessUser = {
  username: string;
  fullName: string;
  email: string;
  roles: string[];
  status: UserStatus;
  mfa: MfaState;
  lastLogin: string;
};

type PermissionRow = {
  permissionName: string;
  module: string;
  action: string;
  roles: string[];
};

@Component({
  selector: 'app-admin-access-control',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './admin-access-control.component.html',
  styleUrl: './admin-access-control.component.scss'
})
export class AdminAccessControlComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly authService = inject(AuthService);
  private readonly adminApiService = inject(AdminApiService);

  roleColumns: string[] = ['ADMIN', 'DOCTOR', 'NURSE', 'BILLING', 'RECEPTIONIST', 'PHARMACIST'];
  isLoading = true;
  loadError = '';

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    role: ['ALL'],
    status: ['ALL'],
    mfa: ['ALL']
  });

  users: AccessUser[] = [];

  permissions: PermissionRow[] = [];

  ngOnInit(): void {
    this.loadSnapshot();
  }

  retryLoad(): void {
    this.loadSnapshot();
  }

  private loadSnapshot(): void {
    this.isLoading = true;
    this.loadError = '';

    this.adminApiService.getAccessControlSnapshot().subscribe({
      next: (snapshot) => {
        this.applySnapshot(snapshot);
        this.isLoading = false;
      },
      error: () => {
        this.roleColumns = ['ADMIN', 'DOCTOR', 'NURSE', 'BILLING', 'RECEPTIONIST', 'PHARMACIST'];
        this.users = [];
        this.permissions = [];
        this.loadError = 'Unable to load access-control data. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private applySnapshot(snapshot: AdminAccessControlSnapshotDto): void {
    if (Array.isArray(snapshot.RoleColumns) && snapshot.RoleColumns.length > 0) {
      this.roleColumns = snapshot.RoleColumns;
    }

    if (Array.isArray(snapshot.Users)) {
      this.users = snapshot.Users.map((user) => ({
        username: user.Username,
        fullName: user.FullName,
        email: user.Email,
        roles: user.Roles ?? [],
        status: this.normalizeStatus(user.Status),
        mfa: this.normalizeMfa(user.Mfa),
        lastLogin: user.LastLogin || 'Never'
      }));
    }

    if (Array.isArray(snapshot.Permissions)) {
      this.permissions = snapshot.Permissions.map((permission) => ({
        permissionName: permission.PermissionName,
        module: permission.Module,
        action: permission.Action,
        roles: permission.Roles ?? []
      }));
    }
  }

  private normalizeStatus(value: string): UserStatus {
    const normalized = (value ?? '').trim().toLowerCase();
    if (normalized === 'locked') {
      return 'Locked';
    }

    if (normalized === 'inactive') {
      return 'Inactive';
    }

    return 'Active';
  }

  private normalizeMfa(value: string): MfaState {
    return (value ?? '').trim().toLowerCase() === 'pending' ? 'Pending' : 'Enrolled';
  }

  get tokenRoles(): string {
    const roles = this.authService.getCurrentRoles();
    if (roles.length === 0) {
      return 'No roles available in current token';
    }

    return roles.join(', ');
  }

  get filteredUsers(): AccessUser[] {
    const value = this.filters.getRawValue();
    const search = value.search.trim().toLowerCase();

    return this.users.filter((user) => {
      const matchesSearch = !search
        || user.username.toLowerCase().includes(search)
        || user.fullName.toLowerCase().includes(search)
        || user.email.toLowerCase().includes(search);

      const matchesRole = value.role === 'ALL' || user.roles.includes(value.role);
      const matchesStatus = value.status === 'ALL' || user.status === value.status;
      const matchesMfa = value.mfa === 'ALL' || user.mfa === value.mfa;

      return matchesSearch && matchesRole && matchesStatus && matchesMfa;
    });
  }

  get activeUsers(): number {
    return this.users.filter((user) => user.status === 'Active').length;
  }

  get lockedUsers(): number {
    return this.users.filter((user) => user.status === 'Locked').length;
  }

  get pendingMfaUsers(): number {
    return this.users.filter((user) => user.mfa === 'Pending').length;
  }

  get privilegedUsers(): number {
    return this.users.filter((user) => user.roles.includes('ADMIN')).length;
  }

  hasRole(user: AccessUser, role: string): boolean {
    return user.roles.includes(role);
  }

  hasPermission(permission: PermissionRow, role: string): boolean {
    return permission.roles.includes(role);
  }
}

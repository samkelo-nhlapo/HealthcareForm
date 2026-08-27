import { CommonModule } from '@angular/common';
import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { distinctUntilChanged } from 'rxjs';
import { finalize, forkJoin } from 'rxjs';
import {
  LookupOptionDto,
  PatientClientAssignmentDto,
  PatientClientLookupItemDto,
  PatientDirectoryItemDto,
  PatientDirectorySnapshotDto
} from '../../models/patient.models';
import { AuthService } from '../../services/auth.service';
import { PatientApiService } from '../../services/patient-api.service';
import { PatientHubSearchService } from '../patient-hub/patient-hub-search.service';
import { PatientHubSelectionService } from '../patient-hub/patient-hub-selection.service';

type RecordState = 'ACTIVE' | 'DELETED' | 'ALL';

type DirectoryRow = {
  patientId: string;
  patient: string;
  idNumber: string;
  email: string;
  phoneNumber: string;
  primaryClient: string;
  clientMeta: string;
  city: string;
  province: string;
  dateOfBirth: string;
  updatedOn: string;
  isDeleted: boolean;
};

@Component({
  selector: 'app-patient-directory',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './patient-directory.component.html',
  styleUrl: './patient-directory.component.scss'
})
export class PatientDirectoryComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly destroyRef = inject(DestroyRef);
  private readonly patientApi = inject(PatientApiService);
  private readonly patientHubSearch = inject(PatientHubSearchService);
  private readonly patientHubSelection = inject(PatientHubSelectionService);
  private readonly authService = inject(AuthService);

  readonly pageSize = 25;

  genders: LookupOptionDto[] = [];
  maritalStatuses: LookupOptionDto[] = [];
  clients: PatientClientLookupItemDto[] = [];
  rows: DirectoryRow[] = [];

  isLoading = true;
  lookupLoading = false;
  loadError = '';
  statusMessage = '';
  statusError = false;
  activeCommandId = '';
  totalRecords = 0;
  currentPage = 1;
  sharedSearchTerm = '';
  focusedPatientId = '';

  readonly filters = this.fb.nonNullable.group({
    genderId: [0],
    maritalStatusId: [0],
    clientId: [''],
    recordState: ['ACTIVE' as RecordState]
  });

  ngOnInit(): void {
    this.loadLookups();
    this.patientHubSearch.searchTerm$
      .pipe(distinctUntilChanged(), takeUntilDestroyed(this.destroyRef))
      .subscribe((searchTerm) => {
        this.sharedSearchTerm = searchTerm;
        this.currentPage = 1;
        this.loadDirectory();
      });

    this.patientHubSelection.selection$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((selection) => {
        this.focusedPatientId = selection?.idNumber ?? '';
      });
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
  }

  get canManageDeletes(): boolean {
    return this.authService.getCurrentRoles().some((role) => role.toUpperCase() === 'ADMIN');
  }

  get isBusy(): boolean {
    return this.isLoading || this.lookupLoading || this.activeCommandId.length > 0;
  }

  applyFilters(): void {
    this.currentPage = 1;
    this.loadDirectory();
  }

  clearFilters(): void {
    this.filters.reset({
      genderId: 0,
      maritalStatusId: 0,
      clientId: '',
      recordState: 'ACTIVE'
    });
    this.currentPage = 1;
    this.loadDirectory();
  }

  retryLoad(): void {
    this.loadDirectory();
  }

  previousPage(): void {
    if (this.currentPage <= 1 || this.isBusy) {
      return;
    }

    this.currentPage -= 1;
    this.loadDirectory();
  }

  nextPage(): void {
    if (this.currentPage >= this.totalPages || this.isBusy) {
      return;
    }

    this.currentPage += 1;
    this.loadDirectory();
  }

  deletePatient(row: DirectoryRow): void {
    if (!this.canManageDeletes || this.isBusy || row.isDeleted) {
      return;
    }

    this.activeCommandId = row.idNumber;
    this.setStatus('', false);

    this.patientApi.deletePatient(row.idNumber)
      .pipe(finalize(() => {
        this.activeCommandId = '';
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.setStatus(`Patient ${row.patient} deleted successfully.`, false);
            this.loadDirectory();
            return;
          }

          this.setStatus(result.Message || 'Unable to delete patient.', true);
        },
        error: (error) => {
          const message = error?.error?.Message ?? error?.error?.message ?? 'Unable to delete patient right now.';
          this.setStatus(message, true);
        }
      });
  }

  restorePatient(row: DirectoryRow): void {
    if (!this.canManageDeletes || this.isBusy || !row.isDeleted) {
      return;
    }

    this.activeCommandId = row.idNumber;
    this.setStatus('', false);

    this.patientApi.restorePatient(row.idNumber)
      .pipe(finalize(() => {
        this.activeCommandId = '';
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.setStatus(`Patient ${row.patient} restored successfully.`, false);
            this.loadDirectory();
            return;
          }

          this.setStatus(result.Message || 'Unable to restore patient.', true);
        },
        error: (error) => {
          const message = error?.error?.Message ?? error?.error?.message ?? 'Unable to restore patient right now.';
          this.setStatus(message, true);
        }
      });
  }

  isRowBusy(row: DirectoryRow): boolean {
    return this.activeCommandId === row.idNumber;
  }

  focusPatient(row: DirectoryRow): void {
    const locationParts = [row.city, row.province]
      .filter((value) => !value.toLowerCase().startsWith('unknown'));
    const locationLabel = locationParts.length > 0 ? locationParts.join(', ') : 'Location unavailable';

    this.patientHubSelection.focusPatient({
      idNumber: row.idNumber,
      patientLabel: row.patient,
      contextLabel: `${row.primaryClient} • ${row.isDeleted ? 'Deleted record' : 'Active record'} • ${locationLabel}`,
      source: 'directory',
      isDeleted: row.isDeleted
    });
  }

  isFocusedRow(row: DirectoryRow): boolean {
    return this.focusedPatientId === row.idNumber;
  }

  private loadLookups(): void {
    this.lookupLoading = true;

    forkJoin({
      clients: this.patientApi.getClientLookup(),
      genders: this.patientApi.getGenders(),
      maritalStatuses: this.patientApi.getMaritalStatuses()
    })
      .pipe(finalize(() => {
        this.lookupLoading = false;
      }))
      .subscribe({
        next: (lookups) => {
          this.clients = lookups.clients;
          this.genders = lookups.genders;
          this.maritalStatuses = lookups.maritalStatuses;
        },
        error: () => {
          this.setStatus('Unable to load patient-directory filters right now.', true);
        }
      });
  }

  private loadDirectory(): void {
    this.isLoading = true;
    this.loadError = '';

    const value = this.filters.getRawValue();
    const isDeleted = this.resolveDeletedFilter(value.recordState);

    this.patientApi.getDirectory({
      SearchTerm: this.sharedSearchTerm,
      GenderId: value.genderId > 0 ? value.genderId : undefined,
      MaritalStatusId: value.maritalStatusId > 0 ? value.maritalStatusId : undefined,
      ClientId: value.clientId.trim().length > 0 ? value.clientId.trim() : undefined,
      IsDeleted: isDeleted,
      PageNumber: this.currentPage,
      PageSize: this.pageSize
    })
      .pipe(finalize(() => {
        this.isLoading = false;
      }))
      .subscribe({
        next: (snapshot) => {
          this.applySnapshot(snapshot);
        },
        error: () => {
          this.rows = [];
          this.totalRecords = 0;
          this.loadError = 'Unable to load patient directory. Check API connectivity and retry.';
        }
      });
  }

  private applySnapshot(snapshot: PatientDirectorySnapshotDto): void {
    this.rows = Array.isArray(snapshot.Patients)
      ? snapshot.Patients.map((item) => this.mapRow(item))
      : [];
    this.totalRecords = Number.isFinite(snapshot.TotalRecords) ? snapshot.TotalRecords : 0;

    if (this.currentPage > this.totalPages) {
      this.currentPage = this.totalPages;
      this.loadDirectory();
    }
  }

  private mapRow(item: PatientDirectoryItemDto): DirectoryRow {
    const patient = `${this.readText(item.FirstName)} ${this.readText(item.LastName)}`.trim() || 'Unknown Patient';
    const relatedClients = this.resolveClientAssignments(item);
    const primaryClientAssignment = relatedClients.find((client) => client.IsPrimary) ?? relatedClients[0];
    const primaryClient = {
      id: primaryClientAssignment?.ClientId ?? item.ClientId,
      name: this.readText(primaryClientAssignment?.ClientName ?? item.ClientName, 'Unassigned clinic'),
      details: [
        this.readText(primaryClientAssignment?.ClientCode ?? item.ClientCode),
        this.readText(primaryClientAssignment?.ClientClinicCategoryName ?? item.ClientClinicCategoryName)
      ].filter((value) => value.length > 0)
    };

    return {
      patientId: item.PatientId,
      patient,
      idNumber: this.readText(item.IdNumber),
      email: this.readText(item.Email, 'No email'),
      phoneNumber: this.readText(item.PhoneNumber, 'No phone'),
      primaryClient: primaryClient.name,
      clientMeta: this.buildClientMeta(primaryClient, relatedClients),
      city: this.readText(item.CityName, 'Unknown city'),
      province: this.readText(item.ProvinceName, 'Unknown province'),
      dateOfBirth: this.formatDate(item.DateOfBirth),
      updatedOn: this.formatDate(item.UpdatedDate),
      isDeleted: item.IsDeleted
    };
  }

  private resolveClientAssignments(item: PatientDirectoryItemDto): PatientClientAssignmentDto[] {
    if (Array.isArray(item.Clients) && item.Clients.length > 0) {
      return item.Clients;
    }

    if (item.ClientId) {
      return [{
        ClientId: item.ClientId,
        ClientCode: item.ClientCode,
        ClientName: item.ClientName,
        ClientClinicCategoryName: item.ClientClinicCategoryName,
        IsPrimary: true
      }];
    }

    return [];
  }

  private buildClientMeta(
    primaryClient: { id: string | null; name: string; details: string[] },
    relatedClients: PatientClientAssignmentDto[]
  ): string {
    const extraClients = relatedClients.filter((client) => client.ClientId !== primaryClient.id);
    const extraNames = extraClients
      .map((client) => this.readText(client.ClientName || client.ClientCode))
      .filter((value) => value.length > 0);

    const parts: string[] = [];
    if (primaryClient.details.length > 0) {
      parts.push(primaryClient.details.join(' / '));
    }

    if (extraNames.length > 0) {
      const preview = extraNames.slice(0, 2).join(', ');
      const overflow = extraNames.length > 2 ? ` +${extraNames.length - 2} more` : '';
      parts.push(`Also linked: ${preview}${overflow}`);
    }

    return parts.length > 0 ? parts.join(' • ') : 'Primary registration only';
  }

  private resolveDeletedFilter(recordState: RecordState): boolean | undefined {
    if (recordState === 'ACTIVE') {
      return false;
    }

    if (recordState === 'DELETED') {
      return true;
    }

    return undefined;
  }

  private formatDate(value: string | null | undefined): string {
    if (!value) {
      return 'Unknown';
    }

    const directDateMatch = value.trim().match(/^(\d{4}-\d{2}-\d{2})/);
    if (directDateMatch) {
      return directDateMatch[1];
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return 'Unknown';
    }

    const year = `${parsed.getFullYear()}`.padStart(4, '0');
    const month = `${parsed.getMonth() + 1}`.padStart(2, '0');
    const day = `${parsed.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private readText(value: string | null | undefined, fallback = ''): string {
    if (typeof value !== 'string') {
      return fallback;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : fallback;
  }

  private setStatus(message: string, isError: boolean): void {
    this.statusMessage = message;
    this.statusError = isError;
  }

  formatClientOption(option: PatientClientLookupItemDto): string {
    const details = [option.ClientCode.trim(), option.ClientClinicCategoryName.trim()].filter((value) => value.length > 0);
    return details.length > 0 ? `${option.ClientName} (${details.join(' / ')})` : option.ClientName;
  }
}

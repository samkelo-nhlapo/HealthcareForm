import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { finalize } from 'rxjs/operators';
import {
  buildOrganizationName,
  buildOrganizationProfile,
  getOrganizationContent,
  inferOrganizationType,
  readOrganizationSecondaryName
} from '../../client-organization';
import { LookupOptionDto, PatientDirectoryItemDto } from '../../models/patient.models';
import {
  ClientDepartmentDto,
  ClientDepartmentUpdateRequestDto,
  ClientRecordDto,
  ClientStaffDto,
  ClientStaffUpdateRequestDto
} from '../../models/clients.models';
import { ClientsApiService } from '../../services/clients-api.service';
import { PatientApiService } from '../../services/patient-api.service';

const DEPARTMENT_TYPES = ['Clinical', 'Administrative', 'Support', 'Management', 'Allied'] as const;
const STAFF_TYPE_OPTIONS = ['Administrative', 'Clinical', 'Support', 'Management', 'Allied'] as const;
const EMPLOYMENT_TYPE_OPTIONS = ['Full-Time', 'Part-Time', 'Contract', 'Locum'] as const;

@Component({
  selector: 'app-client-detail',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './client-detail.component.html',
  styleUrl: './client-detail.component.scss'
})
export class ClientDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly fb = inject(FormBuilder);
  private readonly clientsApi = inject(ClientsApiService);
  private readonly patientApi = inject(PatientApiService);

  readonly departmentTypes = [...DEPARTMENT_TYPES];
  readonly staffTypeOptions = [...STAFF_TYPE_OPTIONS];
  readonly employmentTypeOptions = [...EMPLOYMENT_TYPE_OPTIONS];

  readonly departmentForm = this.fb.nonNullable.group({
    DepartmentName: ['', [Validators.required, Validators.maxLength(100)]],
    DepartmentCode: ['', [Validators.maxLength(50)]],
    DepartmentType: ['Clinical', [Validators.required]],
    IsActive: [true]
  });

  readonly staffForm = this.fb.nonNullable.group({
    StaffCode: ['', [Validators.required, Validators.maxLength(50)]],
    FirstName: ['', [Validators.required, Validators.maxLength(250)]],
    LastName: ['', [Validators.required, Validators.maxLength(250)]],
    Email: ['', [Validators.email, Validators.maxLength(250)]],
    PhoneNumber: ['', [Validators.maxLength(25)]],
    JobTitle: ['', [Validators.maxLength(150)]],
    Department: ['', [Validators.maxLength(100)]],
    StaffType: ['Administrative', [Validators.required]],
    EmploymentType: ['Full-Time', [Validators.required]],
    HireDate: [''],
    TerminationDate: [''],
    IsPrimaryContact: [false],
    IsActive: [true],
    PrimaryDepartmentId: ['']
  });

  client: ClientRecordDto | null = null;
  departments: ClientDepartmentDto[] = [];
  staff: ClientStaffDto[] = [];
  cities: LookupOptionDto[] = [];
  registeredPatients: PatientDirectoryItemDto[] = [];
  patientTotalRecords = 0;

  editingDepartmentId = '';
  editingStaffId = '';
  departmentSaving = false;
  staffSaving = false;
  staffLoadingRecord = false;
  clientDeleting = false;
  activeDepartmentDeleteId = '';
  activeStaffDeleteId = '';

  isLoading = true;
  loadError = '';
  statusMessage = '';
  statusError = false;

  ngOnInit(): void {
    const clientId = this.currentClientId;
    if (!clientId) {
      this.isLoading = false;
      this.loadError = 'No client ID was supplied for this detail view.';
      return;
    }

    this.loadClientDetail(clientId);
  }

  get currentClientId(): string {
    return this.route.snapshot.paramMap.get('clientId') ?? '';
  }

  get title(): string {
    if (!this.client) {
      return 'Organisation Detail';
    }

    const displayName = this.readText(this.client.DisplayName, '');
    if (displayName) {
      return displayName;
    }

    return buildOrganizationName(
      this.client.FirstName,
      this.client.LastName,
      this.readText(this.client.ClientCode, 'Organisation Detail')
    );
  }

  get canEdit(): boolean {
    return !!this.client && !this.client.IsDeleted;
  }

  get canManageLinkedRecords(): boolean {
    return this.canEdit;
  }

  get departmentFormBusy(): boolean {
    return this.departmentSaving || this.isLoading;
  }

  get staffFormBusy(): boolean {
    return this.staffSaving || this.staffLoadingRecord || this.isLoading;
  }

  get departmentFormTitle(): string {
    return this.editingDepartmentId ? 'Edit Department' : 'Add Department';
  }

  get staffFormTitle(): string {
    return this.editingStaffId ? 'Edit Staff Member' : 'Add Staff Member';
  }

  get activeDepartments(): ClientDepartmentDto[] {
    return this.departments.filter((department) => !department.IsDeleted);
  }

  get organizationType() {
    if (!this.client) {
      return 'CLINIC' as const;
    }

    return inferOrganizationType({
      categoryName: this.client.ClientClinicCategoryName,
      primaryName: this.client.DisplayName || this.client.FirstName,
      secondaryName: this.client.LastName,
      fallback: this.client.OrganizationType?.toUpperCase() === 'HOSPITAL' ? 'HOSPITAL' : 'CLINIC'
    });
  }

  get organizationContent() {
    return getOrganizationContent(this.organizationType);
  }

  get organizationSecondaryName(): string {
    if (!this.client) {
      return '';
    }

    return readOrganizationSecondaryName(this.client.FirstName, this.client.LastName);
  }

  get organizationProfile(): string {
    if (!this.client) {
      return 'Profile not set';
    }

    return buildOrganizationProfile(this.client.ClinicSize, this.client.OwnershipType);
  }

  retryLoad(): void {
    const clientId = this.currentClientId;
    if (!clientId) {
      return;
    }

    this.loadClientDetail(clientId);
  }

  deleteClient(): void {
    if (!this.client || !this.canEdit || this.clientDeleting) {
      return;
    }

    const confirmed = window.confirm(`Delete ${this.title}? This will archive the organisation record.`);
    if (!confirmed) {
      return;
    }

    this.clientDeleting = true;
    this.setStatus('', false);

    this.clientsApi.deleteClient(this.client.ClientId)
      .pipe(finalize(() => {
        this.clientDeleting = false;
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            void this.router.navigate(['/admin/clients']);
            return;
          }

          this.setStatus(result.Message || 'Unable to delete the organisation.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to delete the organisation right now.';
          this.setStatus(message, true);
        }
      });
  }

  saveDepartment(): void {
    if (!this.client || !this.canManageLinkedRecords || this.departmentFormBusy) {
      return;
    }

    if (this.departmentForm.invalid) {
      this.departmentForm.markAllAsTouched();
      this.setStatus('Please complete the department form before saving.', true);
      return;
    }

    const raw = this.departmentForm.getRawValue();
    const isEditingDepartment = this.editingDepartmentId.length > 0;
    const updatePayload: ClientDepartmentUpdateRequestDto = {
      DepartmentName: raw.DepartmentName.trim(),
      DepartmentCode: this.readOptional(raw.DepartmentCode),
      DepartmentType: raw.DepartmentType,
      IsActive: raw.IsActive
    };

    this.departmentSaving = true;
    this.setStatus('', false);

    const request$ = isEditingDepartment
      ? this.clientsApi.updateDepartment(this.editingDepartmentId, updatePayload)
      : this.clientsApi.createDepartment(this.client.ClientId, {
          DepartmentName: updatePayload.DepartmentName,
          DepartmentCode: updatePayload.DepartmentCode,
          DepartmentType: updatePayload.DepartmentType
        });

    request$
      .pipe(finalize(() => {
        this.departmentSaving = false;
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.resetDepartmentEditor();
            this.setStatus(
              isEditingDepartment ? 'Department updated successfully.' : 'Department created successfully.',
              false
            );
            this.loadClientDetail(this.client!.ClientId);
            return;
          }

          this.setStatus(result.Message || 'Unable to save the department.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to save the department right now.';
          this.setStatus(message, true);
        }
      });
  }

  editDepartment(department: ClientDepartmentDto): void {
    this.editingDepartmentId = department.ClientDepartmentId;
    this.departmentForm.patchValue({
      DepartmentName: this.readText(department.DepartmentName, ''),
      DepartmentCode: this.readText(department.DepartmentCode, ''),
      DepartmentType: this.readText(department.DepartmentType, 'Clinical'),
      IsActive: department.IsActive
    });
    this.setStatus('', false);
  }

  cancelDepartmentEdit(): void {
    this.resetDepartmentEditor();
    this.setStatus('', false);
  }

  deleteDepartment(department: ClientDepartmentDto): void {
    if (!this.canManageLinkedRecords || department.IsDeleted || this.activeDepartmentDeleteId.length > 0) {
      return;
    }

    const confirmed = window.confirm(`Delete department "${this.readText(department.DepartmentName)}"?`);
    if (!confirmed) {
      return;
    }

    this.activeDepartmentDeleteId = department.ClientDepartmentId;
    this.setStatus('', false);

    this.clientsApi.deleteDepartment(department.ClientDepartmentId)
      .pipe(finalize(() => {
        this.activeDepartmentDeleteId = '';
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            if (this.editingDepartmentId === department.ClientDepartmentId) {
              this.resetDepartmentEditor();
            }

            this.setStatus('Department deleted successfully.', false);
            this.loadClientDetail(this.client!.ClientId);
            return;
          }

          this.setStatus(result.Message || 'Unable to delete the department.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to delete the department right now.';
          this.setStatus(message, true);
        }
      });
  }

  isDeletingDepartment(departmentId: string): boolean {
    return this.activeDepartmentDeleteId === departmentId;
  }

  saveStaff(): void {
    if (!this.client || !this.canManageLinkedRecords || this.staffFormBusy) {
      return;
    }

    if (this.staffForm.invalid) {
      this.staffForm.markAllAsTouched();
      this.setStatus('Please complete the staff form before saving.', true);
      return;
    }

    const raw = this.staffForm.getRawValue();
    if (raw.HireDate && raw.TerminationDate && raw.TerminationDate < raw.HireDate) {
      this.setStatus('Termination date cannot be earlier than the hire date.', true);
      return;
    }

    const updatePayload: ClientStaffUpdateRequestDto = {
      StaffCode: raw.StaffCode.trim(),
      FirstName: raw.FirstName.trim(),
      LastName: raw.LastName.trim(),
      Email: this.readOptional(raw.Email),
      PhoneNumber: this.readOptional(raw.PhoneNumber),
      JobTitle: this.readOptional(raw.JobTitle),
      Department: this.readOptional(raw.Department),
      StaffType: raw.StaffType.trim(),
      EmploymentType: raw.EmploymentType.trim(),
      HireDate: raw.HireDate || undefined,
      TerminationDate: raw.TerminationDate || undefined,
      IsPrimaryContact: raw.IsPrimaryContact,
      IsActive: raw.IsActive,
      PrimaryDepartmentId: raw.PrimaryDepartmentId || undefined
    };

    this.staffSaving = true;
    this.setStatus('', false);

    const request$ = this.editingStaffId
      ? this.clientsApi.updateStaff(this.editingStaffId, updatePayload)
      : this.clientsApi.createStaff(this.client.ClientId, {
          StaffCode: updatePayload.StaffCode,
          FirstName: updatePayload.FirstName,
          LastName: updatePayload.LastName,
          Email: updatePayload.Email,
          PhoneNumber: updatePayload.PhoneNumber,
          JobTitle: updatePayload.JobTitle,
          Department: updatePayload.Department,
          StaffType: updatePayload.StaffType,
          EmploymentType: updatePayload.EmploymentType,
          HireDate: updatePayload.HireDate,
          IsPrimaryContact: updatePayload.IsPrimaryContact,
          PrimaryDepartmentId: updatePayload.PrimaryDepartmentId
        });

    request$
      .pipe(finalize(() => {
        this.staffSaving = false;
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            const wasEditing = this.editingStaffId.length > 0;
            this.resetStaffEditor();
            this.setStatus(wasEditing ? 'Staff member updated successfully.' : 'Staff member created successfully.', false);
            this.loadClientDetail(this.client!.ClientId);
            return;
          }

          this.setStatus(result.Message || 'Unable to save the staff record.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to save the staff record right now.';
          this.setStatus(message, true);
        }
      });
  }

  editStaff(member: ClientStaffDto): void {
    if (member.IsDeleted || this.staffLoadingRecord) {
      return;
    }

    this.staffLoadingRecord = true;
    this.setStatus('', false);

    this.clientsApi.getStaffRecord(member.ClientStaffId, true)
      .pipe(finalize(() => {
        this.staffLoadingRecord = false;
      }))
      .subscribe({
        next: (record) => {
          this.editingStaffId = record.ClientStaffId;
          this.staffForm.patchValue({
            StaffCode: this.readText(record.StaffCode, ''),
            FirstName: this.readText(record.FirstName, ''),
            LastName: this.readText(record.LastName, ''),
            Email: this.readText(record.Email, ''),
            PhoneNumber: this.readText(record.PhoneNumber, ''),
            JobTitle: this.readText(record.JobTitle, ''),
            Department: this.readText(record.Department, ''),
            StaffType: this.readText(record.StaffType, 'Administrative'),
            EmploymentType: this.readText(record.EmploymentType, 'Full-Time'),
            HireDate: this.toDateInput(record.HireDate),
            TerminationDate: this.toDateInput(record.TerminationDate),
            IsPrimaryContact: record.IsPrimaryContact,
            IsActive: record.IsActive,
            PrimaryDepartmentId: record.PrimaryDepartmentId ?? ''
          });
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to load the staff record for editing.';
          this.setStatus(message, true);
        }
      });
  }

  cancelStaffEdit(): void {
    this.resetStaffEditor();
    this.setStatus('', false);
  }

  deleteStaff(member: ClientStaffDto): void {
    if (!this.canManageLinkedRecords || member.IsDeleted || this.activeStaffDeleteId.length > 0) {
      return;
    }

    const fullName = `${this.readText(member.FirstName, '')} ${this.readText(member.LastName, '')}`.trim() || 'this staff record';
    const confirmed = window.confirm(`Delete ${fullName}?`);
    if (!confirmed) {
      return;
    }

    this.activeStaffDeleteId = member.ClientStaffId;
    this.setStatus('', false);

    this.clientsApi.deleteStaff(member.ClientStaffId)
      .pipe(finalize(() => {
        this.activeStaffDeleteId = '';
      }))
      .subscribe({
        next: (result) => {
          if (result.Success) {
            if (this.editingStaffId === member.ClientStaffId) {
              this.resetStaffEditor();
            }

            this.setStatus('Staff member deleted successfully.', false);
            this.loadClientDetail(this.client!.ClientId);
            return;
          }

          this.setStatus(result.Message || 'Unable to delete the staff record.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to delete the staff record right now.';
          this.setStatus(message, true);
        }
      });
  }

  isDeletingStaff(clientStaffId: string): boolean {
    return this.activeStaffDeleteId === clientStaffId;
  }

  formatDate(value: string | null | undefined, fallback = 'Not available'): string {
    if (!value) {
      return fallback;
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return fallback;
    }

    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    }).format(parsed);
  }

  formatDateTime(value: string | null | undefined): string {
    if (!value) {
      return 'Not available';
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return 'Not available';
    }

    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    }).format(parsed);
  }

  readText(value: string | null | undefined, fallback = 'Not available'): string {
    if (typeof value !== 'string') {
      return fallback;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : fallback;
  }

  getAddress(client: ClientRecordDto): string {
    const segments = [this.readText(client.Line1, ''), this.readText(client.Line2, '')].filter((segment) => segment.length > 0);
    const cityName = this.resolveCityName(client.CityId);
    if (cityName.length > 0) {
      segments.push(cityName);
    }

    if (segments.length > 0) {
      return segments.join(', ');
    }

    const importedSegments = [
      this.readText(client.FacilityAddressText, ''),
      this.getFacilityLocation(client, '')
    ].filter((segment) => segment.length > 0);

    return importedSegments.length > 0 ? importedSegments.join(', ') : 'No address on file';
  }

  getFacilityLocation(client: ClientRecordDto | null, fallback = 'Not recorded'): string {
    if (!client) {
      return fallback;
    }

    const parts = [
      this.readText(client.FacilityTownName, ''),
      this.readText(client.FacilityProvinceName, ''),
      this.readText(client.FacilityCountryName, '')
    ].filter((segment) => segment.length > 0);

    if (parts.length === 0) {
      return fallback;
    }

    if (parts.length >= 2 && parts[parts.length - 1] === 'South Africa') {
      return parts.slice(0, parts.length - 1).join(', ');
    }

    return parts.join(', ');
  }

  getPatientMembershipLabel(patient: PatientDirectoryItemDto): string {
    if (!this.client) {
      return 'Registered patient';
    }

    const assignments = Array.isArray(patient.Clients) ? patient.Clients : [];
    const matchingAssignment = assignments.find((assignment) => assignment.ClientId === this.client?.ClientId);

    if (matchingAssignment?.IsPrimary) {
      return 'Primary registration';
    }

    if (matchingAssignment) {
      return 'Shared registration';
    }

    return 'Registered patient';
  }

  private loadClientDetail(clientId: string): void {
    this.isLoading = true;
    this.loadError = '';

    forkJoin({
      cities: this.clientsApi.getCities(),
      client: this.clientsApi.getClient(clientId, true),
      departments: this.clientsApi.getDepartments({
        ClientId: clientId,
        IsDeleted: undefined,
        PageNumber: 1,
        PageSize: 100
      }),
      staff: this.clientsApi.getStaff({
        ClientId: clientId,
        IsDeleted: undefined,
        PageNumber: 1,
        PageSize: 100
      }),
      patients: this.patientApi.getDirectory({
        ClientId: clientId,
        IsDeleted: undefined,
        PageNumber: 1,
        PageSize: 100
      })
    })
      .pipe(finalize(() => {
        this.isLoading = false;
      }))
      .subscribe({
        next: (result) => {
          this.cities = result.cities;
          this.client = result.client;
          this.departments = Array.isArray(result.departments.Departments) ? result.departments.Departments : [];
          this.staff = Array.isArray(result.staff.Staff) ? result.staff.Staff : [];
          this.registeredPatients = Array.isArray(result.patients.Patients) ? result.patients.Patients : [];
          this.patientTotalRecords = Number.isFinite(result.patients.TotalRecords) ? result.patients.TotalRecords : 0;
        },
        error: (error) => {
          this.cities = [];
          this.client = null;
          this.departments = [];
          this.staff = [];
          this.registeredPatients = [];
          this.patientTotalRecords = 0;
          this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Unable to load the organisation detail view right now.';
        }
      });
  }

  private resolveCityName(cityId: number | null | undefined): string {
    if (typeof cityId !== 'number' || cityId <= 0) {
      return '';
    }

    const match = this.cities.find((city) => city.Id === cityId);
    return match?.Name?.trim() ?? '';
  }

  private resetDepartmentEditor(): void {
    this.editingDepartmentId = '';
    this.departmentForm.reset({
      DepartmentName: '',
      DepartmentCode: '',
      DepartmentType: 'Clinical',
      IsActive: true
    });
  }

  private resetStaffEditor(): void {
    this.editingStaffId = '';
    this.staffForm.reset({
      StaffCode: '',
      FirstName: '',
      LastName: '',
      Email: '',
      PhoneNumber: '',
      JobTitle: '',
      Department: '',
      StaffType: 'Administrative',
      EmploymentType: 'Full-Time',
      HireDate: '',
      TerminationDate: '',
      IsPrimaryContact: false,
      IsActive: true,
      PrimaryDepartmentId: ''
    });
  }

  private readOptional(value: string): string | undefined {
    const normalized = value.trim();
    return normalized.length > 0 ? normalized : undefined;
  }

  private toDateInput(value: string | null | undefined): string {
    if (!value) {
      return '';
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return '';
    }

    return parsed.toISOString().slice(0, 10);
  }

  private setStatus(message: string, isError: boolean): void {
    this.statusMessage = message;
    this.statusError = isError;
  }
}

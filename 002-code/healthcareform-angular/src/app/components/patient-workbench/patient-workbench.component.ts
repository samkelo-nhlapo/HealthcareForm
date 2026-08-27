import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';
import {
  LookupOptionDto,
  PatientClientLookupItemDto,
  PatientCreateRequestDto,
  PatientRecordDto
} from '../../models/patient.models';
import {
  isValidPatientIdNumber,
  normalizePatientIdNumber,
  patientIdNumberValidator
} from '../../models/patient-id.utils';
import { PatientHubSelectionService } from '../../pages/patient-hub/patient-hub-selection.service';
import { PatientApiService } from '../../services/patient-api.service';

type SectionKey = 'demographics' | 'contact' | 'location' | 'emergency' | 'clinical';
type SectionDefinition = {
  key: SectionKey;
  label: string;
  fields: string[];
  required: string[];
};

@Component({
  selector: 'app-patient-workbench',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './patient-workbench.component.html',
  styleUrl: './patient-workbench.component.scss'
})
export class PatientWorkbenchComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly patientHubSelection = inject(PatientHubSelectionService, { optional: true });

  clients: PatientClientLookupItemDto[] = [];
  genders: LookupOptionDto[] = [];
  maritalStatuses: LookupOptionDto[] = [];
  countries: LookupOptionDto[] = [];
  provinces: LookupOptionDto[] = [];
  cities: LookupOptionDto[] = [];

  statusMessage = '';
  statusError = false;
  lastSavedAt: Date | null = null;
  activeSection: SectionKey = 'demographics';
  lookupLoading = false;
  patientLoading = false;
  saving = false;
  deleting = false;
  restoring = false;
  conflictDetected = false;
  conflictMessage = '';
  loadedPatientIdNumber = '';
  primaryClientDropdownOpen = false;
  additionalClientsDropdownOpen = false;
  primaryClientSearchTerm = '';
  additionalClientsSearchTerm = '';

  readonly sections: SectionDefinition[] = [
    {
      key: 'demographics',
      label: 'Demographics',
      fields: ['PrimaryClientId', 'SecondaryClientIds', 'FirstName', 'LastName', 'IdNumber', 'DateOfBirth', 'GenderId', 'MaritalStatusId'],
      required: ['PrimaryClientId', 'FirstName', 'LastName', 'IdNumber', 'DateOfBirth', 'GenderId', 'MaritalStatusId']
    },
    {
      key: 'contact',
      label: 'Contact',
      fields: ['PhoneNumber', 'Email'],
      required: ['PhoneNumber', 'Email']
    },
    {
      key: 'location',
      label: 'Location',
      fields: ['Line1', 'Line2', 'CityId', 'ProvinceId', 'CountryId'],
      required: ['Line1', 'Line2', 'CityId', 'ProvinceId', 'CountryId']
    },
    {
      key: 'emergency',
      label: 'Emergency Contact',
      fields: ['EmergencyName', 'EmergencyLastName', 'EmergencyPhoneNumber', 'Relationship', 'EmergencyDateOfBirth'],
      required: ['EmergencyName', 'EmergencyLastName', 'EmergencyPhoneNumber', 'Relationship', 'EmergencyDateOfBirth']
    },
    {
      key: 'clinical',
      label: 'Clinical Notes',
      fields: ['MedicationList'],
      required: []
    }
  ];

  readonly searchForm = this.fb.nonNullable.group({
    idNumber: ['', [Validators.required, patientIdNumberValidator()]]
  });

  readonly patientForm = this.fb.nonNullable.group({
    PrimaryClientId: ['', Validators.required],
    SecondaryClientIds: this.fb.nonNullable.control<string[]>([]),
    FirstName: ['', [Validators.required, Validators.maxLength(30)]],
    LastName: ['', [Validators.required, Validators.maxLength(30)]],
    IdNumber: ['', [Validators.required, patientIdNumberValidator()]],
    DateOfBirth: ['', Validators.required],
    GenderId: [0, [Validators.required, Validators.min(1)]],
    PhoneNumber: ['', Validators.required],
    Email: ['', [Validators.required, Validators.email]],
    Line1: ['', Validators.required],
    Line2: ['', Validators.required],
    CityId: [0, [Validators.required, Validators.min(1)]],
    ProvinceId: [0, [Validators.required, Validators.min(1)]],
    CountryId: [0, [Validators.required, Validators.min(1)]],
    MaritalStatusId: [0, [Validators.required, Validators.min(1)]],
    EmergencyName: ['', Validators.required],
    EmergencyLastName: ['', Validators.required],
    EmergencyPhoneNumber: ['', Validators.required],
    Relationship: ['', Validators.required],
    EmergencyDateOfBirth: ['', Validators.required],
    MedicationList: ['']
  });

  constructor(private readonly patientApi: PatientApiService) {}

  ngOnInit(): void {
    this.loadLookups();
    this.route.queryParamMap.subscribe((params) => {
      const idNumber = normalizePatientIdNumber(params.get('idNumber'));
      if (!isValidPatientIdNumber(idNumber)) {
        if (this.loadedPatientIdNumber || this.searchForm.getRawValue().idNumber.trim().length > 0) {
          this.prepareNewRegistration();
        }

        return;
      }

      if (idNumber === this.loadedPatientIdNumber) {
        if (idNumber !== this.searchForm.getRawValue().idNumber) {
          this.searchForm.patchValue({ idNumber });
        }

        return;
      }

      this.searchForm.patchValue({ idNumber });
      this.getPatient();
    });
  }

  createPatient(): void {
    if (this.saving || this.deleting || this.restoring || this.patientLoading) {
      return;
    }

    this.normalizePatientFormInputs();
    if (this.patientForm.invalid) {
      this.patientForm.markAllAsTouched();
      this.setStatus('Please complete all required patient fields.', true);
      return;
    }

    const payload = this.buildNormalizedPatientPayload();
    this.saving = true;
    this.clearConflict();
    this.patientApi.createPatient(payload)
      .pipe(
        finalize(() => {
          this.saving = false;
        })
      )
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.lastSavedAt = new Date();
            this.loadedPatientIdNumber = payload.IdNumber.trim();
            this.searchForm.patchValue({ idNumber: this.loadedPatientIdNumber });
            this.syncFocusedPatientFromForm(false);
            this.syncHubPatientContext(this.loadedPatientIdNumber);
            this.patientForm.markAsPristine();
            this.setStatus('Patient saved successfully.', false);
            return;
          }

          this.setStatus(result.Message || 'Unable to save patient.', true);
        },
        error: (error) => {
          if (this.handleConflictError('create', error)) {
            return;
          }

          const message = error?.error?.Message ?? error?.error?.message ?? 'Unable to save patient right now.';
          this.setStatus(message, true);
        }
      });
  }

  updatePatient(): void {
    if (this.saving || this.deleting || this.restoring || this.patientLoading) {
      return;
    }

    this.normalizePatientFormInputs();
    if (this.patientForm.invalid) {
      this.patientForm.markAllAsTouched();
      this.setStatus('Please complete all required patient fields before updating.', true);
      return;
    }

    const idNumber = this.resolveIdNumberForUpdate();
    if (!idNumber) {
      this.setStatus('Load the patient record you want to update first.', true);
      return;
    }

    const payload = this.buildNormalizedPatientPayload();
    const updatePayload = {
      FirstName: payload.FirstName,
      LastName: payload.LastName,
      DateOfBirth: payload.DateOfBirth,
      PrimaryClientId: payload.PrimaryClientId,
      SecondaryClientIds: payload.SecondaryClientIds,
      GenderId: payload.GenderId,
      PhoneNumber: payload.PhoneNumber,
      Email: payload.Email,
      Line1: payload.Line1,
      Line2: payload.Line2,
      CityId: payload.CityId,
      ProvinceId: payload.ProvinceId,
      CountryId: payload.CountryId,
      MaritalStatusId: payload.MaritalStatusId,
      EmergencyName: payload.EmergencyName,
      EmergencyLastName: payload.EmergencyLastName,
      EmergencyPhoneNumber: payload.EmergencyPhoneNumber,
      Relationship: payload.Relationship,
      EmergencyDateOfBirth: payload.EmergencyDateOfBirth,
      MedicationList: payload.MedicationList
    };

    this.saving = true;
    this.clearConflict();
    this.patientApi.updatePatient(idNumber, updatePayload)
      .pipe(
        finalize(() => {
          this.saving = false;
        })
      )
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.lastSavedAt = new Date();
            this.syncFocusedPatientFromForm(false);
            this.patientForm.markAsPristine();
            this.setStatus('Patient updated successfully.', false);
            return;
          }

          this.setStatus(result.Message || 'Unable to update patient.', true);
        },
        error: (error) => {
          if (this.handleConflictError('update', error)) {
            return;
          }

          const message = error?.error?.Message ?? error?.error?.message ?? 'Unable to update patient right now.';
          this.setStatus(message, true);
        }
      });
  }

  getPatient(): void {
    if (this.patientLoading || this.saving || this.deleting || this.restoring) {
      return;
    }

    const idNumber = this.normalizeSearchFormInput();
    if (this.searchForm.invalid) {
      this.searchForm.markAllAsTouched();
      this.setStatus('Enter a valid 13-digit ID number to search.', true);
      return;
    }

    this.loadPatientById(idNumber);
  }

  deletePatient(): void {
    if (this.deleting || this.saving || this.patientLoading || this.restoring) {
      return;
    }

    const idNumber = this.resolveIdNumberForRecordAction('delete');
    if (!idNumber) {
      return;
    }

    this.deleting = true;
    this.clearConflict();
    this.patientApi.deletePatient(idNumber)
      .pipe(
        finalize(() => {
          this.deleting = false;
        })
      )
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.loadedPatientIdNumber = '';
            this.searchForm.patchValue({ idNumber });
            this.patientHubSelection?.focusPatient({
              idNumber,
              patientLabel: this.readPatientLabel(),
              contextLabel: 'Deleted record kept in focus so it can be restored or reviewed in the hub.',
              source: 'registration',
              isDeleted: true
            });
            this.syncHubPatientContext(idNumber);
            this.resetPatientForm();
            this.setStatus('Patient deleted successfully.', false);
            return;
          }

          this.setStatus(result.Message || 'Unable to delete patient.', true);
        },
        error: (error) => {
          if (this.handleConflictError('delete', error)) {
            return;
          }

          const message = error?.error?.Message ?? error?.error?.message ?? 'Unable to delete patient right now.';
          this.setStatus(message, true);
        }
      });
  }

  restorePatient(): void {
    if (this.restoring || this.deleting || this.saving || this.patientLoading) {
      return;
    }

    const idNumber = this.resolveIdNumberForRecordAction('restore');
    if (!idNumber) {
      return;
    }

    this.restoring = true;
    this.clearConflict();
    this.patientApi.restorePatient(idNumber)
      .pipe(
        finalize(() => {
          this.restoring = false;
        })
      )
      .subscribe({
        next: (result) => {
          if (result.Success) {
            this.loadPatientById(idNumber, 'Patient restored and loaded successfully.');
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

  private loadLookups(): void {
    this.lookupLoading = true;
    forkJoin({
      clients: this.patientApi.getClientLookup(),
      genders: this.patientApi.getGenders(),
      maritalStatuses: this.patientApi.getMaritalStatuses(),
      countries: this.patientApi.getCountries(),
      provinces: this.patientApi.getProvinces(),
      cities: this.patientApi.getCities()
    })
      .pipe(
        finalize(() => {
          this.lookupLoading = false;
        })
      )
      .subscribe({
        next: (lookups) => {
          this.clients = lookups.clients;
          this.genders = lookups.genders;
          this.maritalStatuses = lookups.maritalStatuses;
          this.countries = lookups.countries;
          this.provinces = lookups.provinces;
          this.cities = lookups.cities;
        },
        error: () => {
          this.setStatus('Failed to load lookup values from backend API.', true);
        }
      });
  }

  reloadLatestPatient(): void {
    const idNumber = this.resolveIdNumberForUpdate();
    if (!idNumber) {
      this.setStatus('Cannot reload latest profile because no patient ID is available.', true);
      return;
    }

    this.searchForm.patchValue({ idNumber });
    this.loadPatientById(idNumber);
  }

  get hasPendingRequest(): boolean {
    return this.lookupLoading || this.patientLoading || this.saving || this.deleting || this.restoring;
  }

  get selectedPrimaryClientLabel(): string {
    const primaryClientId = this.patientForm.controls.PrimaryClientId.value;
    if (primaryClientId.trim().length === 0) {
      return 'Search and select clinic or hospital';
    }

    const selectedClient = this.clients.find((client) => client.ClientId === primaryClientId);
    return selectedClient ? this.formatClientOption(selectedClient) : 'Search and select clinic or hospital';
  }

  get filteredPrimaryClients(): PatientClientLookupItemDto[] {
    return this.clients.filter((client) => this.matchesClientSearch(client, this.primaryClientSearchTerm));
  }

  get selectedAdditionalClientsSummary(): string {
    const selectedIds = this.patientForm.controls.SecondaryClientIds.value;
    if (selectedIds.length === 0) {
      return 'Search and select additional clinics or hospitals';
    }

    const selectedLabels = selectedIds
      .map((clientId) => this.clients.find((client) => client.ClientId === clientId))
      .filter((client): client is PatientClientLookupItemDto => !!client)
      .map((client) => client.ClientName.trim())
      .filter((label) => label.length > 0);

    if (selectedLabels.length === 0) {
      return `${selectedIds.length} additional clinics selected`;
    }

    if (selectedLabels.length <= 2) {
      return selectedLabels.join(', ');
    }

    return `${selectedLabels.length} additional clinics selected`;
  }

  get filteredAdditionalClients(): PatientClientLookupItemDto[] {
    return this.availableAdditionalClients.filter((client) => this.matchesClientSearch(client, this.additionalClientsSearchTerm));
  }

  private loadPatientById(idNumber: string, successMessage = 'Patient loaded successfully.'): void {
    const normalizedIdNumber = normalizePatientIdNumber(idNumber);
    this.patientLoading = true;
    this.clearConflict();
    this.patientApi.getPatient(normalizedIdNumber)
      .pipe(
        finalize(() => {
          this.patientLoading = false;
        })
      )
      .subscribe({
        next: (patient) => {
          this.patchPatientForm(patient);
          this.loadedPatientIdNumber = patient.IdNumber.trim();
          this.searchForm.patchValue({ idNumber: this.loadedPatientIdNumber });
          this.syncFocusedPatient(patient);
          this.syncHubPatientContext(this.loadedPatientIdNumber);
          this.setStatus(successMessage, false);
        },
        error: (error) => {
          const rawMessage = error?.error?.Message ?? error?.error?.message ?? 'Patient not found.';
          if (typeof rawMessage === 'string' && rawMessage.toLowerCase().includes('soft deleted')) {
            this.patientHubSelection?.focusPatient({
              idNumber: normalizedIdNumber,
              patientLabel: this.patientHubSelection?.selection?.idNumber === normalizedIdNumber
                ? this.patientHubSelection.selection.patientLabel
                : `Patient ${normalizedIdNumber}`,
              contextLabel: 'Deleted record. Restore it in registration before opening chart or encounter workflows.',
              source: 'registration',
              isDeleted: true
            });
          }

          const message = typeof rawMessage === 'string' && rawMessage.toLowerCase().includes('soft deleted')
            ? `${rawMessage} Use Restore Patient to reactivate it.`
            : rawMessage;
          this.setStatus(message, true);
        }
      });
  }

  private patchPatientForm(patient: PatientRecordDto): void {
    const primaryClientId = patient.ClientId ?? patient.Clients.find((client) => client.IsPrimary)?.ClientId ?? '';
    const secondaryClientIds = patient.Clients
      .filter((client) => client.ClientId !== primaryClientId)
      .map((client) => client.ClientId);

    this.patientForm.patchValue({
      PrimaryClientId: primaryClientId,
      SecondaryClientIds: secondaryClientIds,
      FirstName: patient.FirstName,
      LastName: patient.LastName,
      IdNumber: patient.IdNumber,
      DateOfBirth: this.toDateInputValue(patient.DateOfBirth),
      GenderId: patient.GenderId,
      PhoneNumber: patient.PhoneNumber,
      Email: patient.Email,
      Line1: patient.Line1,
      Line2: patient.Line2,
      CityId: patient.CityId,
      ProvinceId: patient.ProvinceId,
      CountryId: patient.CountryId,
      MaritalStatusId: patient.MaritalStatusId,
      EmergencyName: patient.EmergencyName,
      EmergencyLastName: patient.EmergencyLastName,
      EmergencyPhoneNumber: patient.EmergencyPhoneNumber,
      Relationship: patient.Relationship,
      EmergencyDateOfBirth: this.toDateInputValue(patient.EmergencyDateOfBirth),
      MedicationList: patient.MedicationList
    });
    this.resetClientDropdownState();
    this.patientForm.markAsPristine();
  }

  private resetPatientForm(): void {
    this.patientForm.reset({
      PrimaryClientId: '',
      SecondaryClientIds: [],
      FirstName: '',
      LastName: '',
      IdNumber: '',
      DateOfBirth: '',
      GenderId: 0,
      PhoneNumber: '',
      Email: '',
      Line1: '',
      Line2: '',
      CityId: 0,
      ProvinceId: 0,
      CountryId: 0,
      MaritalStatusId: 0,
      EmergencyName: '',
      EmergencyLastName: '',
      EmergencyPhoneNumber: '',
      Relationship: '',
      EmergencyDateOfBirth: '',
      MedicationList: ''
    });
    this.resetClientDropdownState();
    this.patientForm.markAsPristine();
  }

  private prepareNewRegistration(): void {
    this.loadedPatientIdNumber = '';
    this.searchForm.reset({ idNumber: '' });
    this.resetPatientForm();
    this.clearConflict();
  }

  private toDateInputValue(value: string): string {
    const directDateMatch = (value ?? '').trim().match(/^(\d{4}-\d{2}-\d{2})/);
    if (directDateMatch) {
      return directDateMatch[1];
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return '';
    }

    const year = `${parsed.getFullYear()}`.padStart(4, '0');
    const month = `${parsed.getMonth() + 1}`.padStart(2, '0');
    const day = `${parsed.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private setStatus(message: string, isError: boolean): void {
    this.statusMessage = message;
    this.statusError = isError;
  }

  private clearConflict(): void {
    this.conflictDetected = false;
    this.conflictMessage = '';
  }

  private handleConflictError(action: 'create' | 'update' | 'delete', error: unknown): boolean {
    const status = this.extractStatusCode(error);
    if (status !== 409 && status !== 412) {
      return false;
    }

    if (action === 'create') {
      this.conflictMessage = 'A patient record for this ID already exists. Load latest profile before creating again.';
    } else if (action === 'delete') {
      this.conflictMessage = 'Record changed on the server before delete. Reload latest profile and retry.';
    } else {
      this.conflictMessage = 'Profile changed on the server while you were editing. Reload latest and apply changes again.';
    }

    this.conflictDetected = true;
    this.setStatus(this.conflictMessage, true);
    return true;
  }

  private extractStatusCode(error: unknown): number {
    if (!error || typeof error !== 'object') {
      return 0;
    }

    const value = (error as { status?: unknown }).status;
    return typeof value === 'number' ? value : 0;
  }

  get sectionIndex(): number {
    return this.sections.findIndex((section) => section.key === this.activeSection);
  }

  get completedSectionsCount(): number {
    return this.sections.filter((section) => this.getSectionState(section.key) === 'complete').length;
  }

  setActiveSection(section: SectionKey): void {
    this.activeSection = section;
  }

  nextSection(): void {
    const next = this.sections[this.sectionIndex + 1];
    if (next) {
      this.activeSection = next.key;
    }
  }

  previousSection(): void {
    const previous = this.sections[this.sectionIndex - 1];
    if (previous) {
      this.activeSection = previous.key;
    }
  }

  getSectionState(sectionKey: SectionKey): 'complete' | 'in-progress' | 'empty' {
    const section = this.sections.find((item) => item.key === sectionKey);
    if (!section) {
      return 'empty';
    }

    const hasAnyValue = section.fields.some((field) => this.controlHasValue(field));
    const requiredValid = section.required.every((field) => this.controlIsValid(field));

    if (!hasAnyValue) {
      return 'empty';
    }

    if (requiredValid) {
      return 'complete';
    }

    return 'in-progress';
  }

  private controlHasValue(controlName: string): boolean {
    const control = this.patientForm.get(controlName);
    if (!control) {
      return false;
    }

    const value = control.value;
    if (Array.isArray(value)) {
      return value.length > 0;
    }

    if (typeof value === 'string') {
      return value.trim().length > 0;
    }

    if (typeof value === 'number') {
      return value > 0;
    }

    return value !== null && value !== undefined;
  }

  private controlIsValid(controlName: string): boolean {
    const control = this.patientForm.get(controlName);
    if (!control) {
      return false;
    }

    return control.valid && this.controlHasValue(controlName);
  }

  private resolveIdNumberForUpdate(): string {
    const formId = normalizePatientIdNumber(this.patientForm.getRawValue().IdNumber);

    if (isValidPatientIdNumber(this.loadedPatientIdNumber)) {
      return this.loadedPatientIdNumber;
    }

    if (isValidPatientIdNumber(formId)) {
      return formId;
    }

    return '';
  }

  private resolveIdNumberForRecordAction(action: 'delete' | 'restore'): string {
    const lookupId = this.normalizeSearchFormInput();
    if (isValidPatientIdNumber(this.loadedPatientIdNumber)) {
      if (isValidPatientIdNumber(lookupId) && lookupId !== this.loadedPatientIdNumber) {
        this.setStatus(
          `Load patient ${lookupId} before trying to ${action}, or clear the lookup field to ${action} the currently loaded record.`,
          true
        );
        return '';
      }

      return this.loadedPatientIdNumber;
    }

    if (isValidPatientIdNumber(lookupId)) {
      return lookupId;
    }

    this.searchForm.markAllAsTouched();
    this.setStatus(`Enter a valid 13-digit ID number to ${action}.`, true);
    return '';
  }

  private syncHubPatientContext(idNumber: string): void {
    const normalizedIdNumber = idNumber.trim();
    if (this.route.snapshot.queryParamMap.get('idNumber') === normalizedIdNumber) {
      return;
    }

    void this.router.navigate(['/patients/registration'], {
      queryParams: { idNumber: normalizedIdNumber || null },
      queryParamsHandling: 'merge',
      replaceUrl: true
    });
  }

  private syncFocusedPatient(patient: PatientRecordDto): void {
    const patientLabel = `${patient.FirstName} ${patient.LastName}`.trim() || patient.IdNumber.trim();
    const primaryClientName = this.resolvePrimaryClientName(patient);
    const linkedClientCount = patient.Clients.length > 0 ? patient.Clients.length : 1;
    const linkedClientLabel = linkedClientCount > 1 ? ` • ${linkedClientCount} linked clinics` : '';

    this.patientHubSelection?.focusPatient({
      idNumber: patient.IdNumber,
      patientLabel,
      contextLabel: `${primaryClientName}${linkedClientLabel}`,
      source: 'registration',
      isDeleted: false
    });
  }

  private syncFocusedPatientFromForm(isDeleted: boolean): void {
    const value = this.patientForm.getRawValue();
    const idNumber = normalizePatientIdNumber(value.IdNumber) || this.loadedPatientIdNumber;
    if (!isValidPatientIdNumber(idNumber)) {
      return;
    }

    const secondaryCount = value.SecondaryClientIds
      .map((clientId) => clientId.trim())
      .filter((clientId) => clientId.length > 0)
      .length;
    const primaryClientName = this.lookupClientName(value.PrimaryClientId);
    const linkedClientCount = value.PrimaryClientId.trim().length > 0 ? secondaryCount + 1 : secondaryCount;
    const linkedClientLabel = linkedClientCount > 1 ? ` • ${linkedClientCount} linked clinics` : '';

    this.patientHubSelection?.focusPatient({
      idNumber,
      patientLabel: this.readPatientLabel(),
      contextLabel: isDeleted
        ? 'Deleted record kept in focus so it can be restored or reviewed in the hub.'
        : `${primaryClientName}${linkedClientLabel}`,
      source: 'registration',
      isDeleted
    });
  }

  private resolvePrimaryClientName(patient: PatientRecordDto): string {
    const primaryClient = patient.Clients.find((client) => client.IsPrimary) ?? patient.Clients[0];
    if (primaryClient?.ClientName?.trim()) {
      return primaryClient.ClientName.trim();
    }

    if (patient.ClientName.trim()) {
      return patient.ClientName.trim();
    }

    return 'Clinic assignment pending';
  }

  private lookupClientName(clientId: string): string {
    if (clientId.trim().length === 0) {
      return 'Clinic assignment pending';
    }

    return this.clients.find((client) => client.ClientId === clientId)?.ClientName ?? 'Clinic assignment pending';
  }

  private readPatientLabel(): string {
    const value = this.patientForm.getRawValue();
    return `${value.FirstName} ${value.LastName}`.trim() || this.loadedPatientIdNumber || value.IdNumber.trim();
  }

  private normalizeSearchFormInput(): string {
    const currentValue = this.searchForm.getRawValue().idNumber;
    const normalizedValue = normalizePatientIdNumber(currentValue);
    if (normalizedValue !== currentValue) {
      this.searchForm.patchValue({ idNumber: normalizedValue }, { emitEvent: false });
    }

    return normalizedValue;
  }

  private normalizePatientFormInputs(): void {
    this.patientForm.patchValue(this.buildNormalizedPatientPayload(), { emitEvent: false });
  }

  private buildNormalizedPatientPayload(): PatientCreateRequestDto {
    const value = this.patientForm.getRawValue();
    const primaryClientId = this.normalizeText(value.PrimaryClientId);
    const secondaryClientIds = value.SecondaryClientIds
      .map((clientId) => this.normalizeText(clientId))
      .filter((clientId) => clientId.length > 0 && clientId !== primaryClientId);

    return {
      PrimaryClientId: primaryClientId,
      SecondaryClientIds: [...new Set(secondaryClientIds)],
      FirstName: this.normalizeText(value.FirstName),
      LastName: this.normalizeText(value.LastName),
      IdNumber: normalizePatientIdNumber(value.IdNumber),
      DateOfBirth: this.normalizeText(value.DateOfBirth),
      GenderId: value.GenderId,
      PhoneNumber: this.normalizeText(value.PhoneNumber),
      Email: this.normalizeText(value.Email),
      Line1: this.normalizeText(value.Line1),
      Line2: this.normalizeText(value.Line2),
      CityId: value.CityId,
      ProvinceId: value.ProvinceId,
      CountryId: value.CountryId,
      MaritalStatusId: value.MaritalStatusId,
      EmergencyName: this.normalizeText(value.EmergencyName),
      EmergencyLastName: this.normalizeText(value.EmergencyLastName),
      EmergencyPhoneNumber: this.normalizeText(value.EmergencyPhoneNumber),
      Relationship: this.normalizeText(value.Relationship),
      EmergencyDateOfBirth: this.normalizeText(value.EmergencyDateOfBirth),
      MedicationList: this.normalizeText(value.MedicationList)
    };
  }

  private normalizeText(value: string): string {
    return (value ?? '').trim();
  }

  formatClientOption(option: PatientClientLookupItemDto): string {
    const details = [option.ClientCode.trim(), option.ClientClinicCategoryName.trim()].filter((value) => value.length > 0);
    return details.length > 0 ? `${option.ClientName} (${details.join(' / ')})` : option.ClientName;
  }

  get availableAdditionalClients(): PatientClientLookupItemDto[] {
    const primaryClientId = this.patientForm.controls.PrimaryClientId.value;
    return this.clients.filter((client) => client.ClientId !== primaryClientId);
  }

  onPrimaryClientChange(primaryClientId: string): void {
    const currentSecondaryIds = this.patientForm.controls.SecondaryClientIds.value;
    if (!currentSecondaryIds.includes(primaryClientId)) {
      return;
    }

    this.patientForm.controls.SecondaryClientIds.setValue(
      currentSecondaryIds.filter((clientId) => clientId !== primaryClientId)
    );
    this.patientForm.controls.SecondaryClientIds.markAsDirty();
  }

  togglePrimaryClientDropdown(): void {
    if (this.hasPendingRequest) {
      return;
    }

    this.primaryClientDropdownOpen = !this.primaryClientDropdownOpen;
    if (this.primaryClientDropdownOpen) {
      this.additionalClientsDropdownOpen = false;
    } else {
      this.primaryClientSearchTerm = '';
    }
  }

  toggleAdditionalClientsDropdown(): void {
    if (this.hasPendingRequest) {
      return;
    }

    this.additionalClientsDropdownOpen = !this.additionalClientsDropdownOpen;
    if (this.additionalClientsDropdownOpen) {
      this.primaryClientDropdownOpen = false;
    } else {
      this.additionalClientsSearchTerm = '';
    }
  }

  setPrimaryClientSearchTerm(value: string): void {
    this.primaryClientSearchTerm = value;
  }

  setAdditionalClientsSearchTerm(value: string): void {
    this.additionalClientsSearchTerm = value;
  }

  selectPrimaryClient(clientId: string): void {
    const normalizedClientId = clientId.trim();
    this.patientForm.controls.PrimaryClientId.setValue(normalizedClientId);
    this.patientForm.controls.PrimaryClientId.markAsDirty();
    this.onPrimaryClientChange(normalizedClientId);
    this.primaryClientDropdownOpen = false;
    this.primaryClientSearchTerm = '';
  }

  clearPrimaryClientSelection(): void {
    this.patientForm.controls.PrimaryClientId.setValue('');
    this.patientForm.controls.PrimaryClientId.markAsDirty();
    this.primaryClientDropdownOpen = false;
    this.primaryClientSearchTerm = '';
  }

  clearAdditionalClientSelections(): void {
    this.patientForm.controls.SecondaryClientIds.setValue([]);
    this.patientForm.controls.SecondaryClientIds.markAsDirty();
  }

  isSecondaryClientSelected(clientId: string): boolean {
    return this.patientForm.controls.SecondaryClientIds.value.includes(clientId);
  }

  toggleSecondaryClient(clientId: string, selected: boolean): void {
    const currentSecondaryIds = this.patientForm.controls.SecondaryClientIds.value;
    const nextSecondaryIds = selected
      ? [...currentSecondaryIds, clientId]
      : currentSecondaryIds.filter((currentId) => currentId !== clientId);

    this.patientForm.controls.SecondaryClientIds.setValue([...new Set(nextSecondaryIds)]);
    this.patientForm.controls.SecondaryClientIds.markAsDirty();
  }

  private resetClientDropdownState(): void {
    this.primaryClientDropdownOpen = false;
    this.additionalClientsDropdownOpen = false;
    this.primaryClientSearchTerm = '';
    this.additionalClientsSearchTerm = '';
  }

  private matchesClientSearch(option: PatientClientLookupItemDto, searchTerm: string): boolean {
    const normalizedSearchTerm = this.normalizeText(searchTerm).toLowerCase();
    if (normalizedSearchTerm.length === 0) {
      return true;
    }

    const searchableText = [
      option.ClientName,
      option.ClientCode,
      option.ClientClinicCategoryName,
      this.formatClientOption(option)
    ]
      .map((value) => this.normalizeText(value).toLowerCase())
      .join(' ');

    return searchableText.includes(normalizedSearchTerm);
  }
}

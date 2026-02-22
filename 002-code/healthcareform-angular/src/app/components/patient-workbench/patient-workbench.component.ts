import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';
import { LookupOptionDto, PatientCreateRequestDto, PatientRecordDto } from '../../models/patient.models';
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
  conflictDetected = false;
  conflictMessage = '';

  readonly sections: SectionDefinition[] = [
    {
      key: 'demographics',
      label: 'Demographics',
      fields: ['FirstName', 'LastName', 'IdNumber', 'DateOfBirth', 'GenderId', 'MaritalStatusId'],
      required: ['FirstName', 'LastName', 'IdNumber', 'DateOfBirth', 'GenderId', 'MaritalStatusId']
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
    idNumber: ['', [Validators.required, Validators.minLength(13), Validators.maxLength(13)]]
  });

  readonly patientForm = this.fb.nonNullable.group({
    FirstName: ['', [Validators.required, Validators.maxLength(30)]],
    LastName: ['', [Validators.required, Validators.maxLength(30)]],
    IdNumber: ['', [Validators.required, Validators.minLength(13), Validators.maxLength(13)]],
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

  constructor(
    private readonly patientApi: PatientApiService,
    private readonly route: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.loadLookups();
    this.route.queryParamMap.subscribe((params) => {
      const idNumber = (params.get('idNumber') ?? '').trim();
      if (idNumber.length !== 13) {
        return;
      }

      if (idNumber === this.searchForm.getRawValue().idNumber) {
        return;
      }

      this.searchForm.patchValue({ idNumber });
      this.getPatient();
    });
  }

  createPatient(): void {
    if (this.saving || this.deleting || this.patientLoading) {
      return;
    }

    if (this.patientForm.invalid) {
      this.patientForm.markAllAsTouched();
      this.setStatus('Please complete all required patient fields.', true);
      return;
    }

    const payload = this.patientForm.getRawValue() as PatientCreateRequestDto;
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
    if (this.saving || this.deleting || this.patientLoading) {
      return;
    }

    if (this.patientForm.invalid) {
      this.patientForm.markAllAsTouched();
      this.setStatus('Please complete all required patient fields before updating.', true);
      return;
    }

    const idNumber = this.resolveIdNumberForUpdate();
    if (!idNumber) {
      this.setStatus('Search and load a patient first, or provide a valid ID number.', true);
      return;
    }

    const payload = this.patientForm.getRawValue();
    const updatePayload = {
      FirstName: payload.FirstName,
      LastName: payload.LastName,
      DateOfBirth: payload.DateOfBirth,
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
    if (this.patientLoading || this.saving || this.deleting) {
      return;
    }

    if (this.searchForm.invalid) {
      this.searchForm.markAllAsTouched();
      this.setStatus('Enter a valid 13-digit ID number to search.', true);
      return;
    }

    const idNumber = this.searchForm.getRawValue().idNumber;
    this.loadPatientById(idNumber);
  }

  deletePatient(): void {
    if (this.deleting || this.saving || this.patientLoading) {
      return;
    }

    if (this.searchForm.invalid) {
      this.searchForm.markAllAsTouched();
      this.setStatus('Enter a valid 13-digit ID number to delete.', true);
      return;
    }

    const idNumber = this.searchForm.getRawValue().idNumber;
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
            this.patientForm.reset({
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
            this.patientForm.markAsPristine();
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

  private loadLookups(): void {
    this.lookupLoading = true;
    forkJoin({
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
    return this.lookupLoading || this.patientLoading || this.saving || this.deleting;
  }

  private loadPatientById(idNumber: string): void {
    this.patientLoading = true;
    this.clearConflict();
    this.patientApi.getPatient(idNumber)
      .pipe(
        finalize(() => {
          this.patientLoading = false;
        })
      )
      .subscribe({
        next: (patient) => {
          this.patchPatientForm(patient);
          this.setStatus('Patient loaded successfully.', false);
        },
        error: (error) => {
          const message = error?.error?.Message ?? error?.error?.message ?? 'Patient not found.';
          this.setStatus(message, true);
        }
      });
  }

  private patchPatientForm(patient: PatientRecordDto): void {
    this.patientForm.patchValue({
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
    this.patientForm.markAsPristine();
  }

  private toDateInputValue(value: string): string {
    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return '';
    }

    return parsed.toISOString().split('T')[0] ?? '';
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
    const searchedId = (this.searchForm.getRawValue().idNumber ?? '').trim();
    const formId = (this.patientForm.getRawValue().IdNumber ?? '').trim();

    if (searchedId.length === 13) {
      return searchedId;
    }

    if (formId.length === 13) {
      return formId;
    }

    return '';
  }
}

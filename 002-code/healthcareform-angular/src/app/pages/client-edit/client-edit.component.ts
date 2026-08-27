import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';
import {
  OrganizationType,
  buildOrganizationName,
  categoryMatchesOrganizationType,
  describeCategoryOption,
  getOrganizationContent,
  inferOrganizationType,
  readOrganizationSecondaryName
} from '../../client-organization';
import {
  ClientClinicCategoryDto,
  ClientRecordDto,
  ClientUpdateRequestDto
} from '../../models/clients.models';
import { LookupOptionDto } from '../../models/patient.models';
import { ClientsApiService } from '../../services/clients-api.service';

@Component({
  selector: 'app-client-edit',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './client-edit.component.html',
  styleUrl: './client-edit.component.scss'
})
export class ClientEditComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly clientsApi = inject(ClientsApiService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  categories: ClientClinicCategoryDto[] = [];
  cities: LookupOptionDto[] = [];
  client: ClientRecordDto | null = null;

  lookupLoading = false;
  clientLoading = true;
  saving = false;
  loadError = '';
  statusMessage = '';
  statusError = false;
  organizationType: OrganizationType = 'CLINIC';

  readonly clientForm = this.fb.nonNullable.group({
    ClientCode: ['', [Validators.required, Validators.maxLength(50)]],
    FirstName: ['', [Validators.required, Validators.maxLength(250)]],
    LastName: ['', [Validators.maxLength(250)]],
    DateOfBirth: [''],
    IdNumber: ['', [Validators.maxLength(250)]],
    Email: ['', [Validators.email, Validators.maxLength(250)]],
    PhoneNumber: ['', [Validators.maxLength(25)]],
    ClientClinicCategoryId: [0],
    Line1: ['', [Validators.maxLength(250)]],
    Line2: ['', [Validators.maxLength(250)]],
    CityId: [0],
    IsActive: [true]
  });

  ngOnInit(): void {
    const clientId = this.route.snapshot.paramMap.get('clientId') ?? '';
    if (!clientId) {
      this.clientLoading = false;
      this.loadError = 'No client ID was supplied for this edit view.';
      return;
    }

    this.loadEditor(clientId);
  }

  get isBusy(): boolean {
    return this.lookupLoading || this.clientLoading || this.saving;
  }

  get organizationContent() {
    return getOrganizationContent(this.organizationType);
  }

  get filteredCategories(): ClientClinicCategoryDto[] {
    return this.categories.filter((category) => categoryMatchesOrganizationType(category, this.organizationType));
  }

  get hasCategoriesForSelectedType(): boolean {
    return this.filteredCategories.length > 0;
  }

  get categoryHelperMessage(): string {
    if (this.hasCategoriesForSelectedType) {
      return `Choose the ${this.organizationContent.singularLower} category that best matches how this organisation operates.`;
    }

    return `No ${this.organizationContent.singularLower} categories are configured yet. You can still save the organisation and assign a category later.`;
  }

  get title(): string {
    if (!this.client) {
      return 'Edit Organisation';
    }

    const displayName = this.readText(this.client.DisplayName, '');
    if (displayName) {
      return `Edit ${displayName}`;
    }

    const name = buildOrganizationName(
      this.client.FirstName,
      this.client.LastName,
      this.readText(this.client.ClientCode, 'Organisation')
    );
    return `Edit ${name}`;
  }

  get isDeletedRecord(): boolean {
    return !!this.client?.IsDeleted;
  }

  updateClient(): void {
    if (this.isBusy || !this.client) {
      return;
    }

    if (this.isDeletedRecord) {
      this.setStatus('Deleted organisation records cannot be updated from this screen.', true);
      return;
    }

    if (this.clientForm.invalid) {
      this.clientForm.markAllAsTouched();
      this.setStatus('Please complete the required organisation fields before saving.', true);
      return;
    }

    if (this.hasPartialAddress()) {
      this.setStatus('If you start the address section, line 1, line 2, and city are all required.', true);
      return;
    }

    const raw = this.clientForm.getRawValue();
    const payload: ClientUpdateRequestDto = {
      ClientCode: raw.ClientCode.trim(),
      FirstName: raw.FirstName.trim(),
      LastName: this.resolveLegacySecondaryName(raw.FirstName, raw.LastName),
      DateOfBirth: raw.DateOfBirth ? raw.DateOfBirth : undefined,
      IdNumber: this.readOptional(raw.IdNumber),
      Email: this.readOptional(raw.Email),
      PhoneNumber: this.readOptional(raw.PhoneNumber),
      Line1: this.readOptional(raw.Line1),
      Line2: this.readOptional(raw.Line2),
      CityId: raw.CityId > 0 ? raw.CityId : undefined,
      ClientClinicCategoryId: raw.ClientClinicCategoryId > 0 ? raw.ClientClinicCategoryId : undefined,
      IsActive: raw.IsActive
    };

    this.saving = true;
    this.setStatus('', false);

    this.clientsApi.updateClient(this.client.ClientId, payload)
      .pipe(finalize(() => {
        this.saving = false;
      }))
      .subscribe({
        next: (result) => {
          if (result.Success && result.ClientId) {
            void this.router.navigate(['/admin/clients', result.ClientId]);
            return;
          }

          this.setStatus(result.Message || 'Unable to update the organisation.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to update the organisation right now.';
          this.setStatus(message, true);
        }
      });
  }

  onOrganizationTypeChange(typeValue: string): void {
    const nextType: OrganizationType = typeValue === 'HOSPITAL' ? 'HOSPITAL' : 'CLINIC';
    this.organizationType = nextType;

    const selectedCategoryId = this.clientForm.controls.ClientClinicCategoryId.value;
    const selectedCategory = this.categories.find((category) => category.ClientClinicCategoryId === selectedCategoryId);
    if (selectedCategory && !categoryMatchesOrganizationType(selectedCategory, nextType)) {
      this.clientForm.controls.ClientClinicCategoryId.setValue(0);
    }
  }

  onCategoryChange(categoryIdValue: string | number): void {
    const categoryId = Number(categoryIdValue);
    const selectedCategory = this.categories.find((category) => category.ClientClinicCategoryId === categoryId);
    if (!selectedCategory) {
      return;
    }

    this.organizationType = categoryMatchesOrganizationType(selectedCategory, 'HOSPITAL')
      ? 'HOSPITAL'
      : 'CLINIC';
  }

  formatCategoryOption(category: ClientClinicCategoryDto): string {
    return describeCategoryOption(category);
  }

  retryLoad(): void {
    const clientId = this.route.snapshot.paramMap.get('clientId') ?? '';
    if (!clientId) {
      return;
    }

    this.loadEditor(clientId);
  }

  private loadEditor(clientId: string): void {
    this.lookupLoading = true;
    this.clientLoading = true;
    this.loadError = '';
    this.setStatus('', false);

    forkJoin({
      categories: this.clientsApi.getClinicCategories(),
      cities: this.clientsApi.getCities(),
      client: this.clientsApi.getClient(clientId, true)
    })
      .pipe(finalize(() => {
        this.lookupLoading = false;
        this.clientLoading = false;
      }))
      .subscribe({
        next: (result) => {
          this.categories = result.categories;
          this.cities = result.cities;
          this.client = result.client;
          this.organizationType = inferOrganizationType({
            categoryName: result.client.ClientClinicCategoryName,
            primaryName: result.client.DisplayName || result.client.FirstName,
            secondaryName: result.client.LastName,
            fallback: result.client.OrganizationType?.toUpperCase() === 'HOSPITAL' ? 'HOSPITAL' : 'CLINIC'
          });
          this.clientForm.patchValue({
            ClientCode: this.readText(result.client.ClientCode, ''),
            FirstName: this.readText(result.client.FirstName, ''),
            LastName: readOrganizationSecondaryName(result.client.FirstName, result.client.LastName),
            DateOfBirth: this.toDateInput(result.client.DateOfBirth),
            IdNumber: this.readText(result.client.IdNumber, ''),
            Email: this.readText(result.client.Email, ''),
            PhoneNumber: this.readText(result.client.PhoneNumber, ''),
            ClientClinicCategoryId: result.client.ClientClinicCategoryId ?? 0,
            Line1: this.readText(result.client.Line1, ''),
            Line2: this.readText(result.client.Line2, ''),
            CityId: result.client.CityId ?? 0,
            IsActive: result.client.IsActive
          });
        },
        error: (error) => {
          this.client = null;
          this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Unable to load the organisation edit view right now.';
        }
      });
  }

  private hasPartialAddress(): boolean {
    const raw = this.clientForm.getRawValue();
    const hasAnyAddressInput =
      raw.Line1.trim().length > 0
      || raw.Line2.trim().length > 0
      || raw.CityId > 0;

    const hasFullAddress =
      raw.Line1.trim().length > 0
      && raw.Line2.trim().length > 0
      && raw.CityId > 0;

    return hasAnyAddressInput && !hasFullAddress;
  }

  private readOptional(value: string): string | undefined {
    const normalized = value.trim();
    return normalized.length > 0 ? normalized : undefined;
  }

  private resolveLegacySecondaryName(primaryName: string, secondaryName: string): string {
    const normalizedPrimary = primaryName.trim();
    const normalizedSecondary = secondaryName.trim();

    return normalizedSecondary.length > 0 ? normalizedSecondary : normalizedPrimary;
  }

  private readText(value: string | null | undefined, fallback = ''): string {
    if (typeof value !== 'string') {
      return fallback;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : fallback;
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

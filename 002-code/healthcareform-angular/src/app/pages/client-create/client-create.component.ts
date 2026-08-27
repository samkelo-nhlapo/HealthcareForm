import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { finalize, forkJoin } from 'rxjs';
import {
  OrganizationType,
  categoryMatchesOrganizationType,
  describeCategoryOption,
  getOrganizationContent
} from '../../client-organization';
import {
  ClientClinicCategoryDto,
  ClientCreateRequestDto
} from '../../models/clients.models';
import { LookupOptionDto } from '../../models/patient.models';
import { ClientsApiService } from '../../services/clients-api.service';

@Component({
  selector: 'app-client-create',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './client-create.component.html',
  styleUrl: './client-create.component.scss'
})
export class ClientCreateComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly clientsApi = inject(ClientsApiService);
  private readonly router = inject(Router);

  categories: ClientClinicCategoryDto[] = [];
  cities: LookupOptionDto[] = [];

  lookupLoading = false;
  saving = false;
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
    CityId: [0]
  });

  ngOnInit(): void {
    this.loadLookups();
  }

  get isBusy(): boolean {
    return this.lookupLoading || this.saving;
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

    return `No ${this.organizationContent.singularLower} categories are configured yet. You can still create the organisation now and assign a category later.`;
  }

  createClient(): void {
    if (this.isBusy) {
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
    const payload: ClientCreateRequestDto = {
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
      ClientClinicCategoryId: raw.ClientClinicCategoryId > 0 ? raw.ClientClinicCategoryId : undefined
    };

    this.saving = true;
    this.setStatus('', false);

    this.clientsApi.createClient(payload)
      .pipe(finalize(() => {
        this.saving = false;
      }))
      .subscribe({
        next: (result) => {
          if (result.Success && result.ClientId) {
            void this.router.navigate(['/admin/clients', result.ClientId]);
            return;
          }

          this.setStatus(result.Message || 'Unable to create the organisation.', true);
        },
        error: (error) => {
          const message =
            error?.error?.Message
            ?? error?.error?.message
            ?? error?.error?.title
            ?? 'Unable to create the organisation right now.';
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

  private loadLookups(): void {
    this.lookupLoading = true;

    forkJoin({
      categories: this.clientsApi.getClinicCategories(),
      cities: this.clientsApi.getCities()
    })
      .pipe(finalize(() => {
        this.lookupLoading = false;
      }))
      .subscribe({
        next: (result) => {
          this.categories = result.categories;
          this.cities = result.cities;
        },
        error: () => {
          this.setStatus('Unable to load organisation lookup values right now.', true);
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

  private setStatus(message: string, isError: boolean): void {
    this.statusMessage = message;
    this.statusError = isError;
  }
}

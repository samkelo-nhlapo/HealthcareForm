import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { finalize } from 'rxjs';
import {
  buildOrganizationName,
  buildOrganizationProfile,
  getOrganizationContent,
  inferOrganizationType
} from '../../client-organization';
import {
  ClientClinicCategoryDto,
  ClientDirectoryItemDto,
  ClientDirectorySnapshotDto
} from '../../models/clients.models';
import { ClientsApiService } from '../../services/clients-api.service';

type RecordState = 'ACTIVE' | 'DELETED' | 'ALL';
type ActivityState = 'ALL' | 'ACTIVE' | 'INACTIVE';

type DirectoryRow = {
  clientId: string;
  client: string;
  clientMeta: string;
  category: string;
  categoryMeta: string;
  registry: string;
  contact: string;
  patientLoad: string;
  updatedOn: string;
  isActive: boolean;
  isDeleted: boolean;
};

@Component({
  selector: 'app-client-directory',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './client-directory.component.html',
  styleUrl: './client-directory.component.scss'
})
export class ClientDirectoryComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly clientsApi = inject(ClientsApiService);

  readonly pageSize = 25;

  categories: ClientClinicCategoryDto[] = [];
  rows: DirectoryRow[] = [];

  isLoading = true;
  lookupLoading = false;
  loadError = '';
  totalRecords = 0;
  currentPage = 1;

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    categoryId: [0],
    recordState: ['ACTIVE' as RecordState],
    activityState: ['ALL' as ActivityState]
  });

  ngOnInit(): void {
    this.loadCategories();
    this.loadDirectory();
  }

  get totalPages(): number {
    return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
  }

  get isBusy(): boolean {
    return this.isLoading || this.lookupLoading;
  }

  applyFilters(): void {
    this.currentPage = 1;
    this.loadDirectory();
  }

  clearFilters(): void {
    this.filters.reset({
      search: '',
      categoryId: 0,
      recordState: 'ACTIVE',
      activityState: 'ALL'
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

  private loadCategories(): void {
    this.lookupLoading = true;

    this.clientsApi.getClinicCategories()
      .pipe(finalize(() => {
        this.lookupLoading = false;
      }))
      .subscribe({
        next: (categories) => {
          this.categories = categories;
        },
        error: () => {
          this.loadError = this.loadError || 'Unable to load organisation-category filters right now.';
        }
      });
  }

  private loadDirectory(): void {
    this.isLoading = true;
    this.loadError = '';

    const value = this.filters.getRawValue();

    this.clientsApi.getClients({
      SearchTerm: value.search,
      ClientClinicCategoryId: value.categoryId > 0 ? value.categoryId : undefined,
      IsActive: this.resolveActiveFilter(value.activityState),
      IsDeleted: this.resolveDeletedFilter(value.recordState),
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
          this.loadError = 'Unable to load the organisation directory. Check API connectivity and retry.';
        }
      });
  }

  private applySnapshot(snapshot: ClientDirectorySnapshotDto): void {
    this.rows = Array.isArray(snapshot.Clients)
      ? snapshot.Clients.map((item) => this.mapRow(item))
      : [];
    this.totalRecords = Number.isFinite(snapshot.TotalRecords) ? snapshot.TotalRecords : 0;

    if (this.currentPage > this.totalPages) {
      this.currentPage = this.totalPages;
      this.loadDirectory();
    }
  }

  private mapRow(item: ClientDirectoryItemDto): DirectoryRow {
    const fallbackType = this.resolveOrganizationType(item.OrganizationType);
    const organizationType = inferOrganizationType({
      categoryName: item.ClientClinicCategoryName,
      primaryName: item.DisplayName || item.FirstName,
      secondaryName: item.LastName,
      fallback: fallbackType
    });
    const organizationTypeLabel = getOrganizationContent(organizationType).singular;
    const location = this.formatLocation(item);
    const displayName = this.readText(item.DisplayName)
      || buildOrganizationName(item.FirstName, item.LastName, 'Unknown Organisation');
    const clientMetaParts = [organizationTypeLabel, this.readText(item.ClientCode, 'No code')];
    if (location) {
      clientMetaParts.push(location);
    }

    return {
      clientId: item.ClientId,
      client: displayName,
      clientMeta: clientMetaParts.join(' • '),
      category: this.readText(item.ClientClinicCategoryName, 'Unassigned category'),
      categoryMeta: buildOrganizationProfile(item.ClinicSize, item.OwnershipType),
      registry:
        this.readText(item.GroupOperator)
        || this.readText(item.IdNumber)
        || this.readText(item.NetworkSources, 'No operator or registration'),
      contact:
        this.readText(item.PhoneNumber)
        || this.readText(item.Email)
        || this.readText(item.FacilityAddressText, 'No contact details'),
      patientLoad: `${item.ActivePatientCount ?? 0} active / ${item.RegisteredPatientCount ?? 0} total patients`,
      updatedOn: this.formatDate(item.UpdatedDate),
      isActive: item.IsActive,
      isDeleted: item.IsDeleted
    };
  }

  private resolveOrganizationType(value: string | null | undefined): 'CLINIC' | 'HOSPITAL' {
    const normalized = this.readText(value).toUpperCase();
    return normalized === 'HOSPITAL' ? 'HOSPITAL' : 'CLINIC';
  }

  private formatLocation(item: ClientDirectoryItemDto): string {
    const parts = [
      this.readText(item.FacilityTownName, ''),
      this.readText(item.FacilityProvinceName, ''),
      this.readText(item.FacilityCountryName, '')
    ].filter((segment) => segment.length > 0);

    if (parts.length === 0) {
      return '';
    }

    if (parts.length >= 2 && parts[parts.length - 1] === 'South Africa') {
      return parts.slice(0, parts.length - 1).join(', ');
    }

    return parts.join(', ');
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

  private resolveActiveFilter(activityState: ActivityState): boolean | undefined {
    if (activityState === 'ACTIVE') {
      return true;
    }

    if (activityState === 'INACTIVE') {
      return false;
    }

    return undefined;
  }

  private readText(value: string | null | undefined, fallback = ''): string {
    if (typeof value !== 'string') {
      return fallback;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : fallback;
  }

  private formatDate(value: string | null | undefined): string {
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
      year: 'numeric'
    }).format(parsed);
  }
}

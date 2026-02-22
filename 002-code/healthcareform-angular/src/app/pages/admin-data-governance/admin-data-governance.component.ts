import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { AdminDataGovernanceSnapshotDto } from '../../models/admin.models';
import { AdminApiService } from '../../services/admin-api.service';

type GovernanceView = 'Configuration' | 'Templates' | 'Lookups';

type ConfigurationItem = {
  key: string;
  scope: string;
  currentValue: string;
  baselineValue: string;
  lastUpdated: string;
  owner: string;
  state: 'Aligned' | 'Drift';
};

type TemplateItem = {
  templateName: string;
  version: string;
  status: 'Draft' | 'Published' | 'Retired';
  owner: string;
  lastApproved: string;
  nextReview: string;
};

type LookupItem = {
  name: string;
  records: number;
  source: string;
  refreshCadence: string;
  lastSync: string;
  state: 'Healthy' | 'Warning' | 'Stale';
};

@Component({
  selector: 'app-admin-data-governance',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './admin-data-governance.component.html',
  styleUrl: './admin-data-governance.component.scss'
})
export class AdminDataGovernanceComponent implements OnInit {
  private readonly adminApiService = inject(AdminApiService);

  selectedView: GovernanceView = 'Configuration';
  isLoading = true;
  loadError = '';

  configurationItems: ConfigurationItem[] = [];

  templateItems: TemplateItem[] = [];

  lookupItems: LookupItem[] = [];

  ngOnInit(): void {
    this.loadSnapshot();
  }

  retryLoad(): void {
    this.loadSnapshot();
  }

  private loadSnapshot(): void {
    this.isLoading = true;
    this.loadError = '';

    this.adminApiService.getDataGovernanceSnapshot().subscribe({
      next: (snapshot) => {
        this.applySnapshot(snapshot);
        this.isLoading = false;
      },
      error: () => {
        this.configurationItems = [];
        this.templateItems = [];
        this.lookupItems = [];
        this.loadError = 'Unable to load data-governance snapshot. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private applySnapshot(snapshot: AdminDataGovernanceSnapshotDto): void {
    if (Array.isArray(snapshot.ConfigurationItems)) {
      this.configurationItems = snapshot.ConfigurationItems.map((item) => ({
        key: item.Key,
        scope: item.Scope,
        currentValue: item.CurrentValue,
        baselineValue: item.BaselineValue,
        lastUpdated: item.LastUpdated,
        owner: item.Owner,
        state: this.normalizeConfigurationState(item.State)
      }));
    }

    if (Array.isArray(snapshot.TemplateItems)) {
      this.templateItems = snapshot.TemplateItems.map((item) => ({
        templateName: item.TemplateName,
        version: item.Version,
        status: this.normalizeTemplateStatus(item.Status),
        owner: item.Owner,
        lastApproved: item.LastApproved,
        nextReview: item.NextReview
      }));
    }

    if (Array.isArray(snapshot.LookupItems)) {
      this.lookupItems = snapshot.LookupItems.map((item) => ({
        name: item.Name,
        records: item.Records,
        source: item.Source,
        refreshCadence: item.RefreshCadence,
        lastSync: item.LastSync,
        state: this.normalizeLookupState(item.State)
      }));
    }
  }

  private normalizeConfigurationState(value: string): ConfigurationItem['state'] {
    return (value ?? '').trim().toLowerCase() === 'drift' ? 'Drift' : 'Aligned';
  }

  private normalizeTemplateStatus(value: string): TemplateItem['status'] {
    const normalized = (value ?? '').trim().toLowerCase();
    if (normalized === 'draft') {
      return 'Draft';
    }

    if (normalized === 'retired') {
      return 'Retired';
    }

    return 'Published';
  }

  private normalizeLookupState(value: string): LookupItem['state'] {
    const normalized = (value ?? '').trim().toLowerCase();
    if (normalized === 'stale') {
      return 'Stale';
    }

    if (normalized === 'warning') {
      return 'Warning';
    }

    return 'Healthy';
  }

  selectView(view: GovernanceView): void {
    this.selectedView = view;
  }

  get configDriftCount(): number {
    return this.configurationItems.filter((item) => item.state === 'Drift').length;
  }

  get draftTemplates(): number {
    return this.templateItems.filter((item) => item.status === 'Draft').length;
  }

  get staleLookups(): number {
    return this.lookupItems.filter((item) => item.state === 'Stale').length;
  }

  get warningLookups(): number {
    return this.lookupItems.filter((item) => item.state === 'Warning').length;
  }
}

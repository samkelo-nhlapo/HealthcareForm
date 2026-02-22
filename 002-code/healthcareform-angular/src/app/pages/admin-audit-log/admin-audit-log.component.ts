import { CommonModule } from '@angular/common';
import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { debounceTime } from 'rxjs';
import { AdminAuditLogQueryDto, AdminAuditLogSnapshotDto } from '../../models/admin.models';
import { AdminApiService } from '../../services/admin-api.service';

type AuditOutcome = 'Success' | 'Warning' | 'Failure';
type AuditCategory = 'Authentication' | 'Authorization' | 'PatientData' | 'Configuration' | 'Billing';

type AuditEvent = {
  occurredAt: string;
  actor: string;
  actorRole: string;
  category: AuditCategory;
  eventName: string;
  resource: string;
  outcome: AuditOutcome;
  ipAddress: string;
  correlationId: string;
  privileged: boolean;
};

@Component({
  selector: 'app-admin-audit-log',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './admin-audit-log.component.html',
  styleUrl: './admin-audit-log.component.scss'
})
export class AdminAuditLogComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly adminApiService = inject(AdminApiService);
  private readonly destroyRef = inject(DestroyRef);

  private readonly defaultPageSize = 50;
  private requestId = 0;

  isLoading = true;
  loadError = '';
  page = 1;
  totalPages = 0;
  totalCount = 0;
  pageSize = this.defaultPageSize;

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    actor: ['ALL'],
    category: ['ALL'],
    outcome: ['ALL'],
    dateFrom: [''],
    dateTo: [''],
    privilegedOnly: [false]
  });

  events: AuditEvent[] = [];

  actorOptions: string[] = [];

  ngOnInit(): void {
    this.filters.valueChanges
      .pipe(debounceTime(250), takeUntilDestroyed(this.destroyRef))
      .subscribe(() => {
        this.page = 1;
        this.loadSnapshot(1);
      });

    this.loadSnapshot();
  }

  retryLoad(): void {
    this.loadSnapshot(this.page);
  }

  goToPage(page: number): void {
    if (page < 1 || page > this.totalPages || page === this.page) {
      return;
    }

    this.loadSnapshot(page);
  }

  private loadSnapshot(page = this.page): void {
    this.page = page;
    this.isLoading = true;
    this.loadError = '';
    const requestId = ++this.requestId;

    this.adminApiService.getAuditLogSnapshot(this.buildQuery()).subscribe({
      next: (snapshot) => {
        if (requestId !== this.requestId) {
          return;
        }

        this.applySnapshot(snapshot);
        this.isLoading = false;
      },
      error: () => {
        if (requestId !== this.requestId) {
          return;
        }

        this.actorOptions = [];
        this.events = [];
        this.loadError = 'Unable to load audit-log data. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private applySnapshot(snapshot: AdminAuditLogSnapshotDto): void {
    this.actorOptions = Array.isArray(snapshot.ActorOptions) ? snapshot.ActorOptions : [];

    if (Array.isArray(snapshot.Events)) {
      this.events = snapshot.Events.map((event) => ({
        occurredAt: event.OccurredAtUtc,
        actor: event.Actor || 'unknown',
        actorRole: event.ActorRole || 'ANONYMOUS',
        category: this.normalizeCategory(event.Category),
        eventName: event.EventName,
        resource: event.Resource,
        outcome: this.normalizeOutcome(event.Outcome),
        ipAddress: event.IpAddress || 'N/A',
        correlationId: event.CorrelationId,
        privileged: event.Privileged
      }));
    } else {
      this.events = [];
    }

    this.page = snapshot.Page ?? this.page;
    this.pageSize = snapshot.PageSize ?? this.defaultPageSize;
    this.totalCount = snapshot.TotalCount ?? this.events.length;
    this.totalPages = snapshot.TotalPages ?? (this.totalCount > 0 ? 1 : 0);
  }

  private buildQuery(): AdminAuditLogQueryDto {
    const value = this.filters.getRawValue();
    const search = value.search.trim();

    return {
      actor: this.normalizeFilter(value.actor),
      category: this.normalizeFilter(value.category),
      outcome: this.normalizeFilter(value.outcome),
      fromUtc: value.dateFrom ? `${value.dateFrom}T00:00:00Z` : undefined,
      toUtc: value.dateTo ? `${value.dateTo}T23:59:59Z` : undefined,
      search: search.length > 0 ? search : undefined,
      privilegedOnly: value.privilegedOnly ? true : undefined,
      page: this.page,
      pageSize: this.defaultPageSize
    };
  }

  private normalizeFilter(value: string): string | undefined {
    return value === 'ALL' ? undefined : value;
  }

  private normalizeCategory(value: string): AuditCategory {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'authentication') {
      return 'Authentication';
    }

    if (normalized === 'authorization') {
      return 'Authorization';
    }

    if (normalized === 'configuration') {
      return 'Configuration';
    }

    if (normalized === 'billing') {
      return 'Billing';
    }

    return 'PatientData';
  }

  private normalizeOutcome(value: string): AuditOutcome {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'failure') {
      return 'Failure';
    }

    if (normalized === 'warning') {
      return 'Warning';
    }

    return 'Success';
  }

  get failureEvents(): number {
    return this.events.filter((event) => event.outcome === 'Failure').length;
  }

  get privilegedEvents(): number {
    return this.events.filter((event) => event.privileged).length;
  }

  get offHoursEvents(): number {
    return this.events.filter((event) => {
      const hour = new Date(event.occurredAt).getUTCHours();
      return hour < 6 || hour >= 20;
    }).length;
  }
}

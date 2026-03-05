import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { RevenueClaimRowDto, RevenueClaimsSnapshotDto } from '../../models/revenue.models';
import { RevenueApiService } from '../../services/revenue-api.service';

type CodingStatus = 'Uncoded' | 'Coder Review' | 'Code Complete';
type ClaimStatus = 'Ready to Submit' | 'Submitted' | 'Pending Documentation' | 'Denied' | 'Paid';

type ClaimRow = {
  claimId: string;
  patient: string;
  idNumber: string;
  payer: string;
  serviceDate: string;
  amount: number;
  paidAmount: number;
  codingStatus: CodingStatus;
  claimStatus: ClaimStatus;
  denialReason: string;
  daysOpen: number;
  lastUpdated: string;
};

type AgingBucket = {
  label: string;
  count: number;
  amount: number;
};

@Component({
  selector: 'app-billing-claims',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './billing-claims.component.html',
  styleUrl: './billing-claims.component.scss'
})
export class BillingClaimsComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly revenueApiService = inject(RevenueApiService);

  isLoading = true;
  loadError = '';
  lastRefreshedAt = '';

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    payer: ['ALL'],
    claimStatus: ['ALL'],
    codingStatus: ['ALL'],
    deniedOnly: [false]
  });

  claims: ClaimRow[] = [];

  ngOnInit(): void {
    this.loadSnapshot();
  }

  get hasSnapshotData(): boolean {
    return this.claims.length > 0;
  }

  get filteredClaims(): ClaimRow[] {
    const value = this.filters.getRawValue();
    const search = value.search.trim().toLowerCase();

    return this.claims.filter((claim) => {
      const matchesSearch = !search
        || claim.claimId.toLowerCase().includes(search)
        || claim.patient.toLowerCase().includes(search)
        || claim.idNumber.includes(search)
        || claim.payer.toLowerCase().includes(search);

      const matchesPayer = value.payer === 'ALL' || claim.payer === value.payer;
      const matchesClaimStatus = value.claimStatus === 'ALL' || claim.claimStatus === value.claimStatus;
      const matchesCodingStatus = value.codingStatus === 'ALL' || claim.codingStatus === value.codingStatus;
      const matchesDenials = !value.deniedOnly || claim.claimStatus === 'Denied';

      return matchesSearch && matchesPayer && matchesClaimStatus && matchesCodingStatus && matchesDenials;
    });
  }

  get outstandingBalance(): number {
    return this.claims.reduce((sum, claim) => sum + this.balance(claim), 0);
  }

  get deniedCount(): number {
    return this.claims.filter((claim) => claim.claimStatus === 'Denied').length;
  }

  get readyToSubmitCount(): number {
    return this.claims.filter((claim) => claim.claimStatus === 'Ready to Submit').length;
  }

  get collectedAmount(): number {
    return this.claims.reduce((sum, claim) => sum + claim.paidAmount, 0);
  }

  get denialRate(): number {
    if (this.claims.length === 0) {
      return 0;
    }

    return Math.round((this.deniedCount / this.claims.length) * 100);
  }

  get agingBuckets(): AgingBucket[] {
    const openClaims = this.claims.filter((claim) => claim.claimStatus !== 'Paid');

    return [
      {
        label: '0-7 days',
        count: openClaims.filter((claim) => claim.daysOpen <= 7).length,
        amount: openClaims.filter((claim) => claim.daysOpen <= 7).reduce((sum, claim) => sum + this.balance(claim), 0)
      },
      {
        label: '8-14 days',
        count: openClaims.filter((claim) => claim.daysOpen >= 8 && claim.daysOpen <= 14).length,
        amount: openClaims.filter((claim) => claim.daysOpen >= 8 && claim.daysOpen <= 14).reduce((sum, claim) => sum + this.balance(claim), 0)
      },
      {
        label: '15+ days',
        count: openClaims.filter((claim) => claim.daysOpen >= 15).length,
        amount: openClaims.filter((claim) => claim.daysOpen >= 15).reduce((sum, claim) => sum + this.balance(claim), 0)
      }
    ];
  }

  get denialRows(): ClaimRow[] {
    return this.claims.filter((claim) => claim.claimStatus === 'Denied');
  }

  get payerOptions(): string[] {
    return this.claims
      .map((claim) => claim.payer)
      .filter((payer) => payer.length > 0)
      .filter((payer, index, values) => values.findIndex((value) => value.toLowerCase() === payer.toLowerCase()) === index)
      .sort((a, b) => a.localeCompare(b));
  }

  collectionPercent(claim: ClaimRow): number {
    if (claim.amount <= 0) {
      return 0;
    }

    return Math.min(100, Math.round((claim.paidAmount / claim.amount) * 100));
  }

  balance(claim: ClaimRow): number {
    return Math.max(0, claim.amount - claim.paidAmount);
  }

  retryLoad(): void {
    this.loadSnapshot();
  }

  private loadSnapshot(): void {
    this.isLoading = true;
    this.loadError = '';

    this.revenueApiService.getClaimsSnapshot().subscribe({
      next: (snapshot) => {
        this.applySnapshot(snapshot);
        this.lastRefreshedAt = this.formatTimestamp(new Date());
        this.isLoading = false;
      },
      error: () => {
        this.claims = [];
        this.loadError = 'Unable to load billing claims data. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private applySnapshot(snapshot: RevenueClaimsSnapshotDto): void {
    this.claims = Array.isArray(snapshot.Claims)
      ? snapshot.Claims.map((claim) => this.mapClaim(claim))
      : [];
  }

  private mapClaim(claim: RevenueClaimRowDto): ClaimRow {
    return {
      claimId: this.readText(claim.ClaimId, 'INV-UNKNOWN'),
      patient: this.readText(claim.Patient, 'Unknown Patient'),
      idNumber: this.readText(claim.IdNumber, ''),
      payer: this.readText(claim.Payer, 'Self Pay'),
      serviceDate: this.readText(claim.ServiceDate, ''),
      amount: this.coerceCurrency(claim.Amount),
      paidAmount: this.coerceCurrency(claim.PaidAmount),
      codingStatus: this.normalizeCodingStatus(claim.CodingStatus),
      claimStatus: this.normalizeClaimStatus(claim.ClaimStatus),
      denialReason: this.readText(claim.DenialReason, ''),
      daysOpen: this.coerceDays(claim.DaysOpen),
      lastUpdated: this.readText(claim.LastUpdated, '')
    };
  }

  private normalizeCodingStatus(value: string): CodingStatus {
    const normalized = (value ?? '').trim().toLowerCase();
    if (normalized === 'uncoded') {
      return 'Uncoded';
    }

    if (normalized === 'coder review') {
      return 'Coder Review';
    }

    return 'Code Complete';
  }

  private normalizeClaimStatus(value: string): ClaimStatus {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'submitted') {
      return 'Submitted';
    }

    if (normalized === 'pending documentation') {
      return 'Pending Documentation';
    }

    if (normalized === 'denied') {
      return 'Denied';
    }

    if (normalized === 'paid') {
      return 'Paid';
    }

    return 'Ready to Submit';
  }

  private coerceCurrency(value: unknown): number {
    const number = typeof value === 'number' ? value : Number(value);
    if (!Number.isFinite(number)) {
      return 0;
    }

    return Math.max(0, Number(number));
  }

  private coerceDays(value: unknown): number {
    const number = typeof value === 'number' ? value : Number(value);
    if (!Number.isFinite(number)) {
      return 0;
    }

    return Math.max(0, Math.round(number));
  }

  private readText(value: unknown, fallback: string): string {
    if (typeof value !== 'string') {
      return fallback;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : fallback;
  }

  private formatTimestamp(date: Date): string {
    return date.toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }
}

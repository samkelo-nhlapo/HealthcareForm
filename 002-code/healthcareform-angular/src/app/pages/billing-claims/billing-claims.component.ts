import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

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
export class BillingClaimsComponent {
  private readonly fb = inject(FormBuilder);

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    payer: ['ALL'],
    claimStatus: ['ALL'],
    codingStatus: ['ALL'],
    deniedOnly: [false]
  });

  readonly claims: ClaimRow[] = [
    {
      claimId: 'CLM-4021',
      patient: 'Nomsa Mokoena',
      idNumber: '9101015001089',
      payer: 'Momentum Health',
      serviceDate: '2026-02-20',
      amount: 4620,
      paidAmount: 0,
      codingStatus: 'Code Complete',
      claimStatus: 'Ready to Submit',
      denialReason: '',
      daysOpen: 1,
      lastUpdated: '2026-02-21 08:11'
    },
    {
      claimId: 'CLM-4017',
      patient: 'Liam Smith',
      idNumber: '8206066002087',
      payer: 'Discovery Health',
      serviceDate: '2026-02-16',
      amount: 7890,
      paidAmount: 0,
      codingStatus: 'Code Complete',
      claimStatus: 'Submitted',
      denialReason: '',
      daysOpen: 5,
      lastUpdated: '2026-02-21 07:44'
    },
    {
      claimId: 'CLM-3998',
      patient: 'Asha Patel',
      idNumber: '0310037003084',
      payer: 'Bonitas',
      serviceDate: '2026-02-10',
      amount: 5380,
      paidAmount: 0,
      codingStatus: 'Code Complete',
      claimStatus: 'Denied',
      denialReason: 'Diagnosis and procedure mismatch',
      daysOpen: 11,
      lastUpdated: '2026-02-20 15:19'
    },
    {
      claimId: 'CLM-3975',
      patient: 'Sibusiso Khumalo',
      idNumber: '7507078004082',
      payer: 'GEMS',
      serviceDate: '2026-02-05',
      amount: 9160,
      paidAmount: 4120,
      codingStatus: 'Code Complete',
      claimStatus: 'Pending Documentation',
      denialReason: '',
      daysOpen: 16,
      lastUpdated: '2026-02-21 09:02'
    },
    {
      claimId: 'CLM-3922',
      patient: 'Jordan Daniels',
      idNumber: '9902029005081',
      payer: 'Discovery Health',
      serviceDate: '2026-01-30',
      amount: 4320,
      paidAmount: 4320,
      codingStatus: 'Code Complete',
      claimStatus: 'Paid',
      denialReason: '',
      daysOpen: 22,
      lastUpdated: '2026-02-19 11:25'
    },
    {
      claimId: 'CLM-4050',
      patient: 'Mandla Peters',
      idNumber: '9303036006085',
      payer: 'Momentum Health',
      serviceDate: '2026-02-21',
      amount: 3080,
      paidAmount: 0,
      codingStatus: 'Coder Review',
      claimStatus: 'Pending Documentation',
      denialReason: '',
      daysOpen: 0,
      lastUpdated: '2026-02-21 09:08'
    }
  ];

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

  collectionPercent(claim: ClaimRow): number {
    if (claim.amount <= 0) {
      return 0;
    }

    return Math.min(100, Math.round((claim.paidAmount / claim.amount) * 100));
  }

  balance(claim: ClaimRow): number {
    return Math.max(0, claim.amount - claim.paidAmount);
  }
}

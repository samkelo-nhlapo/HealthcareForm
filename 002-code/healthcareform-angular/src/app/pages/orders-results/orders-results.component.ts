import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { PatientRecordDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

type ResultSeverity = 'Normal' | 'Abnormal' | 'Critical';
type ResultRow = {
  test: string;
  value: string;
  referenceRange: string;
  severity: ResultSeverity;
  completedAt: string;
};

@Component({
  selector: 'app-orders-results',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './orders-results.component.html',
  styleUrl: './orders-results.component.scss'
})
export class OrdersResultsComponent {
  patient: PatientRecordDto | null = null;
  contextLabel = 'No patient selected.';
  loadError = '';
  abnormalOnly = false;

  readonly pendingOrders: string[] = [
    'CBC with differential',
    'Renal function panel',
    '12-lead ECG follow-up'
  ];

  readonly results: ResultRow[] = [
    { test: 'Hemoglobin', value: '10.4 g/dL', referenceRange: '12.0 - 15.5', severity: 'Abnormal', completedAt: '2026-02-21 08:10' },
    { test: 'Potassium', value: '5.9 mmol/L', referenceRange: '3.5 - 5.1', severity: 'Critical', completedAt: '2026-02-21 08:14' },
    { test: 'Creatinine', value: '89 umol/L', referenceRange: '50 - 98', severity: 'Normal', completedAt: '2026-02-21 08:14' },
    { test: 'Troponin I', value: '0.06 ng/mL', referenceRange: '< 0.04', severity: 'Abnormal', completedAt: '2026-02-21 08:17' }
  ];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly patientApi: PatientApiService
  ) {
    this.route.queryParamMap.subscribe((params) => {
      const idNumber = (params.get('idNumber') ?? '').trim();
      if (idNumber.length !== 13) {
        this.patient = null;
        this.contextLabel = 'No patient selected. Launch from chart or worklist.';
        return;
      }

      this.patientApi.getPatient(idNumber).subscribe({
        next: (patient) => {
          this.patient = patient;
          this.loadError = '';
          this.contextLabel = `${patient.FirstName} ${patient.LastName} (${patient.IdNumber})`;
        },
        error: (error) => {
          this.patient = null;
          this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Failed to load patient context.';
          this.contextLabel = `Patient ${idNumber}`;
        }
      });
    });
  }

  get visibleResults(): ResultRow[] {
    if (!this.abnormalOnly) {
      return this.results;
    }

    return this.results.filter((row) => row.severity !== 'Normal');
  }

  toggleAbnormalOnly(): void {
    this.abnormalOnly = !this.abnormalOnly;
  }
}

import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { isValidPatientIdNumber, normalizePatientIdNumber } from '../../models/patient-id.utils';
import { PatientLabResultDto, PatientPendingOrderDto, PatientRecordDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

type ResultSeverity = 'Normal' | 'Abnormal' | 'Critical';

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
  resultsLoadError = '';
  isLoading = false;
  abnormalOnly = false;

  pendingOrders: PatientPendingOrderDto[] = [];
  results: PatientLabResultDto[] = [];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly patientApi: PatientApiService
  ) {
    this.route.queryParamMap.subscribe((params) => {
      const idNumber = normalizePatientIdNumber(params.get('idNumber'));
      if (!isValidPatientIdNumber(idNumber)) {
        this.resetView();
        return;
      }

      this.isLoading = true;
      this.loadError = '';
      this.resultsLoadError = '';

      this.patientApi.getPatient(idNumber).subscribe({
        next: (patient) => {
          this.patient = patient;
          this.contextLabel = `${patient.FirstName} ${patient.LastName} (${patient.IdNumber})`;
          this.loadOrdersResults(idNumber);
        },
        error: (error) => {
          this.resetView(`Patient ${idNumber}`);
          this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Failed to load patient context.';
          this.isLoading = false;
        }
      });
    });
  }

  get visibleResults(): PatientLabResultDto[] {
    if (!this.abnormalOnly) {
      return this.results;
    }

    return this.results.filter((row) => this.normalizeSeverity(row.Severity) !== 'Normal');
  }

  toggleAbnormalOnly(): void {
    this.abnormalOnly = !this.abnormalOnly;
  }

  severityOf(result: PatientLabResultDto): ResultSeverity {
    return this.normalizeSeverity(result.Severity);
  }

  formattedResultValue(result: PatientLabResultDto): string {
    const value = (result.ResultValue ?? '').trim();
    const unit = (result.Unit ?? '').trim();
    if (!unit) {
      return value;
    }

    return `${value} ${unit}`.trim();
  }

  private loadOrdersResults(idNumber: string): void {
    this.patientApi.getOrdersResults(idNumber).subscribe({
      next: (snapshot) => {
        this.pendingOrders = Array.isArray(snapshot.PendingOrders) ? snapshot.PendingOrders : [];
        this.results = Array.isArray(snapshot.Results) ? snapshot.Results : [];
        this.isLoading = false;
      },
      error: (error) => {
        this.pendingOrders = [];
        this.results = [];
        this.resultsLoadError = error?.error?.Message ?? error?.error?.message ?? 'Failed to load orders and results.';
        this.isLoading = false;
      }
    });
  }

  private resetView(contextLabel = 'No patient selected. Launch from chart or worklist.'): void {
    this.patient = null;
    this.contextLabel = contextLabel;
    this.loadError = '';
    this.resultsLoadError = '';
    this.pendingOrders = [];
    this.results = [];
    this.isLoading = false;
    this.abnormalOnly = false;
  }

  private normalizeSeverity(value: string): ResultSeverity {
    const normalized = (value ?? '').trim().toLowerCase();
    if (normalized === 'critical') {
      return 'Critical';
    }

    if (normalized === 'abnormal') {
      return 'Abnormal';
    }

    return 'Normal';
  }
}

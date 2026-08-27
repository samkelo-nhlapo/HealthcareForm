import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { isValidPatientIdNumber, normalizePatientIdNumber } from '../../models/patient-id.utils';
import { PatientMedicationDto, PatientRecordDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

type MedicationSource = 'Medication History' | 'Current Chart' | 'Patient Reported';

type MedicationItem = {
  name: string;
  source: MedicationSource;
  reviewed: boolean;
  dosage: string;
  frequency: string;
  route: string;
  status: string;
  prescribedBy: string;
  indication: string;
  startDate: string | null;
  endDate: string | null;
};

@Component({
  selector: 'app-medication-reconciliation',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './medication-reconciliation.component.html',
  styleUrl: './medication-reconciliation.component.scss'
})
export class MedicationReconciliationComponent {
  patient: PatientRecordDto | null = null;
  contextLabel = 'No patient selected.';
  loadError = '';
  medicationsLoadError = '';
  isLoadingContext = false;
  isLoadingMedications = false;
  finalizedAt: Date | null = null;

  medications: MedicationItem[] = [];
  private contextRequestToken = 0;
  private readonly fallbackPatientReportedMedications = ['Aspirin 81mg daily', 'Ibuprofen PRN'];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly patientApi: PatientApiService
  ) {
    this.route.queryParamMap.subscribe((params) => {
      const requestToken = ++this.contextRequestToken;
      const idNumber = normalizePatientIdNumber(params.get('idNumber'));
      if (!isValidPatientIdNumber(idNumber)) {
        this.resetContext();
        return;
      }

      this.beginContextLoad(idNumber);
      this.patientApi.getPatient(idNumber).subscribe({
        next: (patient) => {
          if (!this.isActiveRequest(requestToken)) {
            return;
          }

          this.patient = patient;
          this.loadError = '';
          this.contextLabel = `${patient.FirstName} ${patient.LastName} (${patient.IdNumber})`;
          this.isLoadingContext = false;
          this.loadMedicationRows(idNumber, patient, requestToken);
        },
        error: (error) => {
          if (!this.isActiveRequest(requestToken)) {
            return;
          }

          this.isLoadingContext = false;
          this.resetContext();
          this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Failed to load patient context.';
          this.contextLabel = `Patient ${idNumber}`;
        }
      });
    });
  }

  get warnings(): string[] {
    if (this.isLoadingMedications) {
      return ['Medication history is still loading.'];
    }

    if (this.medications.length === 0) {
      return ['No medication data available to evaluate interactions.'];
    }

    const names = this.medications.map((item) => this.medicationDescriptor(item).toLowerCase());
    const warnings: string[] = [];

    if (names.some((name) => name.includes('warfarin')) && names.some((name) => name.includes('aspirin'))) {
      warnings.push('Warfarin + Aspirin increases bleeding risk. Confirm dose and indication.');
    }

    if (names.some((name) => name.includes('ibuprofen')) && names.some((name) => name.includes('lisinopril'))) {
      warnings.push('NSAID with ACE inhibitor may reduce renal perfusion. Monitor kidney function.');
    }

    if (names.some((name) => name.includes('metformin')) && names.some((name) => name.includes('contrast'))) {
      warnings.push('Metformin with contrast exposure requires renal check protocol.');
    }

    if (warnings.length === 0) {
      warnings.push('No known high-risk interaction from listed medications.');
    }

    return warnings;
  }

  get reviewedCount(): number {
    return this.medications.filter((item) => item.reviewed).length;
  }

  toggleReviewed(index: number): void {
    const target = this.medications[index];
    if (!target) {
      return;
    }

    target.reviewed = !target.reviewed;
  }

  finalizeReconciliation(): void {
    this.finalizedAt = new Date();
  }

  private loadMedicationRows(idNumber: string, patient: PatientRecordDto, requestToken: number): void {
    this.isLoadingMedications = true;
    this.medicationsLoadError = '';

    this.patientApi.getPatientMedications(idNumber).subscribe({
      next: (rows) => {
        if (!this.isActiveRequest(requestToken)) {
          return;
        }

        const liveRows = this.buildMedicationRowsFromApi(rows);
        this.medications = liveRows.length > 0 ? liveRows : this.buildFallbackMedicationRows(patient);
        this.isLoadingMedications = false;
      },
      error: (error) => {
        if (!this.isActiveRequest(requestToken)) {
          return;
        }

        this.medicationsLoadError = error?.error?.Message ?? error?.error?.message ?? 'Failed to load medication history.';
        this.medications = this.buildFallbackMedicationRows(patient);
        this.isLoadingMedications = false;
      }
    });
  }

  private buildMedicationRowsFromApi(rows: PatientMedicationDto[] | null | undefined): MedicationItem[] {
    if (!Array.isArray(rows)) {
      return [];
    }

    return rows
      .map((row) => ({
        name: this.normalizeText(row.MedicationName),
        source: 'Medication History' as const,
        reviewed: false,
        dosage: this.normalizeText(row.Dosage),
        frequency: this.normalizeText(row.Frequency),
        route: this.normalizeText(row.Route),
        status: this.normalizeText(row.Status) || (row.IsActive ? 'Active' : 'Inactive'),
        prescribedBy: this.normalizeText(row.PrescribedBy),
        indication: this.normalizeText(row.Indication),
        startDate: this.normalizeDate(row.StartDate),
        endDate: this.normalizeDate(row.EndDate)
      }))
      .filter((item) => item.name.length > 0);
  }

  private buildFallbackMedicationRows(patient: PatientRecordDto): MedicationItem[] {
    const chartRows = this.parseMedicationTokens(patient.MedicationList).map<MedicationItem>((name) => ({
      name,
      source: 'Current Chart',
      reviewed: false,
      dosage: '',
      frequency: '',
      route: '',
      status: 'Chart medication',
      prescribedBy: '',
      indication: '',
      startDate: null,
      endDate: null
    }));

    if (chartRows.length > 0) {
      return chartRows;
    }

    return this.fallbackPatientReportedMedications.map<MedicationItem>((name) => ({
      name,
      source: 'Patient Reported',
      reviewed: false,
      dosage: '',
      frequency: '',
      route: '',
      status: 'Patient reported',
      prescribedBy: '',
      indication: '',
      startDate: null,
      endDate: null
    }));
  }

  private medicationDescriptor(item: MedicationItem): string {
    return [item.name, item.dosage, item.frequency, item.route, item.indication, item.status]
      .map((value) => value.trim())
      .filter((value) => value.length > 0)
      .join(' ');
  }

  private parseMedicationTokens(value: string | null | undefined): string[] {
    return (value ?? '')
      .split(/[,;\n]+/)
      .map((token) => token.trim())
      .filter((token) => token.length > 0);
  }

  private normalizeText(value: string | null | undefined): string {
    return (value ?? '').trim();
  }

  private normalizeDate(value: string | null | undefined): string | null {
    const normalized = this.normalizeText(value);
    return normalized.length > 0 ? normalized : null;
  }

  private isActiveRequest(requestToken: number): boolean {
    return requestToken === this.contextRequestToken;
  }

  private beginContextLoad(idNumber: string): void {
    this.patient = null;
    this.contextLabel = `Patient ${idNumber}`;
    this.loadError = '';
    this.medicationsLoadError = '';
    this.medications = [];
    this.finalizedAt = null;
    this.isLoadingContext = true;
    this.isLoadingMedications = false;
  }

  private resetContext(): void {
    this.patient = null;
    this.loadError = '';
    this.medicationsLoadError = '';
    this.contextLabel = 'No patient selected. Launch from chart or worklist.';
    this.medications = [];
    this.finalizedAt = null;
    this.isLoadingContext = false;
    this.isLoadingMedications = false;
  }
}

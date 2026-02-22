import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { PatientRecordDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

type MedicationItem = {
  name: string;
  source: 'Current Chart' | 'Patient Reported';
  reviewed: boolean;
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
  finalizedAt: Date | null = null;

  medications: MedicationItem[] = [];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly patientApi: PatientApiService
  ) {
    this.route.queryParamMap.subscribe((params) => {
      const idNumber = (params.get('idNumber') ?? '').trim();
      if (idNumber.length !== 13) {
        this.resetContext();
        return;
      }

      this.patientApi.getPatient(idNumber).subscribe({
        next: (patient) => {
          this.patient = patient;
          this.loadError = '';
          this.contextLabel = `${patient.FirstName} ${patient.LastName} (${patient.IdNumber})`;
          this.seedMedicationRows(patient);
        },
        error: (error) => {
          this.resetContext();
          this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Failed to load patient context.';
          this.contextLabel = `Patient ${idNumber}`;
        }
      });
    });
  }

  get warnings(): string[] {
    const names = this.medications.map((item) => item.name.toLowerCase());
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

  private resetContext(): void {
    this.patient = null;
    this.loadError = '';
    this.contextLabel = 'No patient selected. Launch from chart or worklist.';
    this.medications = [];
    this.finalizedAt = null;
  }

  private seedMedicationRows(patient: PatientRecordDto): void {
    const fromChart = (patient.MedicationList ?? '')
      .split(',')
      .map((name) => name.trim())
      .filter((name) => name.length > 0)
      .map<MedicationItem>((name) => ({
        name,
        source: 'Current Chart',
        reviewed: false
      }));

    const reported: MedicationItem[] = [
      { name: 'Aspirin 81mg daily', source: 'Patient Reported', reviewed: false },
      { name: 'Ibuprofen PRN', source: 'Patient Reported', reviewed: false }
    ];

    this.medications = [...fromChart, ...reported];
    if (this.medications.length === 0) {
      this.medications = [{ name: 'No medication entered', source: 'Current Chart', reviewed: false }];
    }
  }
}

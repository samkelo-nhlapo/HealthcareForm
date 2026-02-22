import { CommonModule } from '@angular/common';
import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { PatientRecordDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

@Component({
  selector: 'app-patient-chart',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './patient-chart.component.html',
  styleUrl: './patient-chart.component.scss'
})
export class PatientChartComponent implements OnInit {
  patient: PatientRecordDto | null = null;
  loading = true;
  loadError = '';
  consentStatus = 'Documented';
  private currentIdNumber = '';

  constructor(
    private readonly route: ActivatedRoute,
    private readonly patientApi: PatientApiService
  ) {}

  ngOnInit(): void {
    const idNumber = (this.route.snapshot.paramMap.get('idNumber') ?? '').trim();
    if (!idNumber) {
      this.loading = false;
      this.loadError = 'Patient ID number was not provided.';
      return;
    }

    this.currentIdNumber = idNumber;
    this.loadPatient();
  }

  get patientName(): string {
    if (!this.patient) {
      return '';
    }

    return `${this.patient.FirstName} ${this.patient.LastName}`.trim();
  }

  get age(): number | null {
    if (!this.patient?.DateOfBirth) {
      return null;
    }

    const dob = new Date(this.patient.DateOfBirth);
    if (Number.isNaN(dob.getTime())) {
      return null;
    }

    const today = new Date();
    let years = today.getFullYear() - dob.getFullYear();
    const monthDiff = today.getMonth() - dob.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
      years--;
    }

    return years;
  }

  get riskBand(): 'Critical' | 'High' | 'Moderate' {
    const age = this.age ?? 0;
    const hasMedicationList = (this.patient?.MedicationList ?? '').trim().length > 0;

    if (age >= 75) {
      return 'Critical';
    }

    if (age >= 60 || hasMedicationList) {
      return 'High';
    }

    return 'Moderate';
  }

  get safetyFlags(): string[] {
    if (!this.patient) {
      return [];
    }

    const flags: string[] = [];

    if ((this.patient.MedicationList ?? '').trim().length > 0) {
      flags.push('Medication reconciliation required this visit.');
    }

    if (!(this.patient.EmergencyPhoneNumber ?? '').trim()) {
      flags.push('Emergency phone number missing.');
    }

    if ((this.age ?? 0) >= 65) {
      flags.push('Senior care protocol review recommended.');
    }

    if (flags.length === 0) {
      flags.push('No immediate safety flag from baseline profile.');
    }

    return flags;
  }

  retryLoad(): void {
    if (!this.currentIdNumber) {
      return;
    }

    this.loadPatient();
  }

  private loadPatient(): void {
    this.loading = true;
    this.loadError = '';
    this.patientApi.getPatient(this.currentIdNumber).subscribe({
      next: (patient) => {
        this.patient = patient;
        this.consentStatus = patient.Email ? 'Documented' : 'Pending review';
        this.loading = false;
      },
      error: (error) => {
        this.loading = false;
        this.loadError = error?.error?.Message ?? error?.error?.message ?? 'Unable to load patient chart.';
      }
    });
  }
}

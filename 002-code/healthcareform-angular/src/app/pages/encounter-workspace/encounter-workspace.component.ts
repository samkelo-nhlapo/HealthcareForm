import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { PatientRecordDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

@Component({
  selector: 'app-encounter-workspace',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './encounter-workspace.component.html',
  styleUrl: './encounter-workspace.component.scss'
})
export class EncounterWorkspaceComponent implements OnInit {
  private readonly fb = inject(FormBuilder);

  patient: PatientRecordDto | null = null;
  loadError = '';
  contextLabel = 'No patient selected.';
  draftSavedAt: Date | null = null;
  finalSignedAt: Date | null = null;

  readonly encounterForm = this.fb.nonNullable.group({
    chiefComplaint: ['', Validators.required],
    acuity: ['Routine', Validators.required],
    subjective: ['', [Validators.required, Validators.maxLength(4000)]],
    objective: ['', [Validators.required, Validators.maxLength(4000)]],
    assessment: ['', [Validators.required, Validators.maxLength(4000)]],
    plan: ['', [Validators.required, Validators.maxLength(4000)]],
    allergyReviewed: [false],
    medicationReviewed: [false],
    followUpBooked: [false]
  });

  constructor(
    private readonly route: ActivatedRoute,
    private readonly patientApi: PatientApiService
  ) {}

  ngOnInit(): void {
    this.route.queryParamMap.subscribe((params) => {
      const idNumber = (params.get('idNumber') ?? '').trim();
      if (idNumber.length !== 13) {
        this.patient = null;
        this.contextLabel = 'No patient selected. Launch from worklist or chart.';
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

  saveDraft(): void {
    this.draftSavedAt = new Date();
    this.encounterForm.markAsPristine();
  }

  signEncounter(): void {
    if (this.encounterForm.invalid) {
      this.encounterForm.markAllAsTouched();
      return;
    }

    this.finalSignedAt = new Date();
    this.draftSavedAt = new Date();
    this.encounterForm.markAsPristine();
  }
}

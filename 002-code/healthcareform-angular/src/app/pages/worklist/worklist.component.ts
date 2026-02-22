import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { PatientWorklistItemDto } from '../../models/patient.models';
import { PatientApiService } from '../../services/patient-api.service';

type WorklistRow = {
  idNumber: string;
  patient: string;
  status: 'Waiting' | 'In Progress' | 'Discharged';
  clinic: 'General' | 'Pediatrics' | 'Cardiology' | 'Oncology';
  risk: 'Low' | 'Moderate' | 'High' | 'Critical';
  updatedOn: string;
};

@Component({
  selector: 'app-worklist',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './worklist.component.html',
  styleUrl: './worklist.component.scss'
})
export class WorklistComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly patientApiService = inject(PatientApiService);

  isLoading = true;
  loadError = '';

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    status: ['ALL'],
    clinic: ['ALL'],
    risk: ['ALL'],
    dateFrom: [''],
    dateTo: ['']
  });

  rows: WorklistRow[] = [];

  ngOnInit(): void {
    this.loadWorklist();
  }

  get filteredRows(): WorklistRow[] {
    const value = this.filters.getRawValue();
    const search = value.search.trim().toLowerCase();

    return this.rows.filter((row) => {
      const matchesSearch = !search
        || row.patient.toLowerCase().includes(search)
        || row.idNumber.includes(search);

      const matchesStatus = value.status === 'ALL' || row.status === value.status;
      const matchesClinic = value.clinic === 'ALL' || row.clinic === value.clinic;
      const matchesRisk = value.risk === 'ALL' || row.risk === value.risk;

      const rowDate = Date.parse(row.updatedOn);
      const fromDate = value.dateFrom ? Date.parse(value.dateFrom) : null;
      const toDate = value.dateTo ? Date.parse(value.dateTo) : null;

      const matchesFrom = fromDate === null || rowDate >= fromDate;
      const matchesTo = toDate === null || rowDate <= toDate;

      return matchesSearch && matchesStatus && matchesClinic && matchesRisk && matchesFrom && matchesTo;
    });
  }

  clearFilters(): void {
    this.filters.reset({
      search: '',
      status: 'ALL',
      clinic: 'ALL',
      risk: 'ALL',
      dateFrom: '',
      dateTo: ''
    });
  }

  retryLoad(): void {
    this.loadWorklist();
  }

  private loadWorklist(): void {
    this.isLoading = true;
    this.loadError = '';

    this.patientApiService.getWorklist().subscribe({
      next: (rows) => {
        this.rows = Array.isArray(rows) ? rows.map((row) => this.toWorklistRow(row)) : [];
        this.isLoading = false;
      },
      error: () => {
        this.rows = [];
        this.loadError = 'Unable to load patient worklist. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private toWorklistRow(row: PatientWorklistItemDto): WorklistRow {
    return {
      idNumber: row.IdNumber,
      patient: row.Patient,
      status: this.normalizeStatus(row.Status),
      clinic: this.normalizeClinic(row.Clinic),
      risk: this.normalizeRisk(row.Risk),
      updatedOn: row.UpdatedOn
    };
  }

  private normalizeStatus(value: string): WorklistRow['status'] {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'in progress') {
      return 'In Progress';
    }

    if (normalized === 'discharged') {
      return 'Discharged';
    }

    return 'Waiting';
  }

  private normalizeClinic(value: string): WorklistRow['clinic'] {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'cardiology') {
      return 'Cardiology';
    }

    if (normalized === 'pediatrics') {
      return 'Pediatrics';
    }

    if (normalized === 'oncology') {
      return 'Oncology';
    }

    return 'General';
  }

  private normalizeRisk(value: string): WorklistRow['risk'] {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'critical') {
      return 'Critical';
    }

    if (normalized === 'high') {
      return 'High';
    }

    if (normalized === 'moderate') {
      return 'Moderate';
    }

    return 'Low';
  }
}

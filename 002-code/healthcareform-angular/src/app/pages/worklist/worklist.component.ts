import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

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
export class WorklistComponent {
  private readonly fb = inject(FormBuilder);

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    status: ['ALL'],
    clinic: ['ALL'],
    risk: ['ALL'],
    dateFrom: [''],
    dateTo: ['']
  });

  readonly rows: WorklistRow[] = [
    { idNumber: '9101015001089', patient: 'Nomsa Mokoena', status: 'Waiting', clinic: 'General', risk: 'Critical', updatedOn: '2026-02-21' },
    { idNumber: '8206066002087', patient: 'Liam Smith', status: 'In Progress', clinic: 'Cardiology', risk: 'High', updatedOn: '2026-02-20' },
    { idNumber: '0310037003084', patient: 'Asha Patel', status: 'Waiting', clinic: 'Pediatrics', risk: 'Moderate', updatedOn: '2026-02-18' },
    { idNumber: '7507078004082', patient: 'Sibusiso Khumalo', status: 'Discharged', clinic: 'Oncology', risk: 'High', updatedOn: '2026-02-15' },
    { idNumber: '9902029005081', patient: 'Jordan Daniels', status: 'Waiting', clinic: 'General', risk: 'Low', updatedOn: '2026-02-11' }
  ];

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
}

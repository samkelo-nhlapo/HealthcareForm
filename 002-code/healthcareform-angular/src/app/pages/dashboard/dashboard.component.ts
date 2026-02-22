import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

type Metric = {
  label: string;
  value: string;
  trend: string;
};

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent {
  readonly metrics: Metric[] = [
    { label: 'Active Patients Today', value: '148', trend: '+12% vs yesterday' },
    { label: 'Pending Triage', value: '19', trend: '4 critical priority' },
    { label: 'Open Clinical Tasks', value: '57', trend: '11 overdue actions' },
    { label: 'Billing Exceptions', value: '6', trend: '2 need payer follow-up' }
  ];

  readonly alerts: string[] = [
    'Medication reconciliation pending for 8 discharge summaries.',
    'Lab turnaround SLA exceeded in 2 departments.',
    'Three staff accounts require MFA re-enrollment.'
  ];
}

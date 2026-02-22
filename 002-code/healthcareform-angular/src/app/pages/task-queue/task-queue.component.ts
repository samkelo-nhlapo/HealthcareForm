import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';

type QueuePriority = 'Routine' | 'Urgent' | 'Critical';
type QueueStatus = 'Open' | 'In Progress' | 'Escalated' | 'Blocked' | 'Completed';
type QueueTeam = 'Nursing' | 'Clinical' | 'Laboratory' | 'Pharmacy' | 'Billing';

type TaskQueueRow = {
  taskId: string;
  title: string;
  team: QueueTeam;
  owner: string;
  patient: string;
  idNumber: string;
  priority: QueuePriority;
  status: QueueStatus;
  dueAt: string;
  slaMinutes: number;
  elapsedMinutes: number;
};

@Component({
  selector: 'app-task-queue',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink],
  templateUrl: './task-queue.component.html',
  styleUrl: './task-queue.component.scss'
})
export class TaskQueueComponent {
  private readonly fb = inject(FormBuilder);

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    team: ['ALL'],
    priority: ['ALL'],
    status: ['ACTIVE'],
    breachedOnly: [false]
  });

  readonly rows: TaskQueueRow[] = [
    {
      taskId: 'TQ-1004',
      title: 'Follow-up pain reassessment',
      team: 'Nursing',
      owner: 'S. Mokoena',
      patient: 'Nomsa Mokoena',
      idNumber: '9101015001089',
      priority: 'Critical',
      status: 'Escalated',
      dueAt: '2026-02-21 09:20',
      slaMinutes: 20,
      elapsedMinutes: 29
    },
    {
      taskId: 'TQ-1008',
      title: 'Medication interaction review',
      team: 'Pharmacy',
      owner: 'A. Daniels',
      patient: 'Liam Smith',
      idNumber: '8206066002087',
      priority: 'Urgent',
      status: 'In Progress',
      dueAt: '2026-02-21 09:40',
      slaMinutes: 45,
      elapsedMinutes: 31
    },
    {
      taskId: 'TQ-1012',
      title: 'CBC recollection request',
      team: 'Laboratory',
      owner: 'R. Jacobs',
      patient: 'Asha Patel',
      idNumber: '0310037003084',
      priority: 'Urgent',
      status: 'Open',
      dueAt: '2026-02-21 09:55',
      slaMinutes: 60,
      elapsedMinutes: 22
    },
    {
      taskId: 'TQ-1021',
      title: 'Authorisation packet submission',
      team: 'Billing',
      owner: 'T. Maseko',
      patient: 'Sibusiso Khumalo',
      idNumber: '7507078004082',
      priority: 'Routine',
      status: 'Blocked',
      dueAt: '2026-02-21 10:15',
      slaMinutes: 180,
      elapsedMinutes: 156
    },
    {
      taskId: 'TQ-1029',
      title: 'Finalize discharge education checklist',
      team: 'Clinical',
      owner: 'J. Adams',
      patient: 'Jordan Daniels',
      idNumber: '9902029005081',
      priority: 'Routine',
      status: 'Completed',
      dueAt: '2026-02-21 08:50',
      slaMinutes: 90,
      elapsedMinutes: 72
    }
  ];

  get filteredRows(): TaskQueueRow[] {
    const value = this.filters.getRawValue();
    const search = value.search.trim().toLowerCase();

    return this.rows
      .filter((row) => {
        const matchesSearch = !search
          || row.title.toLowerCase().includes(search)
          || row.patient.toLowerCase().includes(search)
          || row.idNumber.includes(search)
          || row.taskId.toLowerCase().includes(search);

        const matchesTeam = value.team === 'ALL' || row.team === value.team;
        const matchesPriority = value.priority === 'ALL' || row.priority === value.priority;

        const matchesStatus = value.status === 'ALL'
          || (value.status === 'ACTIVE' ? row.status !== 'Completed' : row.status === value.status);

        const matchesBreach = !value.breachedOnly || this.isBreached(row);

        return matchesSearch && matchesTeam && matchesPriority && matchesStatus && matchesBreach;
      })
      .sort((a, b) => this.sortScore(b) - this.sortScore(a));
  }

  get openTasks(): number {
    return this.rows.filter((row) => row.status !== 'Completed').length;
  }

  get breachedTasks(): number {
    return this.rows.filter((row) => this.isBreached(row)).length;
  }

  get escalatedTasks(): number {
    return this.rows.filter((row) => row.status === 'Escalated').length;
  }

  get averageSlaUse(): number {
    const activeRows = this.rows.filter((row) => row.status !== 'Completed');
    if (activeRows.length === 0) {
      return 0;
    }

    const totalPercent = activeRows.reduce((sum, row) => sum + this.slaPercent(row), 0);
    return Math.round(totalPercent / activeRows.length);
  }

  isBreached(row: TaskQueueRow): boolean {
    return row.status !== 'Completed' && row.elapsedMinutes > row.slaMinutes;
  }

  slaPercent(row: TaskQueueRow): number {
    if (row.slaMinutes <= 0) {
      return 0;
    }

    return Math.round((row.elapsedMinutes / row.slaMinutes) * 100);
  }

  slaBarWidth(row: TaskQueueRow): number {
    return Math.min(100, this.slaPercent(row));
  }

  slaState(row: TaskQueueRow): 'healthy' | 'warning' | 'breach' {
    const percent = this.slaPercent(row);
    if (percent > 100) {
      return 'breach';
    }

    if (percent >= 80) {
      return 'warning';
    }

    return 'healthy';
  }

  overdueMinutes(row: TaskQueueRow): number {
    return Math.max(0, row.elapsedMinutes - row.slaMinutes);
  }

  remainingMinutes(row: TaskQueueRow): number {
    return Math.max(0, row.slaMinutes - row.elapsedMinutes);
  }

  private sortScore(row: TaskQueueRow): number {
    const breachScore = this.isBreached(row) ? 1000 : 0;
    const priorityScore = this.priorityScore(row.priority);
    const statusScore = row.status === 'Escalated' ? 120 : row.status === 'Blocked' ? 80 : 0;

    return breachScore + priorityScore + statusScore + this.slaPercent(row);
  }

  private priorityScore(priority: QueuePriority): number {
    if (priority === 'Critical') {
      return 90;
    }

    if (priority === 'Urgent') {
      return 60;
    }

    return 30;
  }
}

import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TaskQueueItemDto, TaskQueueSnapshotDto } from '../../models/operations.models';
import { OperationsApiService } from '../../services/operations-api.service';

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
export class TaskQueueComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly operationsApiService = inject(OperationsApiService);

  isLoading = true;
  loadError = '';

  readonly filters = this.fb.nonNullable.group({
    search: [''],
    team: ['ALL'],
    priority: ['ALL'],
    status: ['ACTIVE'],
    breachedOnly: [false]
  });

  rows: TaskQueueRow[] = [];

  ngOnInit(): void {
    this.loadSnapshot();
  }

  retryLoad(): void {
    this.loadSnapshot();
  }

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

  private loadSnapshot(): void {
    this.isLoading = true;
    this.loadError = '';

    this.operationsApiService.getTaskQueueSnapshot().subscribe({
      next: (snapshot) => {
        this.applySnapshot(snapshot);
        this.isLoading = false;
      },
      error: () => {
        this.rows = [];
        this.loadError = 'Unable to load task queue data. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private applySnapshot(snapshot: TaskQueueSnapshotDto): void {
    this.rows = Array.isArray(snapshot.Tasks)
      ? snapshot.Tasks.map((row) => this.mapRow(row))
      : [];
  }

  private mapRow(row: TaskQueueItemDto): TaskQueueRow {
    return {
      taskId: this.readText(row.TaskId, 'TQ-UNKNOWN'),
      title: this.readText(row.Title, 'Untitled Task'),
      team: this.normalizeTeam(row.Team),
      owner: this.readText(row.Owner, 'Care Team'),
      patient: this.readText(row.Patient, 'Unknown Patient'),
      idNumber: this.readText(row.IdNumber, ''),
      priority: this.normalizePriority(row.Priority),
      status: this.normalizeStatus(row.Status),
      dueAt: this.readText(row.DueAt, ''),
      slaMinutes: this.coerceMinutes(row.SlaMinutes, 60),
      elapsedMinutes: this.coerceMinutes(row.ElapsedMinutes)
    };
  }

  private normalizeTeam(value: string): QueueTeam {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'nursing') {
      return 'Nursing';
    }

    if (normalized === 'laboratory') {
      return 'Laboratory';
    }

    if (normalized === 'pharmacy') {
      return 'Pharmacy';
    }

    if (normalized === 'billing') {
      return 'Billing';
    }

    return 'Clinical';
  }

  private normalizePriority(value: string): QueuePriority {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'critical') {
      return 'Critical';
    }

    if (normalized === 'urgent') {
      return 'Urgent';
    }

    return 'Routine';
  }

  private normalizeStatus(value: string): QueueStatus {
    const normalized = (value ?? '').trim().toLowerCase();

    if (normalized === 'in progress') {
      return 'In Progress';
    }

    if (normalized === 'escalated') {
      return 'Escalated';
    }

    if (normalized === 'blocked') {
      return 'Blocked';
    }

    if (normalized === 'completed') {
      return 'Completed';
    }

    return 'Open';
  }

  private coerceMinutes(value: unknown, fallback = 0): number {
    const numeric = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(numeric) ? Math.max(0, Math.round(numeric)) : fallback;
  }

  private readText(value: unknown, fallback: string): string {
    if (typeof value !== 'string') {
      return fallback;
    }

    const normalized = value.trim();
    return normalized.length > 0 ? normalized : fallback;
  }
}

import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import {
  SchedulingResourceLoadDto,
  SchedulingSnapshotDto,
  SchedulingTimeBlockDto,
  SchedulingProviderLoadDto
} from '../../models/operations.models';
import { OperationsApiService } from '../../services/operations-api.service';

type Clinic = 'General' | 'Cardiology' | 'Pediatrics' | 'Oncology';

type ProviderLoad = {
  provider: string;
  clinic: Clinic;
  room: string;
  booked: number;
  capacity: number;
  nextSlot: string;
};

type ResourceLoad = {
  resource: string;
  clinic: Clinic;
  allocated: number;
  available: number;
  turnaroundMinutes: number;
};

type TimeBlock = {
  time: string;
  general: number;
  cardiology: number;
  pediatrics: number;
  oncology: number;
};

@Component({
  selector: 'app-scheduling',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './scheduling.component.html',
  styleUrl: './scheduling.component.scss'
})
export class SchedulingComponent implements OnInit {
  private readonly operationsApiService = inject(OperationsApiService);

  selectedClinic: 'ALL' | Clinic = 'ALL';
  isLoading = true;
  loadError = '';
  lastRefreshedAt = '';

  providers: ProviderLoad[] = [];

  resources: ResourceLoad[] = [];

  blocks: TimeBlock[] = [];

  ngOnInit(): void {
    this.loadSnapshot();
  }

  setClinic(clinic: string): void {
    if (clinic === 'General' || clinic === 'Cardiology' || clinic === 'Pediatrics' || clinic === 'Oncology') {
      this.selectedClinic = clinic;
      return;
    }

    this.selectedClinic = 'ALL';
  }

  retryLoad(): void {
    this.loadSnapshot();
  }

  get hasSnapshotData(): boolean {
    return this.providers.length > 0 || this.resources.length > 0;
  }

  get hasFilteredProviders(): boolean {
    return this.filteredProviders.length > 0;
  }

  get hasFilteredResources(): boolean {
    return this.filteredResources.length > 0;
  }

  get hasBlocks(): boolean {
    return this.blocks.length > 0;
  }

  get isSnapshotEmpty(): boolean {
    return !this.hasSnapshotData;
  }

  get filteredProviders(): ProviderLoad[] {
    if (this.selectedClinic === 'ALL') {
      return this.providers;
    }

    return this.providers.filter((provider) => provider.clinic === this.selectedClinic);
  }

  get filteredResources(): ResourceLoad[] {
    if (this.selectedClinic === 'ALL') {
      return this.resources;
    }

    return this.resources.filter((resource) => resource.clinic === this.selectedClinic);
  }

  get totalBookings(): number {
    return this.filteredProviders.reduce((sum, provider) => sum + provider.booked, 0);
  }

  get totalCapacity(): number {
    return this.filteredProviders.reduce((sum, provider) => sum + provider.capacity, 0);
  }

  get utilizationPercent(): number {
    if (this.totalCapacity === 0) {
      return 0;
    }

    return Math.round((this.totalBookings / this.totalCapacity) * 100);
  }

  get delayedResources(): number {
    return this.filteredResources.filter((resource) => resource.turnaroundMinutes > 25).length;
  }

  get nearCapacityProviders(): number {
    return this.filteredProviders.filter((provider) => provider.booked >= provider.capacity).length;
  }

  providerUtilization(provider: ProviderLoad): number {
    if (provider.capacity === 0) {
      return 0;
    }

    return Math.min(100, Math.round((provider.booked / provider.capacity) * 100));
  }

  providerRisk(provider: ProviderLoad): 'healthy' | 'warning' | 'critical' {
    const percent = this.providerUtilization(provider);
    if (percent >= 100) {
      return 'critical';
    }

    if (percent >= 85) {
      return 'warning';
    }

    return 'healthy';
  }

  resourceStatus(resource: ResourceLoad): 'available' | 'busy' | 'delayed' {
    if (resource.turnaroundMinutes > 25) {
      return 'delayed';
    }

    if (resource.available === 0) {
      return 'busy';
    }

    return 'available';
  }

  resourceLoadPercent(resource: ResourceLoad): number {
    const total = resource.allocated + resource.available;
    if (total === 0) {
      return 0;
    }

    return Math.round((resource.allocated / total) * 100);
  }

  private loadSnapshot(): void {
    this.isLoading = true;
    this.loadError = '';

    this.operationsApiService.getSchedulingSnapshot().subscribe({
      next: (snapshot) => {
        this.applySnapshot(snapshot);
        this.lastRefreshedAt = this.formatTimestamp(new Date());
        this.isLoading = false;
      },
      error: () => {
        this.providers = [];
        this.resources = [];
        this.blocks = [];
        this.loadError = 'Unable to load scheduling data. Check API connectivity and retry.';
        this.isLoading = false;
      }
    });
  }

  private applySnapshot(snapshot: SchedulingSnapshotDto): void {
    this.providers = Array.isArray(snapshot.Providers)
      ? snapshot.Providers.map((provider) => this.mapProvider(provider))
      : [];

    this.resources = Array.isArray(snapshot.Resources)
      ? snapshot.Resources.map((resource) => this.mapResource(resource))
      : [];

    this.blocks = Array.isArray(snapshot.Blocks)
      ? snapshot.Blocks.map((block) => this.mapBlock(block))
      : [];
  }

  private mapProvider(provider: SchedulingProviderLoadDto): ProviderLoad {
    const booked = this.coerceNumber(provider.Booked);
    const capacity = Math.max(booked, this.coerceNumber(provider.Capacity, 12));

    return {
      provider: this.readText(provider.Provider, 'Provider'),
      clinic: this.normalizeClinic(provider.Clinic),
      room: this.readText(provider.Room, 'Unassigned'),
      booked,
      capacity,
      nextSlot: this.readText(provider.NextSlot, 'N/A')
    };
  }

  private mapResource(resource: SchedulingResourceLoadDto): ResourceLoad {
    const allocated = this.coerceNumber(resource.Allocated);
    const available = this.coerceNumber(resource.Available);

    return {
      resource: this.readText(resource.Resource, 'Resource Pool'),
      clinic: this.normalizeClinic(resource.Clinic),
      allocated,
      available,
      turnaroundMinutes: this.coerceNumber(resource.TurnaroundMinutes, 15)
    };
  }

  private mapBlock(block: SchedulingTimeBlockDto): TimeBlock {
    return {
      time: this.readText(block.Time, '00:00'),
      general: this.coercePercent(block.General),
      cardiology: this.coercePercent(block.Cardiology),
      pediatrics: this.coercePercent(block.Pediatrics),
      oncology: this.coercePercent(block.Oncology)
    };
  }

  private normalizeClinic(value: string): Clinic {
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

  private coercePercent(value: unknown): number {
    const number = this.coerceNumber(value);
    return Math.max(0, Math.min(100, number));
  }

  private coerceNumber(value: unknown, fallback = 0): number {
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

  private formatTimestamp(date: Date): string {
    return date.toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  }
}

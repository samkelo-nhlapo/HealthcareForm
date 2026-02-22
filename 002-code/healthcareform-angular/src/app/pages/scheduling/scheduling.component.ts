import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

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
export class SchedulingComponent {
  selectedClinic: 'ALL' | Clinic = 'ALL';

  readonly providers: ProviderLoad[] = [
    { provider: 'Dr. Naidoo', clinic: 'General', room: 'Room 2A', booked: 14, capacity: 18, nextSlot: '10:20' },
    { provider: 'Dr. Patel', clinic: 'Cardiology', room: 'Room 4C', booked: 12, capacity: 12, nextSlot: '11:10' },
    { provider: 'Dr. Maseko', clinic: 'Oncology', room: 'Room 5B', booked: 10, capacity: 11, nextSlot: '09:55' },
    { provider: 'Dr. Adams', clinic: 'Pediatrics', room: 'Room 3D', booked: 8, capacity: 14, nextSlot: '10:40' }
  ];

  readonly resources: ResourceLoad[] = [
    { resource: 'Ultrasound Unit A', clinic: 'General', allocated: 7, available: 2, turnaroundMinutes: 14 },
    { resource: 'ECG Machine 2', clinic: 'Cardiology', allocated: 12, available: 0, turnaroundMinutes: 32 },
    { resource: 'Infusion Bay 1', clinic: 'Oncology', allocated: 6, available: 1, turnaroundMinutes: 29 },
    { resource: 'Peds Observation Bed', clinic: 'Pediatrics', allocated: 9, available: 3, turnaroundMinutes: 11 }
  ];

  readonly blocks: TimeBlock[] = [
    { time: '08:00', general: 68, cardiology: 75, pediatrics: 41, oncology: 56 },
    { time: '10:00', general: 76, cardiology: 92, pediatrics: 58, oncology: 63 },
    { time: '12:00', general: 61, cardiology: 88, pediatrics: 66, oncology: 71 },
    { time: '14:00', general: 54, cardiology: 79, pediatrics: 52, oncology: 69 },
    { time: '16:00', general: 42, cardiology: 55, pediatrics: 48, oncology: 57 }
  ];

  setClinic(clinic: string): void {
    if (clinic === 'General' || clinic === 'Cardiology' || clinic === 'Pediatrics' || clinic === 'Oncology') {
      this.selectedClinic = clinic;
      return;
    }

    this.selectedClinic = 'ALL';
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
}

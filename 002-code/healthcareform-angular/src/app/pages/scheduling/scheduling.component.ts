import { CommonModule } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { Component, OnInit, inject } from '@angular/core';
import {
  SchedulingAppointmentCommandResultDto,
  SchedulingAppointmentCreateRequestDto,
  SchedulingBookingClientDto,
  SchedulingBookingOptionsDto,
  SchedulingBookingProviderDto,
  SchedulingResourceLoadDto,
  SchedulingProviderLoadDto,
  SchedulingTimeBlockDto,
  SchedulingSnapshotDto
} from '../../models/operations.models';
import { isValidPatientIdNumber, normalizePatientIdNumber } from '../../models/patient-id.utils';
import { OperationsApiService } from '../../services/operations-api.service';

type Clinic = 'General' | 'Cardiology' | 'Pediatrics' | 'Oncology';
const GUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

type ProviderLoad = {
  clientProviderAffiliationId: string;
  clientStaffId: string;
  clientId: string;
  clientName: string;
  providerId: string;
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

type BookingClient = {
  clientId: string;
  clientName: string;
  clientCode: string;
  clientCategory: string;
};

type BookingProvider = {
  clientProviderAffiliationId: string;
  clientStaffId: string;
  providerId: string;
  clientId: string;
  provider: string;
  clinic: Clinic;
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
  isSubmittingAppointment = false;
  appointmentSubmitError = '';
  appointmentSubmitSuccess = '';
  bookingLoadError = '';
  appointmentClientId = '';
  appointmentPatientIdNumber = '';
  appointmentClientProviderAffiliationId = '';
  appointmentDateTimeLocal = '';
  appointmentDurationMinutes = 30;
  appointmentType = 'Consultation';
  appointmentReason = '';
  appointmentLocation = '';

  providers: ProviderLoad[] = [];
  resources: ResourceLoad[] = [];
  blocks: TimeBlock[] = [];
  bookingClients: BookingClient[] = [];
  bookingProviders: BookingProvider[] = [];

  ngOnInit(): void {
    this.appointmentDateTimeLocal = this.buildDefaultAppointmentDateTimeLocal();
    this.loadBookingOptions();
    this.loadSnapshot();
  }

  setClinic(clinic: string): void {
    if (clinic === 'General' || clinic === 'Cardiology' || clinic === 'Pediatrics' || clinic === 'Oncology') {
      this.selectedClinic = clinic;
      return;
    }

    this.selectedClinic = 'ALL';
  }

  setAppointmentClient(clientId: string): void {
    this.appointmentClientId = this.readText(clientId, '');
    this.syncAppointmentProviderSelection();
  }

  retryLoad(): void {
    this.loadSnapshot();
  }

  submitAppointment(): void {
    this.appointmentSubmitError = '';
    this.appointmentSubmitSuccess = '';

    if (!this.canSubmitAppointment) {
      this.appointmentSubmitError = 'Complete required fields to schedule an appointment.';
      return;
    }

    const request: SchedulingAppointmentCreateRequestDto = {
      ClientId: this.appointmentClientId,
      PatientIdNumber: normalizePatientIdNumber(this.appointmentPatientIdNumber),
      ClientProviderAffiliationId: this.appointmentClientProviderAffiliationId,
      ClientStaffId: this.selectedAppointmentProvider?.clientStaffId || undefined,
      AppointmentDateTime: this.toApiDateTime(this.appointmentDateTimeLocal),
      DurationMinutes: this.coerceNumber(this.appointmentDurationMinutes, 30),
      AppointmentType: this.readText(this.appointmentType, 'Consultation'),
      Reason: this.readText(this.appointmentReason, 'General consultation'),
      Location: this.readText(this.appointmentLocation, '')
    };

    this.isSubmittingAppointment = true;
    this.operationsApiService.createSchedulingAppointment(request).subscribe({
      next: (result) => {
        this.isSubmittingAppointment = false;
        this.appointmentSubmitSuccess = this.resolveSuccessMessage(result);
        this.resetAppointmentFormAfterSuccess();
        this.loadSnapshot();
      },
      error: (error: HttpErrorResponse) => {
        this.isSubmittingAppointment = false;
        this.appointmentSubmitError = this.resolveAppointmentSubmitError(error);
      }
    });
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

  get hasBookingClients(): boolean {
    return this.bookingClients.length > 0;
  }

  get selectedAppointmentProvider(): BookingProvider | null {
    if (!GUID_PATTERN.test(this.appointmentClientProviderAffiliationId)) {
      return null;
    }

    return this.appointmentProviders.find(
      (provider) => provider.clientProviderAffiliationId === this.appointmentClientProviderAffiliationId
    ) ?? null;
  }

  get appointmentProviders(): BookingProvider[] {
    if (!GUID_PATTERN.test(this.appointmentClientId)) {
      return [];
    }

    return this.bookingProviders.filter((provider) => provider.clientId === this.appointmentClientId);
  }

  get hasAppointmentProviders(): boolean {
    return this.appointmentProviders.length > 0;
  }

  get hasSelectedAppointmentClient(): boolean {
    return GUID_PATTERN.test(this.appointmentClientId);
  }

  get appointmentProviderPlaceholder(): string {
    if (!this.hasSelectedAppointmentClient) {
      return 'Select clinic or hospital first';
    }

    if (!this.hasAppointmentProviders) {
      return 'No doctor providers available';
    }

    return 'Select doctor';
  }

  get canSubmitAppointment(): boolean {
    return !this.isSubmittingAppointment
      && this.hasBookingClients
      && this.hasAppointmentProviders
      && GUID_PATTERN.test(this.appointmentClientId)
      && isValidPatientIdNumber(this.appointmentPatientIdNumber)
      && GUID_PATTERN.test(this.appointmentClientProviderAffiliationId)
      && this.isValidDateTimeLocal(this.appointmentDateTimeLocal)
      && this.appointmentDurationMinutes >= 5
      && this.appointmentDurationMinutes <= 480;
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

  private loadBookingOptions(): void {
    this.bookingLoadError = '';

    this.operationsApiService.getSchedulingBookingOptions().subscribe({
      next: (options) => {
        this.applyBookingOptions(options);
      },
      error: () => {
        this.bookingClients = [];
        this.bookingProviders = [];
        this.appointmentClientId = '';
        this.appointmentClientProviderAffiliationId = '';
        this.bookingLoadError = 'Unable to load clinic/provider booking options.';
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

  private applyBookingOptions(options: SchedulingBookingOptionsDto): void {
    this.bookingClients = Array.isArray(options.Clients)
      ? options.Clients.map((client) => this.mapBookingClient(client))
      : [];

    this.bookingProviders = Array.isArray(options.Providers)
      ? options.Providers.map((provider) => this.mapBookingProvider(provider))
      : [];

    this.syncAppointmentClientSelection();
    this.syncAppointmentProviderSelection();
  }

  private mapProvider(provider: SchedulingProviderLoadDto): ProviderLoad {
    const booked = this.coerceNumber(provider.Booked);
    const capacity = Math.max(booked, this.coerceNumber(provider.Capacity, 12));

    return {
      clientProviderAffiliationId: this.readText(provider.ClientProviderAffiliationId, ''),
      clientStaffId: this.readText(provider.ClientStaffId, ''),
      clientId: this.readText(provider.ClientId, ''),
      clientName: this.readText(provider.ClientName, 'Client'),
      providerId: this.readText(provider.ProviderId, ''),
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

  private mapBookingClient(client: SchedulingBookingClientDto): BookingClient {
    return {
      clientId: this.readText(client.ClientId, ''),
      clientName: this.readText(client.ClientName, 'Client'),
      clientCode: this.readText(client.ClientCode, ''),
      clientCategory: this.readText(client.ClientCategory, 'Uncategorized')
    };
  }

  private mapBookingProvider(provider: SchedulingBookingProviderDto): BookingProvider {
    return {
      clientProviderAffiliationId: this.readText(provider.ClientProviderAffiliationId, ''),
      clientStaffId: this.readText(provider.ClientStaffId, ''),
      providerId: this.readText(provider.ProviderId, ''),
      clientId: this.readText(provider.ClientId, ''),
      provider: this.readText(provider.Provider, 'Provider'),
      clinic: this.normalizeClinic(provider.Clinic)
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

  private syncAppointmentProviderSelection(): void {
    const options = this.appointmentProviders;
    if (options.length === 0) {
      this.appointmentClientProviderAffiliationId = '';
      return;
    }

    if (!options.some((provider) => provider.clientProviderAffiliationId === this.appointmentClientProviderAffiliationId)) {
      this.appointmentClientProviderAffiliationId = '';
    }
  }

  private syncAppointmentClientSelection(): void {
    if (this.bookingClients.length === 0) {
      this.appointmentClientId = '';
      this.appointmentClientProviderAffiliationId = '';
      return;
    }

    if (!this.bookingClients.some((client) => client.clientId === this.appointmentClientId)) {
      this.appointmentClientId = '';
      this.appointmentClientProviderAffiliationId = '';
    }
  }

  private resolveSuccessMessage(result: SchedulingAppointmentCommandResultDto): string {
    const message = this.readText(result.Message, '');
    return message.length > 0 ? message : 'Appointment scheduled successfully.';
  }

  private resolveAppointmentSubmitError(error: HttpErrorResponse): string {
    if (error.status === 0) {
      return 'Unable to reach the API. Check backend connectivity and retry.';
    }

    const messageFromPayload = this.readErrorMessage(error.error);
    if (messageFromPayload.length > 0) {
      return messageFromPayload;
    }

    return `Unable to schedule appointment (HTTP ${error.status}).`;
  }

  private readErrorMessage(payload: unknown): string {
    if (!payload || typeof payload !== 'object') {
      return '';
    }

    const payloadRecord = payload as Record<string, unknown>;
    const directMessage = this.readText(payloadRecord['Message'], '');
    if (directMessage.length > 0) {
      return directMessage;
    }

    const validationErrors = payloadRecord['errors'];
    if (!validationErrors || typeof validationErrors !== 'object') {
      return '';
    }

    const errorMap = validationErrors as Record<string, unknown>;
    for (const key of Object.keys(errorMap)) {
      const value = errorMap[key];
      if (Array.isArray(value) && value.length > 0 && typeof value[0] === 'string') {
        return value[0].trim();
      }
    }

    return '';
  }

  private isValidDateTimeLocal(value: string): boolean {
    const normalized = value.trim();
    if (normalized.length < 16) {
      return false;
    }

    return !Number.isNaN(new Date(normalized).getTime());
  }

  private toApiDateTime(localValue: string): string {
    const normalized = localValue.trim();
    if (normalized.length === 16) {
      return `${normalized}:00`;
    }

    return normalized;
  }

  private resetAppointmentFormAfterSuccess(): void {
    this.appointmentDateTimeLocal = this.buildDefaultAppointmentDateTimeLocal();
    this.appointmentDurationMinutes = 30;
    this.appointmentType = 'Consultation';
    this.appointmentReason = '';
    this.appointmentLocation = '';
  }

  private buildDefaultAppointmentDateTimeLocal(now: Date = new Date()): string {
    const nextSlot = new Date(now);
    nextSlot.setSeconds(0, 0);
    nextSlot.setMinutes(0);
    nextSlot.setHours(nextSlot.getHours() + 1);

    return this.toLocalDateTimeInput(nextSlot);
  }

  private toLocalDateTimeInput(value: Date): string {
    const year = value.getFullYear();
    const month = `${value.getMonth() + 1}`.padStart(2, '0');
    const day = `${value.getDate()}`.padStart(2, '0');
    const hours = `${value.getHours()}`.padStart(2, '0');
    const minutes = `${value.getMinutes()}`.padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
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

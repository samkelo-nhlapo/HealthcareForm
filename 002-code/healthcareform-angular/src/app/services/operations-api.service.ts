import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  SchedulingAppointmentCommandResultDto,
  SchedulingAppointmentCreateRequestDto,
  SchedulingBookingOptionsDto,
  SchedulingSnapshotDto,
  TaskQueueSnapshotDto
} from '../models/operations.models';

@Injectable({ providedIn: 'root' })
export class OperationsApiService {
  private readonly apiBaseUrl = '/api/operations';

  constructor(private readonly http: HttpClient) {}

  getSchedulingSnapshot(): Observable<SchedulingSnapshotDto> {
    return this.http.get<SchedulingSnapshotDto>(`${this.apiBaseUrl}/scheduling`);
  }

  getSchedulingBookingOptions(): Observable<SchedulingBookingOptionsDto> {
    return this.http.get<SchedulingBookingOptionsDto>(`${this.apiBaseUrl}/scheduling/booking-options`);
  }

  createSchedulingAppointment(request: SchedulingAppointmentCreateRequestDto): Observable<SchedulingAppointmentCommandResultDto> {
    return this.http.post<SchedulingAppointmentCommandResultDto>(`${this.apiBaseUrl}/scheduling/appointments`, request);
  }

  getTaskQueueSnapshot(): Observable<TaskQueueSnapshotDto> {
    return this.http.get<TaskQueueSnapshotDto>(`${this.apiBaseUrl}/task-queue`);
  }
}

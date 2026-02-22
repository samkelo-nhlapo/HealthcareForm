import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { SchedulingSnapshotDto, TaskQueueSnapshotDto } from '../models/operations.models';

@Injectable({ providedIn: 'root' })
export class OperationsApiService {
  private readonly apiBaseUrl = '/api/operations';

  constructor(private readonly http: HttpClient) {}

  getSchedulingSnapshot(): Observable<SchedulingSnapshotDto> {
    return this.http.get<SchedulingSnapshotDto>(`${this.apiBaseUrl}/scheduling`);
  }

  getTaskQueueSnapshot(): Observable<TaskQueueSnapshotDto> {
    return this.http.get<TaskQueueSnapshotDto>(`${this.apiBaseUrl}/task-queue`);
  }
}

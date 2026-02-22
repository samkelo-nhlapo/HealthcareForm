import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { RevenueClaimsSnapshotDto } from '../models/revenue.models';

@Injectable({ providedIn: 'root' })
export class RevenueApiService {
  private readonly apiBaseUrl = '/api/revenue';

  constructor(private readonly http: HttpClient) {}

  getClaimsSnapshot(): Observable<RevenueClaimsSnapshotDto> {
    return this.http.get<RevenueClaimsSnapshotDto>(`${this.apiBaseUrl}/claims`);
  }
}

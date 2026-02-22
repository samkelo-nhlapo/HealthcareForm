import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  AdminAccessControlSnapshotDto,
  AdminAuditLogQueryDto,
  AdminAuditLogSnapshotDto,
  AdminDataGovernanceSnapshotDto
} from '../models/admin.models';

@Injectable({ providedIn: 'root' })
export class AdminApiService {
  private readonly apiBaseUrl = '/api/admin';

  constructor(private readonly http: HttpClient) {}

  getAccessControlSnapshot(): Observable<AdminAccessControlSnapshotDto> {
    return this.http.get<AdminAccessControlSnapshotDto>(`${this.apiBaseUrl}/access-control`);
  }

  getAuditLogSnapshot(query?: AdminAuditLogQueryDto): Observable<AdminAuditLogSnapshotDto> {
    let params = new HttpParams();

    if (query) {
      if (query.actor) {
        params = params.set('actor', query.actor);
      }

      if (query.category) {
        params = params.set('category', query.category);
      }

      if (query.outcome) {
        params = params.set('outcome', query.outcome);
      }

      if (query.fromUtc) {
        params = params.set('fromUtc', query.fromUtc);
      }

      if (query.toUtc) {
        params = params.set('toUtc', query.toUtc);
      }

      if (query.search) {
        params = params.set('search', query.search);
      }

      if (query.privilegedOnly) {
        params = params.set('privilegedOnly', 'true');
      }

      if (query.page) {
        params = params.set('page', query.page.toString());
      }

      if (query.pageSize) {
        params = params.set('pageSize', query.pageSize.toString());
      }
    }

    return this.http.get<AdminAuditLogSnapshotDto>(`${this.apiBaseUrl}/audit-log`, { params });
  }

  getDataGovernanceSnapshot(): Observable<AdminDataGovernanceSnapshotDto> {
    return this.http.get<AdminDataGovernanceSnapshotDto>(`${this.apiBaseUrl}/data-governance`);
  }
}

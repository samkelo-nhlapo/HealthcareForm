import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  ClientCommandResultDto,
  ClientClinicCategoryDto,
  ClientCreateRequestDto,
  ClientDepartmentCommandResultDto,
  ClientDepartmentCreateRequestDto,
  ClientDepartmentQueryDto,
  ClientDepartmentSnapshotDto,
  ClientDepartmentUpdateRequestDto,
  ClientDirectoryQueryDto,
  ClientDirectorySnapshotDto,
  ClientRecordDto,
  ClientStaffDto,
  ClientStaffCommandResultDto,
  ClientStaffCreateRequestDto,
  ClientUpdateRequestDto,
  ClientStaffQueryDto,
  ClientStaffSnapshotDto,
  ClientStaffUpdateRequestDto
} from '../models/clients.models';
import { LookupOptionDto } from '../models/patient.models';

@Injectable({ providedIn: 'root' })
export class ClientsApiService {
  private readonly apiBaseUrl = '/api/clients';

  constructor(private readonly http: HttpClient) {}

  createClient(payload: ClientCreateRequestDto): Observable<ClientCommandResultDto> {
    return this.http.post<ClientCommandResultDto>(this.apiBaseUrl, payload);
  }

  updateClient(clientId: string, payload: ClientUpdateRequestDto): Observable<ClientCommandResultDto> {
    return this.http.put<ClientCommandResultDto>(`${this.apiBaseUrl}/${encodeURIComponent(clientId)}`, payload);
  }

  deleteClient(clientId: string): Observable<ClientCommandResultDto> {
    return this.http.delete<ClientCommandResultDto>(`${this.apiBaseUrl}/${encodeURIComponent(clientId)}`);
  }

  getClinicCategories(): Observable<ClientClinicCategoryDto[]> {
    return this.http.get<ClientClinicCategoryDto[]>(`${this.apiBaseUrl}/clinic-categories`);
  }

  getCities(): Observable<LookupOptionDto[]> {
    return this.http.get<LookupOptionDto[]>('/api/lookups/cities');
  }

  getClients(query: ClientDirectoryQueryDto): Observable<ClientDirectorySnapshotDto> {
    let params = new HttpParams();

    if (query.SearchTerm && query.SearchTerm.trim().length > 0) {
      params = params.set('SearchTerm', query.SearchTerm.trim());
    }

    if (typeof query.ClientClinicCategoryId === 'number' && query.ClientClinicCategoryId > 0) {
      params = params.set('ClientClinicCategoryId', query.ClientClinicCategoryId);
    }

    if (typeof query.IsActive === 'boolean') {
      params = params.set('IsActive', query.IsActive);
    }

    if (typeof query.IsDeleted === 'boolean') {
      params = params.set('IsDeleted', query.IsDeleted);
    }

    if (typeof query.PageNumber === 'number' && query.PageNumber > 0) {
      params = params.set('PageNumber', query.PageNumber);
    }

    if (typeof query.PageSize === 'number' && query.PageSize > 0) {
      params = params.set('PageSize', query.PageSize);
    }

    return this.http.get<ClientDirectorySnapshotDto>(this.apiBaseUrl, { params });
  }

  getClient(clientId: string, includeDeleted = false): Observable<ClientRecordDto> {
    let params = new HttpParams();
    if (includeDeleted) {
      params = params.set('includeDeleted', 'true');
    }

    return this.http.get<ClientRecordDto>(`${this.apiBaseUrl}/${encodeURIComponent(clientId)}`, { params });
  }

  getDepartments(query: ClientDepartmentQueryDto): Observable<ClientDepartmentSnapshotDto> {
    let params = new HttpParams();

    if (query.ClientId) {
      params = params.set('ClientId', query.ClientId);
    }

    if (query.DepartmentType && query.DepartmentType.trim().length > 0) {
      params = params.set('DepartmentType', query.DepartmentType.trim());
    }

    if (query.SearchTerm && query.SearchTerm.trim().length > 0) {
      params = params.set('SearchTerm', query.SearchTerm.trim());
    }

    if (typeof query.IsActive === 'boolean') {
      params = params.set('IsActive', query.IsActive);
    }

    if (typeof query.IsDeleted === 'boolean') {
      params = params.set('IsDeleted', query.IsDeleted);
    }

    if (typeof query.PageNumber === 'number' && query.PageNumber > 0) {
      params = params.set('PageNumber', query.PageNumber);
    }

    if (typeof query.PageSize === 'number' && query.PageSize > 0) {
      params = params.set('PageSize', query.PageSize);
    }

    return this.http.get<ClientDepartmentSnapshotDto>(`${this.apiBaseUrl}/departments`, { params });
  }

  createDepartment(clientId: string, payload: ClientDepartmentCreateRequestDto): Observable<ClientDepartmentCommandResultDto> {
    return this.http.post<ClientDepartmentCommandResultDto>(
      `${this.apiBaseUrl}/${encodeURIComponent(clientId)}/departments`,
      payload
    );
  }

  updateDepartment(
    clientDepartmentId: string,
    payload: ClientDepartmentUpdateRequestDto
  ): Observable<ClientDepartmentCommandResultDto> {
    return this.http.put<ClientDepartmentCommandResultDto>(
      `${this.apiBaseUrl}/departments/${encodeURIComponent(clientDepartmentId)}`,
      payload
    );
  }

  deleteDepartment(clientDepartmentId: string): Observable<ClientDepartmentCommandResultDto> {
    return this.http.delete<ClientDepartmentCommandResultDto>(
      `${this.apiBaseUrl}/departments/${encodeURIComponent(clientDepartmentId)}`
    );
  }

  getStaff(query: ClientStaffQueryDto): Observable<ClientStaffSnapshotDto> {
    let params = new HttpParams();

    if (query.ClientId) {
      params = params.set('ClientId', query.ClientId);
    }

    if (query.SearchTerm && query.SearchTerm.trim().length > 0) {
      params = params.set('SearchTerm', query.SearchTerm.trim());
    }

    if (query.RoleId) {
      params = params.set('RoleId', query.RoleId);
    }

    if (query.StaffType && query.StaffType.trim().length > 0) {
      params = params.set('StaffType', query.StaffType.trim());
    }

    if (typeof query.IsActive === 'boolean') {
      params = params.set('IsActive', query.IsActive);
    }

    if (typeof query.IsDeleted === 'boolean') {
      params = params.set('IsDeleted', query.IsDeleted);
    }

    if (typeof query.PageNumber === 'number' && query.PageNumber > 0) {
      params = params.set('PageNumber', query.PageNumber);
    }

    if (typeof query.PageSize === 'number' && query.PageSize > 0) {
      params = params.set('PageSize', query.PageSize);
    }

    return this.http.get<ClientStaffSnapshotDto>(`${this.apiBaseUrl}/staff`, { params });
  }

  getStaffRecord(clientStaffId: string, includeDeleted = false): Observable<ClientStaffDto> {
    let params = new HttpParams();
    if (includeDeleted) {
      params = params.set('includeDeleted', 'true');
    }

    return this.http.get<ClientStaffDto>(`${this.apiBaseUrl}/staff/${encodeURIComponent(clientStaffId)}`, { params });
  }

  createStaff(clientId: string, payload: ClientStaffCreateRequestDto): Observable<ClientStaffCommandResultDto> {
    return this.http.post<ClientStaffCommandResultDto>(
      `${this.apiBaseUrl}/${encodeURIComponent(clientId)}/staff`,
      payload
    );
  }

  updateStaff(clientStaffId: string, payload: ClientStaffUpdateRequestDto): Observable<ClientStaffCommandResultDto> {
    return this.http.put<ClientStaffCommandResultDto>(
      `${this.apiBaseUrl}/staff/${encodeURIComponent(clientStaffId)}`,
      payload
    );
  }

  deleteStaff(clientStaffId: string): Observable<ClientStaffCommandResultDto> {
    return this.http.delete<ClientStaffCommandResultDto>(`${this.apiBaseUrl}/staff/${encodeURIComponent(clientStaffId)}`);
  }
}

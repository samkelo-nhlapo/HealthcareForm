import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  PatientClientLookupItemDto,
  PatientDirectoryQueryDto,
  PatientDirectorySnapshotDto,
  LookupOptionDto,
  PatientCommandResultDto,
  PatientCreateRequestDto,
  PatientMedicationDto,
  PatientOrdersResultsSnapshotDto,
  PatientLookupResultDto,
  PatientRecordDto,
  PatientWorklistItemDto
} from '../models/patient.models';

@Injectable({ providedIn: 'root' })
export class PatientApiService {
  private readonly apiBaseUrl = '/api';

  constructor(private readonly http: HttpClient) {}

  getGenders(): Observable<LookupOptionDto[]> {
    return this.http.get<LookupOptionDto[]>(`${this.apiBaseUrl}/lookups/genders`);
  }

  getMaritalStatuses(): Observable<LookupOptionDto[]> {
    return this.http.get<LookupOptionDto[]>(`${this.apiBaseUrl}/lookups/marital-statuses`);
  }

  getCountries(): Observable<LookupOptionDto[]> {
    return this.http.get<LookupOptionDto[]>(`${this.apiBaseUrl}/lookups/countries`);
  }

  getProvinces(): Observable<LookupOptionDto[]> {
    return this.http.get<LookupOptionDto[]>(`${this.apiBaseUrl}/lookups/provinces`);
  }

  getCities(): Observable<LookupOptionDto[]> {
    return this.http.get<LookupOptionDto[]>(`${this.apiBaseUrl}/lookups/cities`);
  }

  getClientLookup(): Observable<PatientClientLookupItemDto[]> {
    return this.http.get<PatientClientLookupItemDto[]>(`${this.apiBaseUrl}/patients/client-lookup`);
  }

  getWorklist(): Observable<PatientWorklistItemDto[]> {
    return this.http.get<PatientWorklistItemDto[]>(`${this.apiBaseUrl}/patients/worklist`);
  }

  getDirectory(query: PatientDirectoryQueryDto): Observable<PatientDirectorySnapshotDto> {
    let params = new HttpParams();

    if (query.SearchTerm && query.SearchTerm.trim().length > 0) {
      params = params.set('SearchTerm', query.SearchTerm.trim());
    }

    if (typeof query.GenderId === 'number' && query.GenderId > 0) {
      params = params.set('GenderId', query.GenderId);
    }

    if (typeof query.MaritalStatusId === 'number' && query.MaritalStatusId > 0) {
      params = params.set('MaritalStatusId', query.MaritalStatusId);
    }

    if (query.ClientId && query.ClientId.trim().length > 0) {
      params = params.set('ClientId', query.ClientId.trim());
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

    return this.http.get<PatientDirectorySnapshotDto>(`${this.apiBaseUrl}/patients/directory`, { params });
  }

  createPatient(payload: PatientCreateRequestDto): Observable<PatientCommandResultDto> {
    return this.http.post<PatientCommandResultDto>(`${this.apiBaseUrl}/patients`, payload);
  }

  updatePatient(idNumber: string, payload: Omit<PatientCreateRequestDto, 'IdNumber'>): Observable<PatientCommandResultDto> {
    return this.http.put<PatientCommandResultDto>(
      `${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}`,
      payload
    );
  }

  getPatient(idNumber: string): Observable<PatientRecordDto> {
    return this.http.get<PatientRecordDto>(`${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}`);
  }

  getPatientMedications(idNumber: string): Observable<PatientMedicationDto[]> {
    return this.http.get<PatientMedicationDto[]>(
      `${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}/medications`
    );
  }

  getOrdersResults(idNumber: string): Observable<PatientOrdersResultsSnapshotDto> {
    return this.http.get<PatientOrdersResultsSnapshotDto>(
      `${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}/orders-results`
    );
  }

  deletePatient(idNumber: string): Observable<PatientCommandResultDto> {
    return this.http.delete<PatientCommandResultDto>(`${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}`);
  }

  restorePatient(idNumber: string): Observable<PatientCommandResultDto> {
    return this.http.post<PatientCommandResultDto>(
      `${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}/restore`,
      {}
    );
  }

  // Reserved for phase 2 API work.
  getPatientLookup(idNumber: string): Observable<PatientLookupResultDto> {
    return this.http.get<PatientLookupResultDto>(`${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}`);
  }
}

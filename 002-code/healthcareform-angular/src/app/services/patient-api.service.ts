import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import {
  LookupOptionDto,
  PatientCommandResultDto,
  PatientCreateRequestDto,
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

  getWorklist(): Observable<PatientWorklistItemDto[]> {
    return this.http.get<PatientWorklistItemDto[]>(`${this.apiBaseUrl}/patients/worklist`);
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

  deletePatient(idNumber: string): Observable<PatientCommandResultDto> {
    return this.http.delete<PatientCommandResultDto>(`${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}`);
  }

  // Reserved for phase 2 API work.
  getPatientLookup(idNumber: string): Observable<PatientLookupResultDto> {
    return this.http.get<PatientLookupResultDto>(`${this.apiBaseUrl}/patients/${encodeURIComponent(idNumber)}`);
  }
}

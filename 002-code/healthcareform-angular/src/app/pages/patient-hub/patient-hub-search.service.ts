import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable()
export class PatientHubSearchService {
  private readonly searchTermSubject = new BehaviorSubject<string>('');

  readonly searchTerm$ = this.searchTermSubject.asObservable();

  get searchTerm(): string {
    return this.searchTermSubject.value;
  }

  setSearchTerm(value: string): void {
    const normalizedValue = (value ?? '').trim();
    if (normalizedValue === this.searchTermSubject.value) {
      return;
    }

    this.searchTermSubject.next(normalizedValue);
  }
}

import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { isValidPatientIdNumber, normalizePatientIdNumber } from '../../models/patient-id.utils';

export type PatientHubSelectionSource = 'worklist' | 'directory' | 'registration' | 'manual';

export type PatientHubSelection = {
  idNumber: string;
  patientLabel: string;
  contextLabel: string;
  source: PatientHubSelectionSource;
  isDeleted: boolean;
};

@Injectable()
export class PatientHubSelectionService {
  private readonly selectionSubject = new BehaviorSubject<PatientHubSelection | null>(null);

  readonly selection$ = this.selectionSubject.asObservable();

  get selection(): PatientHubSelection | null {
    return this.selectionSubject.value;
  }

  focusPatient(selection: PatientHubSelection): void {
    const normalizedIdNumber = normalizePatientIdNumber(selection.idNumber);
    const normalizedSelection: PatientHubSelection = {
      idNumber: normalizedIdNumber,
      patientLabel: selection.patientLabel.trim() || normalizedIdNumber,
      contextLabel: selection.contextLabel.trim(),
      source: selection.source,
      isDeleted: selection.isDeleted
    };

    if (!isValidPatientIdNumber(normalizedSelection.idNumber)) {
      return;
    }

    const currentSelection = this.selectionSubject.value;
    if (
      currentSelection
      && currentSelection.idNumber === normalizedSelection.idNumber
      && currentSelection.patientLabel === normalizedSelection.patientLabel
      && currentSelection.contextLabel === normalizedSelection.contextLabel
      && currentSelection.source === normalizedSelection.source
      && currentSelection.isDeleted === normalizedSelection.isDeleted
    ) {
      return;
    }

    this.selectionSubject.next(normalizedSelection);
  }

  clearSelection(): void {
    if (this.selectionSubject.value === null) {
      return;
    }

    this.selectionSubject.next(null);
  }
}

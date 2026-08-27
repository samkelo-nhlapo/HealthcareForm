import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

const PATIENT_ID_NUMBER_PATTERN = /^\d{13}$/;

export function normalizePatientIdNumber(value: string | null | undefined): string {
  return (value ?? '').trim();
}

export function isValidPatientIdNumber(value: string | null | undefined): boolean {
  return PATIENT_ID_NUMBER_PATTERN.test(normalizePatientIdNumber(value));
}

export function patientIdNumberValidator(): ValidatorFn {
  return (control: AbstractControl): ValidationErrors | null => {
    const value = `${control.value ?? ''}`;
    if (value.length === 0) {
      return null;
    }

    return isValidPatientIdNumber(value) ? null : { patientIdNumber: true };
  };
}

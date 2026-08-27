import { CommonModule } from '@angular/common';
import { Component, DestroyRef, OnInit, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { isValidPatientIdNumber, normalizePatientIdNumber } from '../../models/patient-id.utils';
import { PatientDirectoryComponent } from '../patient-directory/patient-directory.component';
import { WorklistComponent } from '../worklist/worklist.component';
import { PatientHubSearchService } from './patient-hub-search.service';
import { PatientHubSelection, PatientHubSelectionService, PatientHubSelectionSource } from './patient-hub-selection.service';

type PatientHubTab = 'worklist' | 'directory';

type PatientHubTabDefinition = {
  key: PatientHubTab;
  label: string;
  eyebrow: string;
  description: string;
};

@Component({
  selector: 'app-patient-hub',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, WorklistComponent, PatientDirectoryComponent],
  providers: [PatientHubSearchService],
  templateUrl: './patient-hub.component.html',
  styleUrl: './patient-hub.component.scss'
})
export class PatientHubComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly destroyRef = inject(DestroyRef);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly patientHubSearch = inject(PatientHubSearchService);
  private readonly patientHubSelection = inject(PatientHubSelectionService);

  readonly tabs: PatientHubTabDefinition[] = [
    {
      key: 'worklist',
      label: 'Worklist',
      eyebrow: 'Operational View',
      description: 'Triage active patients, review risk, and hand off into chart or encounter workflows.'
    },
    {
      key: 'directory',
      label: 'Directory',
      eyebrow: 'Registry View',
      description: 'Search the broader patient registry, review archived records, and restore soft-deleted profiles.'
    }
  ];

  readonly patientSearchForm = this.fb.nonNullable.group({
    query: ['']
  });

  activeTab: PatientHubTab = 'worklist';
  activeIdNumber = '';
  appliedSearchTerm = '';
  contextError = '';
  focusedPatient: PatientHubSelection | null = null;

  ngOnInit(): void {
    this.patientHubSelection.selection$
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((selection) => {
        this.focusedPatient = selection;
        this.activeIdNumber = selection?.idNumber ?? '';
      });

    this.route.queryParamMap.subscribe((params) => {
      const requestedTab = params.get('tab');
      if (requestedTab === 'registration') {
        const normalizedIdNumber = normalizePatientIdNumber(params.get('idNumber'));
        void this.router.navigate(['/patients/registration'], {
          queryParams: {
            idNumber: isValidPatientIdNumber(normalizedIdNumber) ? normalizedIdNumber : null
          },
          replaceUrl: true
        });
        return;
      }

      this.activeTab = this.normalizeTab(requestedTab);
      const routeIdNumber = normalizePatientIdNumber(params.get('idNumber'));
      this.appliedSearchTerm = (params.get('search') ?? '').trim();
      this.patientSearchForm.patchValue({ query: this.appliedSearchTerm }, { emitEvent: false });
      this.patientHubSearch.setSearchTerm(this.appliedSearchTerm);
      if (isValidPatientIdNumber(routeIdNumber)) {
        const currentSelection = this.patientHubSelection.selection;
        this.patientHubSelection.focusPatient({
          idNumber: routeIdNumber,
          patientLabel: currentSelection?.idNumber === routeIdNumber
            ? currentSelection.patientLabel
            : `Patient ${routeIdNumber}`,
          contextLabel: currentSelection?.idNumber === routeIdNumber
            ? currentSelection.contextLabel
            : 'Focused from patient workspace routing.',
          source: currentSelection?.idNumber === routeIdNumber
            ? currentSelection.source
            : 'manual',
          isDeleted: currentSelection?.idNumber === routeIdNumber
            ? currentSelection.isDeleted
            : false
        });
      } else if (!this.patientHubSelection.selection) {
        this.activeIdNumber = '';
      }

      this.contextError = '';
    });
  }

  get activeTabDefinition(): PatientHubTabDefinition {
    return this.tabs.find((tab) => tab.key === this.activeTab) ?? this.tabs[0];
  }

  get hasActivePatientContext(): boolean {
    return isValidPatientIdNumber(this.activeIdNumber);
  }

  get hasSharedSearch(): boolean {
    return this.appliedSearchTerm.length > 0;
  }

  get hasReadySearchId(): boolean {
    return this.readExactSearchId().length > 0;
  }

  switchTab(tab: PatientHubTab): void {
    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { tab },
      queryParamsHandling: 'merge'
    });
  }

  startNewRegistration(): void {
    this.contextError = '';
    this.patientHubSelection.clearSelection();

    void this.router.navigate(['/patients/registration']);
  }

  openRegistrationWorkspace(): void {
    const idNumber = this.resolveActionablePatientId('open registration');
    if (!idNumber) {
      return;
    }

    this.ensureFocusedPatientFromSearch(idNumber, 'Pinned from the patient hub for registration.');

    void this.router.navigate(['/patients/registration'], {
      queryParams: { idNumber }
    });
  }

  openPatientChart(): void {
    const idNumber = this.resolveActionablePatientId('open the chart');
    if (!idNumber) {
      return;
    }

    if (this.isFocusedPatientDeleted(idNumber)) {
      this.contextError = 'Restore this patient before opening chart or encounter workflows.';
      return;
    }

    this.ensureFocusedPatientFromSearch(idNumber, 'Pinned from the patient hub for chart review.');
    void this.router.navigate(['/patients/chart', idNumber]);
  }

  openEncounterWorkspace(): void {
    const idNumber = this.resolveActionablePatientId('open the encounter workspace');
    if (!idNumber) {
      return;
    }

    if (this.isFocusedPatientDeleted(idNumber)) {
      this.contextError = 'Restore this patient before opening chart or encounter workflows.';
      return;
    }

    this.ensureFocusedPatientFromSearch(idNumber, 'Pinned from the patient hub for encounter work.');
    void this.router.navigate(['/clinical/encounter'], {
      queryParams: { idNumber }
    });
  }

  clearFocusedPatient(): void {
    this.contextError = '';
    this.patientHubSelection.clearSelection();

    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { idNumber: null },
      queryParamsHandling: 'merge'
    });
  }

  applyPatientSearch(): void {
    this.contextError = '';
    const searchTerm = this.readSearchQuery();
    const exactSearchId = this.readExactSearchId(searchTerm);
    if (exactSearchId.length > 0) {
      this.ensureFocusedPatientFromSearch(exactSearchId, 'Pinned from the shared patient search.');
    }

    const queryParams: { search: string | null; idNumber?: string } = {
      search: searchTerm || null
    };
    if (exactSearchId.length > 0) {
      queryParams.idNumber = exactSearchId;
    }

    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams,
      queryParamsHandling: 'merge'
    });
  }

  focusPatientFromSearch(): void {
    const exactSearchId = this.readExactSearchId();
    if (exactSearchId.length === 0) {
      const query = this.readSearchQuery();
      this.contextError = query.length > 0
        ? 'Enter a full 13-digit patient ID number to focus one patient from the search bar.'
        : 'Enter a patient name, contact detail, or 13-digit ID number to begin searching.';
      return;
    }

    this.ensureFocusedPatientFromSearch(exactSearchId, 'Pinned from the shared patient search.');

    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: {
        search: this.readSearchQuery() || exactSearchId,
        idNumber: exactSearchId
      },
      queryParamsHandling: 'merge'
    });
  }

  clearPatientSearch(): void {
    this.contextError = '';
    this.patientSearchForm.reset({ query: '' });

    void this.router.navigate([], {
      relativeTo: this.route,
      queryParams: { search: null },
      queryParamsHandling: 'merge'
    });
  }

  private normalizeTab(value: string | null): PatientHubTab {
    if (value === 'directory') {
      return value;
    }

    return 'worklist';
  }

  private resolveActionablePatientId(action: string): string {
    if (this.hasActivePatientContext) {
      this.contextError = '';
      return this.activeIdNumber;
    }

    const exactSearchId = this.readExactSearchId();
    if (exactSearchId.length > 0) {
      this.contextError = '';
      return exactSearchId;
    }

    const query = this.readSearchQuery();
    this.contextError = query.length > 0
      ? `Enter a full 13-digit patient ID number to ${action}, or focus a patient from the results first.`
      : `Search for a patient, or focus one from the results, before trying to ${action}.`;
    return '';
  }

  describeSelectionSource(source: PatientHubSelectionSource): string {
    if (source === 'directory') {
      return 'Focused from the patient directory';
    }

    if (source === 'registration') {
      return 'Focused from registration';
    }

    if (source === 'manual') {
      return 'Focused from the hub context controls';
    }

    return 'Focused from the worklist';
  }

  private syncFocusedPatientContext(
    idNumber: string,
    patientLabel: string,
    contextLabel: string,
    source: PatientHubSelectionSource,
    isDeleted: boolean
  ): void {
    this.contextError = '';
    this.patientHubSelection.focusPatient({
      idNumber,
      patientLabel,
      contextLabel,
      source,
      isDeleted
    });
  }

  private readSearchQuery(): string {
    return (this.patientSearchForm.getRawValue().query ?? '').trim();
  }

  private readExactSearchId(query = this.readSearchQuery()): string {
    const normalizedQuery = normalizePatientIdNumber(query);
    return isValidPatientIdNumber(normalizedQuery) ? normalizedQuery : '';
  }

  private ensureFocusedPatientFromSearch(idNumber: string, fallbackContextLabel: string): void {
    if (this.focusedPatient?.idNumber === idNumber) {
      this.contextError = '';
      return;
    }

    this.syncFocusedPatientContext(
      idNumber,
      `Patient ${idNumber}`,
      fallbackContextLabel,
      'manual',
      false
    );
  }

  private isFocusedPatientDeleted(idNumber: string): boolean {
    return this.focusedPatient?.idNumber === idNumber && this.focusedPatient.isDeleted;
  }
}

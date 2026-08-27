import { Component } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ActivatedRoute, Router, convertToParamMap } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { PatientDirectoryComponent } from '../patient-directory/patient-directory.component';
import { WorklistComponent } from '../worklist/worklist.component';
import { PatientHubComponent } from './patient-hub.component';
import { PatientHubSearchService } from './patient-hub-search.service';
import { PatientHubSelectionService } from './patient-hub-selection.service';

@Component({
  selector: 'app-worklist',
  standalone: true,
  template: '<div>worklist stub</div>'
})
class WorklistStubComponent {}

@Component({
  selector: 'app-patient-directory',
  standalone: true,
  template: '<div>directory stub</div>'
})
class PatientDirectoryStubComponent {}

describe('PatientHubComponent', () => {
  let fixture: ComponentFixture<PatientHubComponent>;
  let component: PatientHubComponent;
  let router: jasmine.SpyObj<Router>;
  let routeParams$: BehaviorSubject<ReturnType<typeof convertToParamMap>>;
  let patientHubSearch: PatientHubSearchService;
  let patientHubSelection: PatientHubSelectionService;

  beforeEach(async () => {
    routeParams$ = new BehaviorSubject(convertToParamMap({}));
    router = jasmine.createSpyObj<Router>('Router', ['navigate']);
    router.navigate.and.resolveTo(true);

    await TestBed.configureTestingModule({
      imports: [PatientHubComponent],
      providers: [
        PatientHubSelectionService,
        { provide: Router, useValue: router },
        {
          provide: ActivatedRoute,
          useValue: {
            queryParamMap: routeParams$.asObservable(),
            snapshot: {
              queryParamMap: convertToParamMap({})
            }
          }
        }
      ]
    })
      .overrideComponent(PatientHubComponent, {
        remove: {
          imports: [WorklistComponent, PatientDirectoryComponent]
        },
        add: {
          imports: [WorklistStubComponent, PatientDirectoryStubComponent]
        }
      })
      .compileComponents();

    fixture = TestBed.createComponent(PatientHubComponent);
    component = fixture.componentInstance;
    patientHubSearch = fixture.debugElement.injector.get(PatientHubSearchService);
    patientHubSelection = TestBed.inject(PatientHubSelectionService);
    fixture.detectChanges();
  });

  it('syncs route search params into the unified search form and shared search service', () => {
    routeParams$.next(convertToParamMap({
      tab: 'directory',
      search: 'Jane Doe'
    }));
    fixture.detectChanges();

    expect(component.activeTab).toBe('directory');
    expect(component.patientSearchForm.getRawValue().query).toBe('Jane Doe');
    expect(patientHubSearch.searchTerm).toBe('Jane Doe');
  });

  it('pins an exact 13-digit search from the unified search flow', () => {
    component.patientSearchForm.patchValue({ query: '1234567890123' });

    component.applyPatientSearch();

    expect(patientHubSelection.selection).toEqual(jasmine.objectContaining({
      idNumber: '1234567890123',
      patientLabel: 'Patient 1234567890123',
      source: 'manual',
      isDeleted: false
    }));
    expect(router.navigate).toHaveBeenCalledWith([], jasmine.objectContaining({
      queryParams: {
        search: '1234567890123',
        idNumber: '1234567890123'
      },
      queryParamsHandling: 'merge'
    }));
  });

  it('uses the focused patient as the action target instead of a different typed search id', () => {
    patientHubSelection.focusPatient({
      idNumber: '1111111111111',
      patientLabel: 'Focused Patient',
      contextLabel: 'Focused from the worklist',
      source: 'worklist',
      isDeleted: false
    });
    fixture.detectChanges();

    component.patientSearchForm.patchValue({ query: '9999999999999' });

    component.openPatientChart();

    expect(router.navigate).toHaveBeenCalledWith(['/patients/chart', '1111111111111']);
  });

  it('shows one patient-search command field in the hub UI', () => {
    const element = fixture.nativeElement as HTMLElement;

    expect(element.querySelectorAll('input[formControlName="query"]').length).toBe(1);
    expect(element.textContent).toContain('One patient search');
    expect(element.textContent).not.toContain('Focused Patient ID');
  });
});

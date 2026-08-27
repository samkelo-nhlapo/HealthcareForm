import { convertToParamMap, ActivatedRoute } from '@angular/router';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';
import { PatientWorkbenchComponent } from './patient-workbench.component';
import { PatientApiService } from '../../services/patient-api.service';
import { LookupOptionDto, PatientClientLookupItemDto } from '../../models/patient.models';

describe('PatientWorkbenchComponent', () => {
  let fixture: ComponentFixture<PatientWorkbenchComponent>;
  let component: PatientWorkbenchComponent;

  const clients: PatientClientLookupItemDto[] = [
    {
      ClientId: 'client-primary',
      ClientCode: 'CLI-001',
      ClientName: 'Alpha Clinic',
      ClientClinicCategoryName: 'Clinic'
    },
    {
      ClientId: 'client-secondary',
      ClientCode: 'HSP-002',
      ClientName: 'Beta Hospital',
      ClientClinicCategoryName: 'Hospital'
    },
    {
      ClientId: 'client-third',
      ClientCode: 'CLI-003',
      ClientName: 'Gamma Care Centre',
      ClientClinicCategoryName: 'Clinic'
    }
  ];

  const genders: LookupOptionDto[] = [
    { Id: 1, Name: 'Female' },
    { Id: 2, Name: 'Male' }
  ];

  const maritalStatuses: LookupOptionDto[] = [
    { Id: 1, Name: 'Single' },
    { Id: 2, Name: 'Married' }
  ];

  const countries: LookupOptionDto[] = [
    { Id: 1, Name: 'South Africa' }
  ];

  const provinces: LookupOptionDto[] = [
    { Id: 1, Name: 'Gauteng' }
  ];

  const cities: LookupOptionDto[] = [
    { Id: 1, Name: 'Johannesburg' }
  ];

  const patientApiStub: Partial<PatientApiService> = {
    getClientLookup: () => of(clients),
    getGenders: () => of(genders),
    getMaritalStatuses: () => of(maritalStatuses),
    getCountries: () => of(countries),
    getProvinces: () => of(provinces),
    getCities: () => of(cities),
    createPatient: jasmine.createSpy('createPatient'),
    updatePatient: jasmine.createSpy('updatePatient'),
    getPatient: jasmine.createSpy('getPatient'),
    deletePatient: jasmine.createSpy('deletePatient'),
    restorePatient: jasmine.createSpy('restorePatient')
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [PatientWorkbenchComponent],
      providers: [
        { provide: PatientApiService, useValue: patientApiStub },
        {
          provide: ActivatedRoute,
          useValue: {
            queryParamMap: of(convertToParamMap({}))
          }
        }
      ]
    }).compileComponents();

    fixture = TestBed.createComponent(PatientWorkbenchComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();

    (patientApiStub.createPatient as jasmine.Spy).calls.reset();
    (patientApiStub.updatePatient as jasmine.Spy).calls.reset();
    (patientApiStub.getPatient as jasmine.Spy).calls.reset();
    (patientApiStub.deletePatient as jasmine.Spy).calls.reset();
    (patientApiStub.restorePatient as jasmine.Spy).calls.reset();
  });

  it('loads dropdown options for patient registration on init', () => {
    expect(component.clients).toEqual(clients);
    expect(component.genders).toEqual(genders);
    expect(component.maritalStatuses).toEqual(maritalStatuses);
    expect(component.countries).toEqual(countries);
    expect(component.provinces).toEqual(provinces);
    expect(component.cities).toEqual(cities);

    const element = fixture.nativeElement as HTMLElement;
    const selects = element.querySelectorAll('select');
    expect(selects.length).toBe(2);

    const genderSelect = element.querySelector('select[formControlName="GenderId"]');
    const maritalStatusSelect = element.querySelector('select[formControlName="MaritalStatusId"]');

    expect(genderSelect?.querySelectorAll('option').length).toBe(genders.length + 1);
    expect(maritalStatusSelect?.querySelectorAll('option').length).toBe(maritalStatuses.length + 1);

    component.togglePrimaryClientDropdown();
    fixture.detectChanges();

    const primaryOptions = element.querySelectorAll('.option-button');
    expect(primaryOptions.length).toBe(clients.length);
  });

  it('keeps the selected primary client out of additional client selections', () => {
    component.patientForm.patchValue({
      PrimaryClientId: 'client-primary',
      SecondaryClientIds: ['client-primary', 'client-secondary']
    });

    component.onPrimaryClientChange('client-primary');
    fixture.detectChanges();

    expect(component.patientForm.controls.SecondaryClientIds.value).toEqual(['client-secondary']);
    expect(component.availableAdditionalClients.map((client) => client.ClientId)).toEqual([
      'client-secondary',
      'client-third'
    ]);

    component.toggleAdditionalClientsDropdown();
    fixture.detectChanges();

    const checkboxLabels = Array.from(
      (fixture.nativeElement as HTMLElement).querySelectorAll('.checkbox-option span')
    ).map((node) => node.textContent?.trim());
    expect(checkboxLabels).not.toContain('Alpha Clinic (CLI-001 / Clinic)');
  });

  it('updates additional client selections from the checkbox list without duplicates', () => {
    component.patientForm.patchValue({
      PrimaryClientId: 'client-primary',
      SecondaryClientIds: []
    });
    component.toggleAdditionalClientsDropdown();
    fixture.detectChanges();

    const checkboxes = (fixture.nativeElement as HTMLElement).querySelectorAll<HTMLInputElement>(
      '.checkbox-option input[type="checkbox"]'
    );

    const secondaryCheckbox = checkboxes[0];
    expect(secondaryCheckbox).toBeTruthy();

    secondaryCheckbox.checked = true;
    secondaryCheckbox.dispatchEvent(new Event('change'));
    fixture.detectChanges();

    expect(component.patientForm.controls.SecondaryClientIds.value).toEqual(['client-secondary']);

    secondaryCheckbox.checked = true;
    secondaryCheckbox.dispatchEvent(new Event('change'));
    fixture.detectChanges();

    expect(component.patientForm.controls.SecondaryClientIds.value).toEqual(['client-secondary']);

    secondaryCheckbox.checked = false;
    secondaryCheckbox.dispatchEvent(new Event('change'));
    fixture.detectChanges();

    expect(component.patientForm.controls.SecondaryClientIds.value).toEqual([]);
  });

  it('filters primary clinic options from the search field', () => {
    component.togglePrimaryClientDropdown();
    component.setPrimaryClientSearchTerm('beta');
    fixture.detectChanges();

    const optionLabels = Array.from(
      (fixture.nativeElement as HTMLElement).querySelectorAll('.option-button span')
    ).map((node) => node.textContent?.trim());

    expect(optionLabels).toEqual(['Beta Hospital']);
  });

  it('filters additional clinic options from the search field', () => {
    component.patientForm.patchValue({
      PrimaryClientId: 'client-primary'
    });
    component.toggleAdditionalClientsDropdown();
    component.setAdditionalClientsSearchTerm('gamma');
    fixture.detectChanges();

    const checkboxLabels = Array.from(
      (fixture.nativeElement as HTMLElement).querySelectorAll('.checkbox-option span')
    ).map((node) => node.textContent?.trim());

    expect(checkboxLabels).toEqual(['Gamma Care Centre (CLI-003 / Clinic)']);
  });

  it('rejects non-digit 13-character patient IDs during search', () => {
    const getPatientSpy = patientApiStub.getPatient as jasmine.Spy;
    component.searchForm.patchValue({ idNumber: '123456789012a' });

    component.getPatient();

    expect(getPatientSpy).not.toHaveBeenCalled();
    expect(component.searchForm.controls.idNumber.invalid).toBeTrue();
    expect(component.statusMessage).toBe('Enter a valid 13-digit ID number to search.');
  });

  it('trims demographic payload strings before create calls', () => {
    const createPatientSpy = patientApiStub.createPatient as jasmine.Spy;
    createPatientSpy.and.returnValue(of({
      Success: false,
      Message: 'Duplicate patient.',
      StatusCode: 2,
      PatientId: null
    }));

    component.patientForm.patchValue({
      PrimaryClientId: ' client-primary ',
      SecondaryClientIds: [' client-secondary ', 'client-secondary', ' client-primary '],
      FirstName: '  Sam  ',
      LastName: '  Patient  ',
      IdNumber: ' 1234567890123 ',
      DateOfBirth: ' 1990-01-01 ',
      GenderId: 1,
      PhoneNumber: ' 0123456789 ',
      Email: ' sam@example.com ',
      Line1: ' 1 Integration Street ',
      Line2: ' Suite 2 ',
      CityId: 1,
      ProvinceId: 1,
      CountryId: 1,
      MaritalStatusId: 1,
      EmergencyName: ' Casey ',
      EmergencyLastName: ' Contact ',
      EmergencyPhoneNumber: ' 0987654321 ',
      Relationship: ' Sibling ',
      EmergencyDateOfBirth: ' 1988-01-01 ',
      MedicationList: ' Vitamin D '
    });

    component.createPatient();

    expect(createPatientSpy).toHaveBeenCalledOnceWith({
      PrimaryClientId: 'client-primary',
      SecondaryClientIds: ['client-secondary'],
      FirstName: 'Sam',
      LastName: 'Patient',
      IdNumber: '1234567890123',
      DateOfBirth: '1990-01-01',
      GenderId: 1,
      PhoneNumber: '0123456789',
      Email: 'sam@example.com',
      Line1: '1 Integration Street',
      Line2: 'Suite 2',
      CityId: 1,
      ProvinceId: 1,
      CountryId: 1,
      MaritalStatusId: 1,
      EmergencyName: 'Casey',
      EmergencyLastName: 'Contact',
      EmergencyPhoneNumber: '0987654321',
      Relationship: 'Sibling',
      EmergencyDateOfBirth: '1988-01-01',
      MedicationList: 'Vitamin D'
    });
  });
});

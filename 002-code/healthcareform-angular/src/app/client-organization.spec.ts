import {
  buildOrganizationName,
  buildOrganizationProfile,
  categoryMatchesOrganizationType,
  getOrganizationContent,
  inferOrganizationType,
  readOrganizationSecondaryName
} from './client-organization';

describe('client-organization helpers', () => {
  it('infers hospitals from category names', () => {
    expect(inferOrganizationType({ categoryName: 'Large Public Hospital' })).toBe('HOSPITAL');
  });

  it('falls back to clinics when no explicit type exists', () => {
    expect(inferOrganizationType({ primaryName: 'West End Medical Centre' })).toBe('CLINIC');
  });

  it('deduplicates the secondary name when the legacy fields match', () => {
    expect(readOrganizationSecondaryName('City Hospital', 'City Hospital')).toBe('');
    expect(buildOrganizationName('City Hospital', 'City Hospital')).toBe('City Hospital');
  });

  it('describes the organisation profile from size and ownership', () => {
    expect(buildOrganizationProfile('Large', 'Public')).toBe('Large footprint / Public ownership');
  });

  it('matches categories to the selected organisation type', () => {
    expect(categoryMatchesOrganizationType({ CategoryName: 'Medium Private Hospital' }, 'HOSPITAL')).toBeTrue();
    expect(categoryMatchesOrganizationType({ CategoryName: 'Small Public Clinic' }, 'HOSPITAL')).toBeFalse();
  });

  it('returns type-specific copy for the client pages', () => {
    expect(getOrganizationContent('HOSPITAL').phoneLabel).toBe('Main Switchboard');
    expect(getOrganizationContent('CLINIC').secondaryNameLabel).toBe('Practice / Branch Name');
  });
});

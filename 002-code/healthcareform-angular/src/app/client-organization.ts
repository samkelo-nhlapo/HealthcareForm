import { ClientClinicCategoryDto } from './models/clients.models';

export type OrganizationType = 'CLINIC' | 'HOSPITAL';

export interface OrganizationContent {
  singular: string;
  singularLower: string;
  plural: string;
  secondaryNameLabel: string;
  secondaryNamePlaceholder: string;
  registrationLabel: string;
  establishedLabel: string;
  phoneLabel: string;
  intakeSummary: string;
}

const ORGANIZATION_CONTENT: Record<OrganizationType, OrganizationContent> = {
  CLINIC: {
    singular: 'Clinic',
    singularLower: 'clinic',
    plural: 'Clinics',
    secondaryNameLabel: 'Practice / Branch Name',
    secondaryNamePlaceholder: 'Optional branch, practice, or network name',
    registrationLabel: 'Practice Number / Licence Number',
    establishedLabel: 'Opened / Established Date',
    phoneLabel: 'Reception Number',
    intakeSummary:
      'Capture the clinic organisation details patients, staff, and billing teams will recognise when this record is used across the platform.'
  },
  HOSPITAL: {
    singular: 'Hospital',
    singularLower: 'hospital',
    plural: 'Hospitals',
    secondaryNameLabel: 'Campus / Group Name',
    secondaryNamePlaceholder: 'Optional campus, unit, or hospital-group name',
    registrationLabel: 'Hospital Licence / Registration Number',
    establishedLabel: 'Commissioned / Established Date',
    phoneLabel: 'Main Switchboard',
    intakeSummary:
      'Capture the hospital organisation details patients, staff, and operational teams will recognise when this record is used across the platform.'
  }
};

export function getOrganizationContent(type: OrganizationType): OrganizationContent {
  return ORGANIZATION_CONTENT[type];
}

export function inferOrganizationType(input: {
  categoryName?: string | null;
  primaryName?: string | null;
  secondaryName?: string | null;
  fallback?: OrganizationType;
}): OrganizationType {
  const source = [
    normalizeText(input.categoryName),
    normalizeText(input.primaryName),
    normalizeText(input.secondaryName)
  ]
    .filter((value) => value.length > 0)
    .join(' ')
    .toLowerCase();

  if (source.includes('hospital')) {
    return 'HOSPITAL';
  }

  if (source.includes('clinic')) {
    return 'CLINIC';
  }

  return input.fallback ?? 'CLINIC';
}

export function buildOrganizationName(
  primaryName: string | null | undefined,
  secondaryName: string | null | undefined,
  fallback = 'Unnamed organisation'
): string {
  const primary = normalizeText(primaryName);
  const secondary = readOrganizationSecondaryName(primaryName, secondaryName);
  const parts = [primary, secondary].filter((value) => value.length > 0);
  return parts.length > 0 ? parts.join(' ') : fallback;
}

export function readOrganizationSecondaryName(
  primaryName: string | null | undefined,
  secondaryName: string | null | undefined
): string {
  const primary = normalizeText(primaryName).toLowerCase();
  const secondary = normalizeText(secondaryName);

  if (secondary.length === 0) {
    return '';
  }

  if (primary.length > 0 && secondary.toLowerCase() === primary) {
    return '';
  }

  return secondary;
}

export function buildOrganizationProfile(
  scale: string | null | undefined,
  ownership: string | null | undefined
): string {
  const parts: string[] = [];
  const normalizedScale = normalizeText(scale);
  const normalizedOwnership = normalizeText(ownership);

  if (normalizedScale.length > 0) {
    parts.push(`${normalizedScale} footprint`);
  }

  if (normalizedOwnership.length > 0) {
    parts.push(`${normalizedOwnership} ownership`);
  }

  return parts.length > 0 ? parts.join(' / ') : 'Profile not set';
}

export function categoryMatchesOrganizationType(
  category: Pick<ClientClinicCategoryDto, 'CategoryName'>,
  type: OrganizationType
): boolean {
  return inferOrganizationType({
    categoryName: category.CategoryName,
    fallback: type
  }) === type;
}

export function describeCategoryOption(category: ClientClinicCategoryDto): string {
  const profile = buildOrganizationProfile(category.ClinicSize, category.OwnershipType);
  return profile === 'Profile not set'
    ? category.CategoryName
    : `${category.CategoryName} (${profile})`;
}

function normalizeText(value: string | null | undefined): string {
  if (typeof value !== 'string') {
    return '';
  }

  const normalized = value.trim();
  return normalized.length > 0 ? normalized : '';
}

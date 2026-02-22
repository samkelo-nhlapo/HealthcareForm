export interface RevenueClaimRowDto {
  ClaimId: string;
  Patient: string;
  IdNumber: string;
  Payer: string;
  ServiceDate: string;
  Amount: number;
  PaidAmount: number;
  CodingStatus: string;
  ClaimStatus: string;
  DenialReason: string;
  DaysOpen: number;
  LastUpdated: string;
}

export interface RevenueClaimsSnapshotDto {
  Claims: RevenueClaimRowDto[];
}

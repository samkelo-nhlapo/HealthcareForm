export interface LoginRequestDto {
  UsernameOrEmail: string;
  Password: string;
}

export interface AuthUserDto {
  UserId: string;
  Username: string;
  Email: string;
  FirstName: string;
  LastName: string;
  IsSuperAdmin: boolean;
  Roles: string[];
}

export interface AuthTokenResponseDto {
  TokenType: string;
  AccessToken: string;
  ExpiresAtUtc: string;
  User: AuthUserDto;
}

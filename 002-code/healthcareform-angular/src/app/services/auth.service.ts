import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { AuthTokenResponseDto, AuthUserDto, LoginRequestDto } from '../models/auth.models';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly storageKey = 'healthcareform.auth.session';
  private session: AuthTokenResponseDto | null;

  constructor(
    private readonly http: HttpClient,
    private readonly router: Router
  ) {
    this.session = this.readSession();
  }

  login(payload: LoginRequestDto): Observable<AuthTokenResponseDto> {
    return this.http.post<AuthTokenResponseDto>('/api/auth/login', payload).pipe(
      tap((response) => {
        this.session = response;
        localStorage.setItem(this.storageKey, JSON.stringify(response));
      })
    );
  }

  logout(redirect = true): void {
    this.session = null;
    localStorage.removeItem(this.storageKey);

    if (redirect) {
      void this.router.navigate(['/login']);
    }
  }

  isAuthenticated(): boolean {
    return this.getAccessToken() !== null;
  }

  getAccessToken(): string | null {
    const activeSession = this.session ?? this.readSession();
    if (!activeSession) {
      return null;
    }

    if (this.isExpired(activeSession.ExpiresAtUtc)) {
      this.logout(false);
      return null;
    }

    this.session = activeSession;
    return activeSession.AccessToken;
  }

  getCurrentUsername(): string {
    return this.session?.User.Username ?? this.readSession()?.User.Username ?? '';
  }

  getCurrentUser(): AuthUserDto | null {
    const activeSession = this.session ?? this.readSession();
    return activeSession?.User ?? null;
  }

  getCurrentRoles(): string[] {
    return this.getCurrentUser()?.Roles ?? [];
  }

  private readSession(): AuthTokenResponseDto | null {
    const raw = localStorage.getItem(this.storageKey);
    if (!raw) {
      return null;
    }

    try {
      const parsed = JSON.parse(raw) as AuthTokenResponseDto;
      if (!parsed?.AccessToken || !parsed?.ExpiresAtUtc) {
        return null;
      }

      return parsed;
    } catch {
      return null;
    }
  }

  private isExpired(expiresAtUtc: string): boolean {
    const expiresMs = Date.parse(expiresAtUtc);
    if (Number.isNaN(expiresMs)) {
      return true;
    }

    return expiresMs <= Date.now();
  }
}

import { inject } from '@angular/core';
import { CanActivateFn, ActivatedRouteSnapshot, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

function normalizeRoles(values: readonly string[]): Set<string> {
  return new Set(values.map((value) => value.trim().toUpperCase()).filter((value) => value.length > 0));
}

function requiredRolesFrom(route: ActivatedRouteSnapshot): string[] {
  const dataRoles = route.data['roles'];
  if (!Array.isArray(dataRoles)) {
    return [];
  }

  return dataRoles.filter((role): role is string => typeof role === 'string');
}

export const roleGuard: CanActivateFn = (route) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const requiredRoles = requiredRolesFrom(route);
  if (requiredRoles.length === 0) {
    return true;
  }

  const currentRoles = normalizeRoles(authService.getCurrentRoles());
  const isAuthorized = requiredRoles.some((role) => currentRoles.has(role.toUpperCase()));

  if (isAuthorized) {
    return true;
  }

  return router.createUrlTree(['/unauthorized']);
};

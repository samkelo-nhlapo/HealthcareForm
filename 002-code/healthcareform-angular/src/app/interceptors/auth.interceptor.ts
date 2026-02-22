import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const authInterceptor: HttpInterceptorFn = (request, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const isApiRequest = request.url.startsWith('/api');
  const isLoginRequest = request.url.startsWith('/api/auth/login');

  const token = authService.getAccessToken();
  const authorizedRequest = isApiRequest && !isLoginRequest && token
    ? request.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      })
    : request;

  return next(authorizedRequest).pipe(
    catchError((error: HttpErrorResponse) => {
      if (isApiRequest && error.status === 401 && !isLoginRequest) {
        authService.logout(false);
        void router.navigate(['/login']);
      }

      return throwError(() => error);
    })
  );
};

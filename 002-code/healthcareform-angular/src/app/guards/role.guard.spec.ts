import { TestBed } from '@angular/core/testing';
import { ActivatedRouteSnapshot, Router, RouterStateSnapshot, UrlTree } from '@angular/router';
import { roleGuard } from './role.guard';
import { AuthService } from '../services/auth.service';

describe('roleGuard', () => {
  const unauthorizedTree = {} as UrlTree;

  let authServiceMock: jasmine.SpyObj<Pick<AuthService, 'getCurrentRoles'>>;
  let routerMock: jasmine.SpyObj<Pick<Router, 'createUrlTree'>>;

  beforeEach(() => {
    authServiceMock = jasmine.createSpyObj('AuthService', ['getCurrentRoles']);
    routerMock = jasmine.createSpyObj('Router', ['createUrlTree']);
    routerMock.createUrlTree.and.returnValue(unauthorizedTree);

    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useValue: authServiceMock },
        { provide: Router, useValue: routerMock }
      ]
    });
  });

  it('allows access when no roles are required', () => {
    authServiceMock.getCurrentRoles.and.returnValue([]);
    const route = { data: {} } as ActivatedRouteSnapshot;

    const result = TestBed.runInInjectionContext(() => roleGuard(route, {} as RouterStateSnapshot));

    expect(result).toBeTrue();
    expect(routerMock.createUrlTree).not.toHaveBeenCalled();
  });

  it('allows access when user has one required role', () => {
    authServiceMock.getCurrentRoles.and.returnValue(['NURSE', 'BILLING']);
    const route = { data: { roles: ['ADMIN', 'BILLING'] } } as ActivatedRouteSnapshot;

    const result = TestBed.runInInjectionContext(() => roleGuard(route, {} as RouterStateSnapshot));

    expect(result).toBeTrue();
    expect(routerMock.createUrlTree).not.toHaveBeenCalled();
  });

  it('redirects to unauthorized when user lacks required roles', () => {
    authServiceMock.getCurrentRoles.and.returnValue(['DOCTOR']);
    const route = { data: { roles: ['ADMIN', 'BILLING'] } } as ActivatedRouteSnapshot;

    const result = TestBed.runInInjectionContext(() => roleGuard(route, {} as RouterStateSnapshot));

    expect(result).toBe(unauthorizedTree);
    expect(routerMock.createUrlTree).toHaveBeenCalledWith(['/unauthorized']);
  });
});

import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';
import { roleGuard } from './guards/role.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./components/login/login.component').then((m) => m.LoginComponent)
  },
  {
    path: 'unauthorized',
    loadComponent: () => import('./pages/unauthorized/unauthorized.component').then((m) => m.UnauthorizedComponent)
  },
  {
    path: '',
    loadComponent: () => import('./layout/clinical-shell/clinical-shell.component').then((m) => m.ClinicalShellComponent),
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () => import('./pages/dashboard/dashboard.component').then((m) => m.DashboardComponent)
      },
      {
        path: 'patients/hub',
        loadComponent: () => import('./pages/patient-hub/patient-hub.component').then((m) => m.PatientHubComponent)
      },
      {
        path: 'patients/registration',
        loadComponent: () => import('./components/patient-workbench/patient-workbench.component').then((m) => m.PatientWorkbenchComponent)
      },
      {
        path: 'patients/worklist',
        loadComponent: () => import('./pages/patient-hub-redirect/patient-hub-redirect.component').then((m) => m.PatientHubRedirectComponent),
        data: { tab: 'worklist' }
      },
      {
        path: 'patients/directory',
        loadComponent: () => import('./pages/patient-hub-redirect/patient-hub-redirect.component').then((m) => m.PatientHubRedirectComponent),
        data: { tab: 'directory' }
      },
      {
        path: 'patients/chart/:idNumber',
        loadComponent: () => import('./pages/patient-chart/patient-chart.component').then((m) => m.PatientChartComponent)
      },
      {
        path: 'patients/workbench',
        loadComponent: () => import('./pages/patient-hub-redirect/patient-hub-redirect.component').then((m) => m.PatientHubRedirectComponent),
        data: { destination: 'registration' }
      },
      {
        path: 'clinical/encounter',
        loadComponent: () => import('./pages/encounter-workspace/encounter-workspace.component').then((m) => m.EncounterWorkspaceComponent)
      },
      {
        path: 'clinical/orders-results',
        loadComponent: () => import('./pages/orders-results/orders-results.component').then((m) => m.OrdersResultsComponent)
      },
      {
        path: 'clinical/medication-reconciliation',
        loadComponent: () => import('./pages/medication-reconciliation/medication-reconciliation.component').then((m) => m.MedicationReconciliationComponent)
      },
      {
        path: 'scheduling',
        loadComponent: () => import('./pages/scheduling/scheduling.component').then((m) => m.SchedulingComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN', 'DOCTOR', 'NURSE', 'BILLING', 'PHARMACIST'] }
      },
      {
        path: 'operations/task-queue',
        loadComponent: () => import('./pages/task-queue/task-queue.component').then((m) => m.TaskQueueComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN', 'DOCTOR', 'NURSE', 'PHARMACIST', 'BILLING'] }
      },
      {
        path: 'revenue/billing-claims',
        loadComponent: () => import('./pages/billing-claims/billing-claims.component').then((m) => m.BillingClaimsComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN', 'BILLING'] }
      },
      {
        path: 'messages',
        loadComponent: () => import('./pages/messages/messages.component').then((m) => m.MessagesComponent)
      },
      {
        path: 'admin',
        loadComponent: () => import('./pages/admin/admin.component').then((m) => m.AdminComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/clients',
        loadComponent: () => import('./pages/client-directory/client-directory.component').then((m) => m.ClientDirectoryComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/clients/new',
        loadComponent: () => import('./pages/client-create/client-create.component').then((m) => m.ClientCreateComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/clients/:clientId/edit',
        loadComponent: () => import('./pages/client-edit/client-edit.component').then((m) => m.ClientEditComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/clients/:clientId',
        loadComponent: () => import('./pages/client-detail/client-detail.component').then((m) => m.ClientDetailComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/access-control',
        loadComponent: () => import('./pages/admin-access-control/admin-access-control.component').then((m) => m.AdminAccessControlComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/audit-log',
        loadComponent: () => import('./pages/admin-audit-log/admin-audit-log.component').then((m) => m.AdminAuditLogComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/data-governance',
        loadComponent: () => import('./pages/admin-data-governance/admin-data-governance.component').then((m) => m.AdminDataGovernanceComponent),
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      }
    ]
  },
  { path: '**', redirectTo: '' }
];

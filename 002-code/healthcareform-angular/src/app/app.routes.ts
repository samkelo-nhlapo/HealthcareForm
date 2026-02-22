import { Routes } from '@angular/router';
import { PatientWorkbenchComponent } from './components/patient-workbench/patient-workbench.component';
import { LoginComponent } from './components/login/login.component';
import { authGuard } from './guards/auth.guard';
import { roleGuard } from './guards/role.guard';
import { ClinicalShellComponent } from './layout/clinical-shell/clinical-shell.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { WorklistComponent } from './pages/worklist/worklist.component';
import { SchedulingComponent } from './pages/scheduling/scheduling.component';
import { MessagesComponent } from './pages/messages/messages.component';
import { AdminComponent } from './pages/admin/admin.component';
import { PatientChartComponent } from './pages/patient-chart/patient-chart.component';
import { EncounterWorkspaceComponent } from './pages/encounter-workspace/encounter-workspace.component';
import { OrdersResultsComponent } from './pages/orders-results/orders-results.component';
import { MedicationReconciliationComponent } from './pages/medication-reconciliation/medication-reconciliation.component';
import { BillingClaimsComponent } from './pages/billing-claims/billing-claims.component';
import { TaskQueueComponent } from './pages/task-queue/task-queue.component';
import { AdminAccessControlComponent } from './pages/admin-access-control/admin-access-control.component';
import { AdminAuditLogComponent } from './pages/admin-audit-log/admin-audit-log.component';
import { AdminDataGovernanceComponent } from './pages/admin-data-governance/admin-data-governance.component';
import { UnauthorizedComponent } from './pages/unauthorized/unauthorized.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'unauthorized', component: UnauthorizedComponent },
  {
    path: '',
    component: ClinicalShellComponent,
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      { path: 'dashboard', component: DashboardComponent },
      { path: 'patients/worklist', component: WorklistComponent },
      { path: 'patients/chart/:idNumber', component: PatientChartComponent },
      { path: 'patients/workbench', component: PatientWorkbenchComponent },
      { path: 'clinical/encounter', component: EncounterWorkspaceComponent },
      { path: 'clinical/orders-results', component: OrdersResultsComponent },
      { path: 'clinical/medication-reconciliation', component: MedicationReconciliationComponent },
      {
        path: 'scheduling',
        component: SchedulingComponent,
        canActivate: [roleGuard],
        data: { roles: ['ADMIN', 'DOCTOR', 'NURSE', 'BILLING', 'PHARMACIST'] }
      },
      {
        path: 'operations/task-queue',
        component: TaskQueueComponent,
        canActivate: [roleGuard],
        data: { roles: ['ADMIN', 'DOCTOR', 'NURSE', 'PHARMACIST', 'BILLING'] }
      },
      {
        path: 'revenue/billing-claims',
        component: BillingClaimsComponent,
        canActivate: [roleGuard],
        data: { roles: ['ADMIN', 'BILLING'] }
      },
      { path: 'messages', component: MessagesComponent },
      { path: 'admin', component: AdminComponent, canActivate: [roleGuard], data: { roles: ['ADMIN'] } },
      {
        path: 'admin/access-control',
        component: AdminAccessControlComponent,
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/audit-log',
        component: AdminAuditLogComponent,
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      },
      {
        path: 'admin/data-governance',
        component: AdminDataGovernanceComponent,
        canActivate: [roleGuard],
        data: { roles: ['ADMIN'] }
      }
    ]
  },
  { path: '**', redirectTo: '' }
];

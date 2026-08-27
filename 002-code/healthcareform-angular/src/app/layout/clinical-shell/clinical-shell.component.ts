import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { PatientHubSelectionService } from '../../pages/patient-hub/patient-hub-selection.service';
import { AuthService } from '../../services/auth.service';

type NavItem = {
  label: string;
  route: string;
  exact?: boolean;
  level?: 0 | 1;
  roles?: string[];
};

@Component({
  selector: 'app-clinical-shell',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  providers: [PatientHubSelectionService],
  templateUrl: './clinical-shell.component.html',
  styleUrl: './clinical-shell.component.scss'
})
export class ClinicalShellComponent {
  readonly navItems: NavItem[] = [
    { label: 'Ops Dashboard', route: '/dashboard', exact: true },
    { label: 'Patient Hub', route: '/patients/hub' },
    { label: 'Patient Registration', route: '/patients/registration', level: 1 },
    { label: 'Encounter Workspace', route: '/clinical/encounter' },
    { label: 'Orders & Results', route: '/clinical/orders-results' },
    { label: 'Med Reconciliation', route: '/clinical/medication-reconciliation' },
    { label: 'Scheduling', route: '/scheduling' },
    { label: 'Team Task Queue', route: '/operations/task-queue', roles: ['ADMIN', 'DOCTOR', 'NURSE', 'PHARMACIST', 'BILLING'] },
    { label: 'Billing & Claims', route: '/revenue/billing-claims', roles: ['ADMIN', 'BILLING'] },
    { label: 'Messages', route: '/messages' },
    { label: 'Admin Hub', route: '/admin', roles: ['ADMIN'] },
    { label: 'Client Directory', route: '/admin/clients', roles: ['ADMIN'] },
    { label: 'Access Control', route: '/admin/access-control', roles: ['ADMIN'] },
    { label: 'Audit Log', route: '/admin/audit-log', roles: ['ADMIN'] },
    { label: 'Data Governance', route: '/admin/data-governance', roles: ['ADMIN'] }
  ];

  readonly todayLabel = new Intl.DateTimeFormat('en-US', {
    weekday: 'long',
    month: 'short',
    day: 'numeric',
    year: 'numeric'
  }).format(new Date());

  constructor(private readonly authService: AuthService) {}

  get visibleNavItems(): NavItem[] {
    const roleSet = new Set(this.authService.getCurrentRoles().map((role) => role.toUpperCase()));
    return this.navItems.filter((item) => {
      if (!item.roles || item.roles.length === 0) {
        return true;
      }

      return item.roles.some((role) => roleSet.has(role.toUpperCase()));
    });
  }

  get username(): string {
    return this.authService.getCurrentUsername() || 'Clinical User';
  }

  logout(): void {
    this.authService.logout();
  }
}

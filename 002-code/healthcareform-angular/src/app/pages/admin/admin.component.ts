import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';

type AdminCard = {
  title: string;
  description: string;
  route: string;
  metricLabel: string;
  metricValue: string;
  tone: 'neutral' | 'warning' | 'critical';
};

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './admin.component.html',
  styleUrl: './admin.component.scss'
})
export class AdminComponent {
  readonly cards: AdminCard[] = [
    {
      title: 'Role and Permission Control',
      description: 'Review user role assignments and module-level permission coverage.',
      route: '/admin/access-control',
      metricLabel: 'Access reviews due',
      metricValue: '4',
      tone: 'warning'
    },
    {
      title: 'Security Audit Log',
      description: 'Filter privileged actions, failed authentications, and policy exceptions.',
      route: '/admin/audit-log',
      metricLabel: 'Anomalies in 24h',
      metricValue: '2',
      tone: 'critical'
    },
    {
      title: 'Data Governance Console',
      description: 'Manage lookup quality, template lifecycle, and environment configuration drift.',
      route: '/admin/data-governance',
      metricLabel: 'Pending approvals',
      metricValue: '6',
      tone: 'neutral'
    }
  ];

  readonly complianceChecklist: string[] = [
    'Weekly role recertification for privileged accounts.',
    'Daily exception review for failed login lockouts.',
    'Monthly lookup and template version reconciliation.'
  ];

  constructor(private readonly authService: AuthService) {}

  get currentPrincipal(): string {
    const user = this.authService.getCurrentUser();
    if (!user) {
      return 'Authenticated user';
    }

    return `${user.FirstName} ${user.LastName}`.trim() || user.Username;
  }

  get roleSummary(): string {
    const roles = this.authService.getCurrentRoles();
    if (roles.length === 0) {
      return 'No roles in token';
    }

    return roles.join(', ');
  }
}

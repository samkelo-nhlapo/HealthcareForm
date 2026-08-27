import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

@Component({
  selector: 'app-patient-hub-redirect',
  standalone: true,
  imports: [CommonModule],
  template: `
    <section class="panel">
      <h3>Redirecting to Patient Hub...</h3>
    </section>
  `
})
export class PatientHubRedirectComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  ngOnInit(): void {
    const destination = this.route.snapshot.data['destination'];
    if (destination === 'registration') {
      void this.router.navigate(['/patients/registration'], {
        queryParams: this.route.snapshot.queryParams,
        replaceUrl: true
      });
      return;
    }

    const tab = this.resolveTab(this.route.snapshot.data['tab']);

    void this.router.navigate(['/patients/hub'], {
      queryParams: {
        ...this.route.snapshot.queryParams,
        tab
      },
      replaceUrl: true
    });
  }

  private resolveTab(value: unknown): 'worklist' | 'directory' {
    if (value === 'directory') {
      return value;
    }

    return 'worklist';
  }
}

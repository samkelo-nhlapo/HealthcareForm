import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  private readonly fb = inject(FormBuilder);

  errorMessage = '';
  submitting = false;

  readonly loginForm = this.fb.nonNullable.group({
    UsernameOrEmail: ['', Validators.required],
    Password: ['', Validators.required]
  });

  constructor(
    private readonly authService: AuthService,
    private readonly router: Router
  ) {
    if (this.authService.isAuthenticated()) {
      void this.router.navigate(['/']);
    }
  }

  login(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      this.errorMessage = 'Username/email and password are required.';
      return;
    }

    this.errorMessage = '';
    this.submitting = true;

    this.authService.login(this.loginForm.getRawValue()).subscribe({
      next: () => {
        this.submitting = false;
        void this.router.navigate(['/']);
      },
      error: (error) => {
        this.submitting = false;
        this.errorMessage = error?.error?.Message ?? error?.error?.message ?? 'Login failed.';
      }
    });
  }
}

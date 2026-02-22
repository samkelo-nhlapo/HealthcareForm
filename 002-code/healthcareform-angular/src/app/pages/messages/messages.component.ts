import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

type MessageItem = {
  sender: string;
  topic: string;
  age: string;
};

@Component({
  selector: 'app-messages',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './messages.component.html',
  styleUrl: './messages.component.scss'
})
export class MessagesComponent {
  readonly items: MessageItem[] = [
    { sender: 'Nurse Station A', topic: 'Escalation: pain score increase for ward 3', age: '2 min ago' },
    { sender: 'Billing Office', topic: 'Claim rejection requires diagnosis code review', age: '18 min ago' },
    { sender: 'Lab Intake', topic: 'Specimen recollection request for Patient #2481', age: '34 min ago' }
  ];
}

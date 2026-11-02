import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { DatePipe } from '@angular/common';

interface Note {
  id: number;
  content: string;
  created_at: string;
}

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [FormsModule, DatePipe],
  template: `
    <main style="max-width:600px;margin:2rem auto;font-family:sans-serif">
      <h1>Notatki (test infrastruktury)</h1>

      <p>Status API:
        <strong [style.color]="health === 'ok' ? 'green' : 'red'">{{ health }}</strong>
      </p>

      <form (ngSubmit)="add()">
        <input name="content" [(ngModel)]="newContent" placeholder="Treść notatki"
               style="width:70%;padding:6px" />
        <button type="submit" style="padding:6px 12px">Dodaj</button>
      </form>

      @if (error) { <p style="color:red">{{ error }}</p> }

      <ul>
        @for (n of notes; track n.id) {
          <li>
            {{ n.content }}
            <small>({{ n.created_at | date: 'dd.MM.yyyy HH:mm:ss' }})</small>
            <button (click)="remove(n.id)">usuń</button>
          </li>
        }
      </ul>
    </main>
  `,
})
export class AppComponent implements OnInit {
  notes: Note[] = [];
  newContent = '';
  health = '...';
  error = '';

  constructor(private http: HttpClient, private changeDetector: ChangeDetectorRef) {}

  ngOnInit() {
    this.http.get<{ status: string }>('/api/health').subscribe({
      next: (r) => {
        this.health = r.status;
        this.changeDetector.markForCheck();
      },
      error: () => {
        this.health = 'niedostępne';
        this.changeDetector.markForCheck();
      },
    });
    this.load();
  }

  load() {
    this.http.get<Note[]>('/api/notes').subscribe({
      next: (n) => {
        this.notes = n;
        this.error = '';
        this.changeDetector.markForCheck();
      },
      error: () => {
        this.error = 'Nie udało się pobrać notatek';
        this.changeDetector.markForCheck();
      },
    });
  }

  add() {
    if (!this.newContent.trim()) return;
    this.http.post('/api/notes', { content: this.newContent }).subscribe({
      next: () => { this.newContent = ''; this.load(); },
      error: () => {
        this.error = 'Nie udało się dodać notatki';
        this.changeDetector.markForCheck();
      },
    });
  }

  remove(id: number) {
    this.http.delete(`/api/notes/${id}`).subscribe(() => this.load());
  }
}

# NEXORA

**Your skills. Your potential. Your next opportunity.**

NEXORA is a Flutter + FastAPI career-readiness application. This project includes a PDF resume analyzer, role-based skill gap analyzer, personalized learning roadmap, sample job matching, interview practice, and a profile workspace.

## Included modules

1. **Dashboard** – overview of your workspace and quick navigation.
2. **Resume Analyzer** – PDF upload, text extraction, skill detection, section checks and a preliminary heuristic score.
3. **Job Matching** – ranks illustrative sample roles by overlap between your skills and role requirements. These are not live vacancies.
4. **Skill Gap Analyzer** – compares your skills with five target career paths.
5. **Learning Roadmap** – creates a weekly plan from the skills missing for the selected role.
6. **Interview Preparation** – role-based technical and HR question sets with rule-based answer-length feedback.
7. **My Profile** – edit your display name, target role and skills for the current app session.

## Requirements

- Flutter SDK compatible with the `environment.sdk` value in `pubspec.yaml`.
- Python 3.10 or newer.
- macOS, Windows or Linux.

## Run the backend (Terminal 1)

```bash
cd nexora/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

On Windows PowerShell, activate with `.venv\\Scripts\\Activate.ps1`.

API documentation: http://127.0.0.1:8000/docs
Health check: http://127.0.0.1:8000/health

## Run Flutter (Terminal 2)

```bash
cd nexora
flutter pub get
flutter run -d chrome
```

For a macOS desktop build, use `flutter run -d macos` after enabling macOS desktop support.

## API endpoints

- `GET /` and `GET /health`
- `POST /analyze-resume`
- `POST /analyze-skill-gap`
- `POST /generate-roadmap`
- `POST /match-jobs`
- `POST /interview/questions`
- `POST /interview/evaluate`

## Important notes and current limitations

- Resume score is a preliminary rule-based heuristic, not an official ATS score or hiring prediction.
- Resume parsing currently extracts selectable PDF text. Scanned/image-only PDFs need OCR and are not supported by this version.
- Job matching uses bundled illustrative sample roles; it does not scrape live vacancies or submit applications.
- Interview questions are curated role-based prompts. Feedback is heuristic and does not use an LLM or replace an interviewer's assessment.
- Profile edits and roadmap checkbox progress are currently held in app memory and may reset when the app is restarted. Authentication and persistent user storage are not configured.
- The app's API URLs are set to `127.0.0.1`, suitable for Flutter Web on the same computer and local desktop runs. For a physical phone, change the API host to your computer's LAN IP; Android emulator commonly uses `10.0.2.2`.
- Before public deployment, add authentication, database-backed profiles/progress, secrets management, HTTPS, rate limiting, stronger validation and privacy controls.

## Project structure

```text
nexora/
├── lib/
│   ├── main.dart
│   └── screens/
│       ├── resume_screen.dart
│       ├── skill_gap_screen.dart
│       ├── learning_roadmap_screen.dart
│       ├── job_matching_screen.dart
│       └── interview_prep_screen.dart
└── backend/
    ├── main.py
    └── requirements.txt
```

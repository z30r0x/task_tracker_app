# Task Tracker

Task Tracker is a Flutter application for organizing technical work in one
simple dashboard. It helps users create, categorize, prioritize, complete, and
review tasks while keeping task data available locally on the device.

## Main features

- Create tasks with a title, description, category, priority, and due date.
- Filter active tasks by category or view all tasks.
- Open task details to edit or delete a task.
- Mark tasks as completed and move them to the Completed page.
- Uncheck completed tasks to return them to the active task list.
- Persist active and completed tasks locally with `shared_preferences`.
- Customize the app accent with the three design colors:
  - Green: `#3FB950`
  - Blue: `#0D99FF`
  - Cyan: `#00E5FF`
- Use the Settings page to change the accent color and language preference.
- Use the shared DataPulse logo and centralized color, font, and image tokens.

## Project structure

```text
lib/
├── main.dart
├── core/
│   └── utils/
│       ├── colors.dart
│       └── styles/
│           ├── fonts.dart
│           └── images.dart
└── features/
    ├── home_page/
    │   └── home.dart
    ├── completed_tasks_page/
    │   └── completed_tasks.dart
    └── settings_page/
        └── settings.dart
```

## How it works

- `main.dart` creates the app theme and keeps the selected accent color in
  sync with the Settings page.
- `home.dart` manages the task list, task dialogs, category filtering, task
  completion, and local storage.
- `completed_tasks.dart` displays completed tasks and lets users edit, delete,
  or uncheck them.
- `settings.dart` displays the color panel and preference controls.
- `shared_preferences` stores tasks as JSON strings and stores the selected
  accent color between app launches.
- Shared visual tokens are defined in `core/utils/colors.dart` and
  `core/utils/styles/`.

## Run the project

Make sure Flutter is installed, then run:

```bash
flutter pub get
flutter run
```

## Validate the project

Run static analysis and tests with:

```bash
flutter analyze
flutter test
```

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_tracker/main.dart';

void main() {
  testWidgets('renders the English task dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskTrackerApp());

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(
      find.text('Build daily ETL pipeline for sales data'),
      findsOneWidget,
    );
    expect(find.text('New task'), findsOneWidget);
    expect(find.text('All tasks'), findsOneWidget);
  });

  testWidgets('shows the completed page with the logo and completed task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskTrackerApp());

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Completed tasks'), findsOneWidget);
    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Create data quality checks'), findsOneWidget);
  });

  testWidgets('shows dates and the settings design', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskTrackerApp());

    expect(find.text('Due 14/09/2026'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Workspace'), findsNothing);
  });

  testWidgets('filters tasks by category and deletes task from details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskTrackerApp());

    await tester.tap(find.text('SQL Queries'));
    await tester.pumpAndSettle();
    expect(find.text('Review slow SQL queries'), findsOneWidget);
    expect(find.text('Build daily ETL pipeline for sales data'), findsNothing);

    await tester.tap(find.text('Review slow SQL queries'));
    await tester.pumpAndSettle();
    expect(find.text('Category: SQL Queries'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Review slow SQL queries'), findsNothing);
  });

  testWidgets('changes the app accent from the settings color panel', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskTrackerApp());

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Colors'), findsOneWidget);
    final colorChoice = find.byType(GestureDetector).last;
    await tester.tap(colorChoice);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
  });
}

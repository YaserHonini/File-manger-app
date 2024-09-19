import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_manager_app/main.dart'; // تأكد من استخدام المسار الصحيح

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // بناء التطبيق
    await tester.pumpWidget(FileManagerApp());

    // تحقق من وجود النص "0" في واجهة المستخدم
    expect(find.text('0'), findsOneWidget);

    // تحقق من وجود عنصر واجهة المستخدم (مثلاً زراً) للتفاعل معه
    final Finder incrementButton = find.byIcon(Icons.add);
    expect(incrementButton, findsOneWidget);

    // تفاعل مع الزر
    await tester.tap(incrementButton);
    await tester.pump();

    // تحقق من أن النص قد تغير
    expect(find.text('1'), findsOneWidget);
  });
}

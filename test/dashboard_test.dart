import 'package:expenses_app/expenses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/utils/app_state_notifier.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
    return '.';
  });

  sqfliteFfiInit();

  DbHelper.instance;

  databaseFactory = databaseFactoryFfiNoIsolate;

  testWidgets('Test dashboard title', (widgetTester) async {
    await widgetTester.pumpWidget(ChangeNotifierProvider<AppStateNotifier>(
      create: (_) => AppStateNotifier(),
      builder: (context, _) => const Expenses(),
    ));

    expect(find.text('0'), findsNothing);
    expect(find.text('No Transactions'), findsOne);
  });
}

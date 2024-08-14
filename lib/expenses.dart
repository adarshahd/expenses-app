import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/screens/dashboard.dart';
import 'package:expenses_app/screens/home.dart';
import 'package:expenses_app/screens/settings.dart';
import 'package:expenses_app/utils/app_state_notifier.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  DbHelper.instance;

  runApp(ChangeNotifierProvider<AppStateNotifier>(
    create: (_) => AppStateNotifier(),
    child: const Expenses(),
  ));
}

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  bool _isLoading = true;

  // Routes
  static final routes = {
    '/dashboard': (context) => const Dashboard(),
    '/settings': (context) => const Settings(),
  };

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  void _initialize() async {
    await DbHelper.instance.initialize();

    Setting? themeSetting = await DbHelper.instance
        .getSetting(Constants.settingApplicationThemeMode);
    bool isDarkMode = bool.parse(themeSetting!.value);
    Provider.of<AppStateNotifier>(context, listen: false)
        .changeTheme(isDarkMode);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, value, child) {
        return MaterialApp(
          title: "Expenses",
          routes: routes,
          home: _getHome(context),
          theme: _getTheme(value),
        );
      },
    );
  }

  _getHome(context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    return const Home();
  }

  _getTheme(appState) {
    if (appState.isDarkMode) {
      return ThemeData.from(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue,
          secondary: Colors.blue,
        ),
      );
    } else {
      return ThemeData.from(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.deepOrange,
          secondary: Colors.deepOrangeAccent,
        ),
      );
    }
  }
}

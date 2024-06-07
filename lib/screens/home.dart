import 'package:expenses_app/screens/components/desktop_container.dart';
import 'package:expenses_app/screens/components/mobile_container.dart';
import 'package:expenses_app/screens/introduction.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:expenses_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isFirstRun = false;
  late SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((preferences) {
      _preferences = preferences;
      setState(() {
        _isFirstRun = _preferences.getBool(Constants.prefIsFirstRun) ?? true;
      });

      if (_isFirstRun) {
        _showIntroduction();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
    );
  }

  _getBody() {
    if (Utils.isLargeScreen(context)) {
      return const DesktopContainer();
    }

    return const MobileContainer();
  }

  _showIntroduction() async {
    bool isCompleted = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const Introduction(),
          ),
        ) ??
        false;

    setState(() {
      _isFirstRun = isCompleted;
    });
  }
}

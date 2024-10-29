import 'package:expenses_app/screens/dashboard.dart';
import 'package:expenses_app/screens/settings.dart';
import 'package:expenses_app/screens/transactions.dart';
import 'package:flutter/material.dart';

class DesktopContainer extends StatefulWidget {
  const DesktopContainer({super.key});

  @override
  State<DesktopContainer> createState() => _DesktopContainerState();
}

class _DesktopContainerState extends State<DesktopContainer> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
    );
  }

  _getBody() {
    return Row(
      children: [
        SizedBox(
          width: _getDrawerWidth(context),
          child: _getNavItems(),
        ),
        Expanded(child: _getContainerContent()),
      ],
    );
  }

  _getNavItems() {
    return Card(
      elevation: 8,
      child: ListView(
        children: [
          const SizedBox(height: 48),
          Text(
            "Expenses",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 48),
          ListTile(
            title: const Text("Dashboard"),
            leading: const Icon(Icons.home),
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
            },
            selected: _currentIndex == 0,
          ),
          ListTile(
            title: const Text('Transactions'),
            leading: const Icon(Icons.list),
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            selected: _currentIndex == 1,
          ),
          ListTile(
            title: const Text("Settings"),
            leading: const Icon(Icons.settings),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
            },
            selected: _currentIndex == 2,
          )
        ],
      ),
    );
  }

  _getDrawerWidth(context) {
    return MediaQuery.of(context).size.width / 5;
  }

  _getContainerContent() {
    switch (_currentIndex) {
      case 0:
        return const Dashboard();
      case 1:
        return const Transactions();
      case 2:
        return const Settings();
    }
  }
}

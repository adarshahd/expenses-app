import 'package:expenses_app/screens/dashboard.dart';
import 'package:expenses_app/screens/settings.dart';
import 'package:flutter/material.dart';

class MobileContainer extends StatefulWidget {
  const MobileContainer({super.key});

  @override
  State<MobileContainer> createState() => _MobileContainerState();
}

class _MobileContainerState extends State<MobileContainer> {
  int _selectedNavigationItemIndex = 0;

  static const _bottomNavigationItems = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')
  ];

  late PageController _pageController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getContainerBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavigationItems,
        onTap: (index) {
          setState(() {
            _selectedNavigationItemIndex = index;
            _pageController.animateToPage(
              index,
              duration: Durations.medium1,
              curve: Curves.easeOut,
            );
          });
        },
        currentIndex: _selectedNavigationItemIndex,
      ),
    );
  }

  _getContainerBody() {
    return PageView(
      controller: _pageController,
      children: const [
        Dashboard(),
        Settings(),
      ],
      onPageChanged: (index) {
        setState(() {
          _selectedNavigationItemIndex = index;
        });
      },
    );
  }
}

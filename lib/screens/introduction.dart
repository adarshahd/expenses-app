import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Introduction extends StatefulWidget {
  const Introduction({super.key});

  @override
  State<Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends State<Introduction> {
  late List<Currency> _currencies;
  late Currency _defaultCurrency;
  late SharedPreferences _preferences;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((preferences) {
      _preferences = preferences;
    });

    _currencies = CurrencyService().getAll();
    _defaultCurrency = _currencies.where((item) => item.code == 'INR').first;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) => _updateIntroductionCompleted(),
      child: SafeArea(
        child: IntroductionScreen(
          next: const Text("Next"),
          done: const Text('Continue'),
          skip: const Text('Skip'),
          onDone: () => _onDone(),
          bodyPadding: const EdgeInsets.all(16),
          pages: [
            PageViewModel(
              bodyWidget: Column(
                children: [
                  Text(
                    'Expense Manager',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simple to start, Powerful when needed',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              titleWidget: Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              image: SvgPicture.asset('assets/images/undraw_welcoming.svg'),
            ),
            PageViewModel(
              title: 'Select currency',
              image:
                  SvgPicture.asset('assets/images/undraw_connected_world.svg'),
              bodyWidget: Container(
                margin: const EdgeInsets.all(8),
                child: DropdownMenu<Currency>(
                  dropdownMenuEntries: _getCurrencyDropdown(),
                  onSelected: (value) =>
                      _defaultCurrency = value ?? _defaultCurrency,
                  enableSearch: true,
                  menuHeight: MediaQuery.of(context).size.height / 3,
                  leadingIcon: const Icon(Icons.location_on_outlined),
                  initialSelection: _defaultCurrency,
                  width: MediaQuery.of(context).size.width * 3 / 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _getCurrencyDropdown() {
    List<DropdownMenuEntry<Currency>> dropdownItems = [];
    for (Currency currency in _currencies) {
      dropdownItems.add(
        DropdownMenuEntry<Currency>(
          label: '${currency.symbol} ${currency.name}',
          value: currency,
        ),
      );
    }

    return dropdownItems;
  }

  _updateIntroductionCompleted() {
    DbHelper.instance.createOrUpdateSetting(
      Constants.settingApplicationCurrency,
      jsonEncode(_defaultCurrency.toJson()),
    );
    _preferences.setBool(Constants.prefIsFirstRun, false);
  }

  _onDone() {
    _updateIntroductionCompleted();
    Navigator.of(context).pop(false);
  }
}

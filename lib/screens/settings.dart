import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/utils/app_state_notifier.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late Currency _currency;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    DbHelper.instance
        .getSetting(Constants.settingApplicationCurrency)
        .then((setting) {
      Setting currencySetting = setting!;

      _currency = Currency.from(json: jsonDecode(currencySetting.value));

      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              "Settings",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Row(
                children: [
                  const Text("Dark Theme"),
                  const Spacer(),
                  Switch.adaptive(
                    value: Provider.of<AppStateNotifier>(context).isDarkMode,
                    onChanged: (value) => _updateTheme(value),
                  )
                ],
              ),
              onTap: () => _updateTheme(
                  !Provider.of<AppStateNotifier>(context, listen: false)
                      .isDarkMode),
            ),
            ListTile(
              title: Row(
                children: [
                  const Text("Application Currency"),
                  const Spacer(),
                  _getCurrency()
                ],
              ),
              onTap: () {
                showCurrencyPicker(
                  context: context,
                  showFlag: true,
                  showCurrencyName: true,
                  showCurrencyCode: true,
                  onSelect: (value) => _updateCurrency(value),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  _updateTheme(bool value) {
    Provider.of<AppStateNotifier>(context, listen: false).changeTheme(value);
    DbHelper.instance
        .createOrUpdateSetting(Constants.settingApplicationThemeMode, value);
  }

  _getCurrency() {
    if (_isLoading) {
      return const CircularProgressIndicator.adaptive();
    }

    return Text("${_currency.symbol} ${_currency.code}");
  }

  _updateCurrency(Currency currency) {
    setState(() {
      _currency = currency;
    });

    DbHelper.instance.createOrUpdateSetting(
        Constants.settingApplicationCurrency, jsonEncode(_currency.toJson()));
  }
}

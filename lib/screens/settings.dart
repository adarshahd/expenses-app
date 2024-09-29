import 'dart:convert';
import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/utils/app_state_notifier.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const MethodChannel _channel = MethodChannel("io.gthink.expenses/file_operations");

  late Currency _currency;
  bool _isLoading = true;
  late SharedPreferences _preferences;
  String? _customPath;

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

    SharedPreferences.getInstance().then((preferences) {
      _preferences = preferences;
      _customPath = preferences.getString(Constants.prefDbFileLocation);
    });
  }

  @override
  Widget build(BuildContext context) {
    String? directoryString = '';
    if (_customPath != null) {
      String customPath = '${_customPath!.substring(0, 30)}...';
      directoryString =
          'Custom location can result in performance degrade. Click and hold to reset. \n$customPath';
    } else {
      directoryString = 'Custom location can result in performance degrade.';
    }

    return SafeArea(
      child: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(8),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              Text(
                "Settings",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Row(
                    children: [
                      const Text("Dark Theme"),
                      const Spacer(),
                      Switch.adaptive(
                        value:
                            Provider.of<AppStateNotifier>(context).isDarkMode,
                        onChanged: (value) => _updateTheme(value),
                      )
                    ],
                  ),
                  leading: const Icon(Icons.dark_mode_rounded),
                  onTap: () => _updateTheme(
                      !Provider.of<AppStateNotifier>(context, listen: false)
                          .isDarkMode),
                ),
              ),
              Card(
                child: ListTile(
                  title: Row(
                    children: [
                      const Text("Application Currency"),
                      const Spacer(),
                      _getCurrency()
                    ],
                  ),
                  leading: const Icon(Icons.currency_exchange_rounded),
                  onTap: () {
                    showCurrencyPicker(
                      context: context,
                      showFlag: true,
                      showCurrencyName: true,
                      showCurrencyCode: true,
                      onSelect: (value) => _updateCurrency(value),
                    );
                  },
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Database File Location'),
                  subtitle: Text(directoryString),
                  isThreeLine: true,
                  leading: const Icon(Icons.storage_rounded),
                  onTap: () => _showFilePicker(),
                  onLongPress:
                      _customPath == null ? () => {} : () => _showResetDialog(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
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

  _showFilePicker() async {
    String? selectedFile;
    if(!Platform.isAndroid) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Expenses storage location',
      );

      selectedFile = result?.files.single.path;
    } else {
      selectedFile = await _channel.invokeMethod("pick_file");
    }

    if (selectedFile != null && context.mounted) {
      bool shouldReload = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm Reload'),
            content: const Text(
              '''To use the storage location selected,
              application will be reloaded. Are you sure ?''',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Ok'),
              )
            ],
          );
        },
      );

      if (shouldReload) {
        await _preferences.setString(
            Constants.prefDbFileLocation, selectedFile);

        await DbHelper.instance.initialize();

        setState(() {
          _customPath = selectedFile;
        });
      }
    }
  }

  _showResetDialog() async {
    bool shouldReset = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Database path reset'),
          content: const Text(
            '''Database path will be reset back to default path.,
              Are you sure ?''',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ok'),
            )
          ],
        );
      },
    );

    if (shouldReset) {
      await _preferences.remove(Constants.prefDbFileLocation);

      setState(() {
        _customPath = null;
      });
    }
  }
}

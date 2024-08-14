import 'dart:convert';
import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/utils/app_state_notifier.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late Currency _currency;
  bool _isLoading = true;
  late SharedPreferences _preferences;
  String? _applicationDatabaseDirectory;

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
      _applicationDatabaseDirectory =
          preferences.getString(Constants.prefDbFileLocation);
      if (_applicationDatabaseDirectory == null) {
        getApplicationDocumentsDirectory().then((directory) {
          _applicationDatabaseDirectory = directory.path;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  subtitle: Text(_applicationDatabaseDirectory ?? ''),
                  leading: const Icon(Icons.storage_rounded),
                  onTap: () => _showFilePicker(),
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
    String? selectedDirectory;
    if (Platform.isAndroid) {
      DirectoryLocation? pickedDirectory = await FlutterFileDialog.pickDirectory();
      selectedDirectory = pickedDirectory.toString();
    } else {
      selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Chose data location',
      );
    }

    if (selectedDirectory != null && context.mounted) {
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
            Constants.prefDbFileLocation, selectedDirectory);

        await DbHelper.instance.initialize();

        setState(() {
          _applicationDatabaseDirectory = selectedDirectory;
        });
      }
    }
  }
}

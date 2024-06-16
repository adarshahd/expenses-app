import 'dart:convert';
import 'dart:math';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/utils/constants.dart';

class Initialize {
  late final DbHelper _dbHelper;

  Initialize({required String dbPath}) {
    _dbHelper = DbHelper.instance;
  }

  Future<void> run() async {
    await _createDefaultAccount();
    await _createDefaultCategories();
    await _setDefaultThemeMode();
    await _setDefaultApplicationCurrency();
  }

  _createDefaultAccount() async {
    // Create default account if not created before
    Setting? defaultAccountCreated = await _dbHelper.getSetting(
      Constants.settingDefaultAccountCreated,
    );

    if (defaultAccountCreated == null) {
      _dbHelper.createAccount(
        'Default',
        'Default account',
        isDefault: true,
      );

      _dbHelper.createOrUpdateSetting(
        Constants.settingDefaultAccountCreated,
        true,
      );
    }
  }

  _createDefaultCategories() async {
    Setting? defaultCategoriesCreated = await _dbHelper.getSetting(
      Constants.settingDefaultCategoriesCreated,
    );

    if (defaultCategoriesCreated == null) {
      _dbHelper.createCategory(
        'Others',
        'Default Category',
        (Random().nextDouble() * 0xFFFFFF).toInt(),
      );

      _dbHelper.createOrUpdateSetting(
        Constants.settingDefaultCategoriesCreated,
        true,
      );
    }
  }

  _setDefaultThemeMode() async {
    Setting? defaultApplicationThemeModeSet = await _dbHelper.getSetting(
      Constants.settingThemeModeSet,
    );

    if (defaultApplicationThemeModeSet == null) {
      _dbHelper.createOrUpdateSetting(
        Constants.settingApplicationThemeMode,
        false,
      );

      _dbHelper.createOrUpdateSetting(
        Constants.settingThemeModeSet,
        true,
      );
    }
  }

  _setDefaultApplicationCurrency() async {
    Setting? defaultApplicationCurrencySet = await _dbHelper.getSetting(
      Constants.settingDefaultCurrencySet,
    );

    if (defaultApplicationCurrencySet == null) {
      Currency? currencyINR = CurrencyService().findByCode("INR");

      _dbHelper.createOrUpdateSetting(
        Constants.settingApplicationCurrency,
        jsonEncode(currencyINR!.toJson()),
      );

      _dbHelper.createOrUpdateSetting(
        Constants.settingDefaultCurrencySet,
        true,
      );
    }
  }
}

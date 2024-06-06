import 'package:currency_picker/currency_picker.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final CurrencyFormatter instance = CurrencyFormatter._();

  CurrencyFormatter._();

  String formatCurrency(int amount, Currency currency) {
    return NumberFormat.currency(
      decimalDigits: currency.decimalDigits,
      symbol: currency.symbol,
    ).format(amount / 100);
  }
}

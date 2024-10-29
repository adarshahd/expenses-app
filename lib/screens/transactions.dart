import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/models/transaction_filter.dart' as filter;
import 'package:expenses_app/screens/components/transaction_filter.dart';
import 'package:expenses_app/screens/transaction.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:expenses_app/utils/currency_formatter.dart';
import 'package:expenses_app/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class Transactions extends StatefulWidget {
  const Transactions({super.key});

  @override
  State<Transactions> createState() => _TransactionsState();
}

class _TransactionsState extends State<Transactions> {
  bool _isLoading = false;
  late Currency _currency;
  List<AccountTransaction> _transactions = [];
  late filter.TransactionFilterModel _filter;

  @override
  void initState() {
    super.initState();

    DateTime current = DateTime.now();
    _filter = filter.TransactionFilterModel(
      startDate: DateTime(current.year, current.month),
      endDate: DateTime(current.year, current.month, current.day, 23, 59, 59),
      categories: '',
      minAmount: 0,
      maxAmount: 1000000,
      type: null,
    );

    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(8),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Transactions",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _getTransactionListView(),
              )
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showFilters(),
          child: const Icon(Icons.filter_alt_rounded),
        ),
      ),
    );
  }

  _initialize() async {
    Setting? currencySetting = await DbHelper.instance
        .getSetting(Constants.settingApplicationCurrency);

    if (currencySetting == null) {
      _currency = CurrencyService().findByCode('INR')!;
    } else {
      _currency = Currency.from(json: jsonDecode(currencySetting.value));
    }

    await _getTransactions();

    setState(() {
      _isLoading = false;
    });
  }

  _getTransactionListView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const SizedBox(height: 32),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 3,
                height: MediaQuery.of(context).size.height / 3,
                child: SvgPicture.asset('assets/images/undraw_add_notes.svg'),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                "No transactions found for selected filters",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemBuilder: (context, index) {
        AccountTransaction transaction = _transactions[index];
        return Card(
          child: ListTile(
            title: Row(
              children: [
                Text(
                  transaction.title ?? '',
                  //style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  CurrencyFormatter.instance
                      .formatCurrency(transaction.total, _currency),
                ),
              ],
            ),
            subtitle: Text(DateFormat(Constants.dateTimeFormat)
                .format(transaction.transactionTime)),
            onTap: () => _editItem(transaction),
          ),
        );
      },
      itemCount: _transactions.length,
      padding: const EdgeInsets.only(bottom: 64),
    );
  }

  _getTransactions() async {
    _transactions = await DbHelper.instance.getTransactions(null, _filter);
  }

  _editItem(AccountTransaction transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return Transaction(txnId: transaction.id);
      }),
    );

    await _getTransactions();
    setState(() {});
  }

  _showFilters() async {
    filter.TransactionFilterModel? transactionFilter;
    if (Utils.isLargeScreen(context)) {
      transactionFilter = await showDialog<filter.TransactionFilterModel>(
        context: context,
        builder: (context) => Dialog(
          child: _showFilterDialog(),
        ),
      );
    } else {
      transactionFilter =
          await showModalBottomSheet<filter.TransactionFilterModel>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: _showFilterSheet(),
          );
        },
      );
    }

    if (transactionFilter != null) {
      _filter = transactionFilter;
      await _getTransactions();

      setState(() {});
    }
  }

  _showFilterDialog() {
    return Container(
      width: 600,
      height: 500,
      margin: const EdgeInsets.all(16),
      child: TransactionFilter(filter: _filter),
    );
  }

  _showFilterSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 2 / 3,
      child: TransactionFilter(filter: _filter),
    );
  }
}

import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/charts/category_map.dart';
import 'package:expenses_app/models/settings.dart';
import 'package:expenses_app/screens/components/transaction_form.dart';
import 'package:expenses_app/screens/transaction.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:expenses_app/utils/currency_formatter.dart';
import 'package:expenses_app/utils/utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _isLoading = true;

  late Currency _currency;
  List<AccountTransaction> _transactions = [];
  List<CategoryMap> _chartData = [];

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _getBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _handleNewItemClick(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  _getBody() {
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
            SvgPicture.asset('assets/images/undraw_add_notes.svg'),
            const SizedBox(height: 32),
            Center(
              child: Text(
                "No Transactions",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            )
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _getChartHeight(),
            child: _getDashboardCharts(),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: Text(
              "Recent Transactions",
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _getTransactionListView(),
          ),
        ],
      ),
    );
  }

  _getDashboardCharts() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 8),
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: Utils.isLargeScreen(context) ? 48 : 32,
              sections: _getChartSections(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _getLegends(),
      ],
    );
  }

  _getTransactionListView() {
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

  _handleNewItemClick(context) async {
    if (Utils.isLargeScreen(context)) {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          child: _getExpenseAddDialog(),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return _getExpenseAddSheet();
        },
      );
    }

    await _getTransactions();
    await _getChartData();
    setState(() {});
  }

  _getExpenseAddDialog() {
    return Container(
      width: 600,
      height: 400,
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            "New Transaction",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: TransactionForm(
              accountTransaction: null,
              isFullForm: false,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: () => _showTransactionScreen(),
              label: const Text('Add More Info'),
              icon: const Icon(Icons.arrow_drop_down),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  _getExpenseAddSheet() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 2 / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            "New Transaction",
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: TransactionForm(
              accountTransaction: null,
              isFullForm: false,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              onPressed: () => _showTransactionScreen(),
              label: const Text('Add More Info'),
              icon: const Icon(Icons.arrow_drop_down),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  _showTransactionScreen() async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return const Transaction(txnId: 0);
      }),
    );
    setState(() {});
  }

  _editItem(AccountTransaction transaction) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return Transaction(txnId: transaction.id);
      }),
    );

    await _getTransactions();
    await _getChartData();
    setState(() {});
  }

  _getChartHeight() {
    if (_transactions.isEmpty) {
      return 0.0;
    }
    return MediaQuery.of(context).size.height / 3;
  }

  _initialize() async {
    await _getTransactions();
    Setting? currencySetting = await DbHelper.instance
        .getSetting(Constants.settingApplicationCurrency);

    if (currencySetting == null) {
      _currency = CurrencyService().findByCode('INR')!;
    } else {
      _currency = Currency.from(json: jsonDecode(currencySetting.value));
    }
    await _getChartData();

    setState(() {
      _isLoading = false;
    });
  }

  _getTransactions() async {
    _transactions = await DbHelper.instance.getTransactions(5, null);
  }

  _getChartData() async {
    _chartData = await DbHelper.instance.getChartData();
  }

  _getChartSections() {
    List<PieChartSectionData> sections = [];
    for (CategoryMap? item in _chartData) {
      sections.add(
        PieChartSectionData(
          radius: Utils.isLargeScreen(context) ? 72 : 48,
          title: '${item!.percent}%',
          value: item.percent!.toDouble(),
          color: Color(item.color!).withOpacity(0.6),
        ),
      );
    }

    return sections;
  }

  _getLegends() {
    List<Widget> legendItems = [];
    for (CategoryMap? item in _chartData) {
      legendItems.add(
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Color(item!.color!).withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(item.title!),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...legendItems,
      ],
    );
  }
}

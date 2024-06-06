import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/screens/components/transaction_form.dart';
import 'package:flutter/material.dart';

class Transaction extends StatefulWidget {
  final int txnId;

  const Transaction({super.key, required this.txnId});

  @override
  State<Transaction> createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  late int _txnId;
  bool _isLoading = true;
  AccountTransaction? _accountTransaction;

  @override
  void initState() {
    super.initState();

    _txnId = widget.txnId;
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_txnId == 0 ? "New Transaction" : "Edit Transaction"),
      ),
      body: _getBody(),
    );
  }

  _initialize() async {
    if (_txnId != 0) {
      _accountTransaction = await DbHelper.instance.getTransaction(_txnId);
    }

    setState(() {
      _isLoading = false;
    });
  }

  _getBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_accountTransaction == null && _txnId != 0) {
      return const Center(
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.amber,
            ),
            Text('Transaction Not Found !!'),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: TransactionForm(
        accountTransaction: _accountTransaction,
        isFullForm: true,
      ),
    );
  }
}

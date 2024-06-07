import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class TransactionForm extends StatefulWidget {
  final bool isFullForm;
  final AccountTransaction? accountTransaction;

  const TransactionForm(
      {super.key, required this.accountTransaction, required this.isFullForm});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

enum TransactionType { credit, debit }

class _TransactionFormState extends State<TransactionForm> {
  late bool _isFullForm;
  late AccountTransaction? _accountTransaction;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _transactionTimeController =
      TextEditingController();
  bool _isSaving = false;
  TransactionType _transactionType = TransactionType.debit;
  static String tempAmount = '';
  DateTime _transactionTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _accountTransaction = widget.accountTransaction;
    _isFullForm = widget.isFullForm;

    // If we have amount entered in the dialog/bottom sheet, populate the same
    // in the full form
    if (tempAmount.isNotEmpty && _isFullForm) {
      _amountController.text = tempAmount;
    }

    // Clear the amount field if the form is reopened from dialog/bottom sheet
    if (!_isFullForm) {
      tempAmount = '';
    }

    if (_accountTransaction != null) {
      _amountController.text = (_accountTransaction!.total / 100).toString();
      _titleController.text = _accountTransaction!.title!;
      _transactionType = _accountTransaction!.type == 'credit'
          ? TransactionType.credit
          : TransactionType.debit;
      _transactionTime = _accountTransaction!.transactionTime;
    }

    _transactionTimeController.text =
        DateFormat(Constants.dateTimeFormat).format(_transactionTime);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SegmentedButton<TransactionType>(
            style: const ButtonStyle(
              visualDensity: VisualDensity(vertical: 1),
            ),
            segments: const <ButtonSegment<TransactionType>>[
              ButtonSegment<TransactionType>(
                value: TransactionType.debit,
                label: Text("Debit"),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment<TransactionType>(
                value: TransactionType.credit,
                label: Text("Credit"),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: <TransactionType>{_transactionType},
            onSelectionChanged: (selection) {
              setState(() {
                _transactionType = selection.first;
              });
            },
          ),
          if (_isFullForm) const SizedBox(height: 16),
          if (_isFullForm)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
                hintText: 'Title',
                labelText: 'Transaction title',
              ),
              keyboardType: TextInputType.text,
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.money_outlined),
              border: OutlineInputBorder(),
              hintText: 'Amount',
              labelText: 'Transaction amount',
            ),
            keyboardType: const TextInputType.numberWithOptions(),
            validator: (value) {
              double? amount = double.tryParse(value!);
              if (amount != null) {
                return null;
              }

              return 'Please enter a valid number';
            },
            autofocus: true,
            onChanged: (value) => tempAmount = value,
          ),
          if (_isFullForm) const SizedBox(height: 16),
          if (_isFullForm)
            TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_month_outlined),
                border: OutlineInputBorder(),
                labelText: 'Transaction time',
              ),
              controller: _transactionTimeController,
              readOnly: true,
              onTap: () => _showDatePicker(),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: _getSaveIcon(),
            onPressed: () {
              bool isFormValid = _formKey.currentState!.validate();
              if (isFormValid) {
                _saveTransaction();
              }
            },
            label: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  _saveTransaction() {
    setState(() {
      _isSaving = true;
    });
    double amount = double.parse(_amountController.text.toString());
    String title = _titleController.text.toString();

    if (_accountTransaction != null) {
      _accountTransaction!.total = (amount * 100).floor();
      _accountTransaction!.title = title;
      _accountTransaction!.type =
          _transactionType == TransactionType.credit ? 'credit' : 'debit';
      _accountTransaction!.transactionTime = _transactionTime;

      DbHelper.instance.updateTransaction(_accountTransaction!);
    } else {
      DbHelper.instance.createTransaction(
        1,
        _transactionType == TransactionType.credit ? 'Income' : 'Expense',
        null,
        (amount * 100).floor(),
        _transactionType == TransactionType.credit ? 'credit' : 'debit',
        _transactionTime,
      );
    }

    tempAmount = '';

    setState(() {
      _isSaving = false;
    });

    Navigator.pop(context);
  }

  _getSaveIcon() {
    if (_isSaving) {
      return const CircularProgressIndicator();
    }
    return const Icon(Icons.check_circle_outline);
  }

  _showDatePicker() async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      borderRadius: const BorderRadius.all(Radius.zero),
      initialDate: _transactionTime,
    );

    setState(() {
      _transactionTime = dateTime ?? _transactionTime;
      _transactionTimeController.text =
          DateFormat(Constants.dateTimeFormat).format(_transactionTime);
    });
  }
}

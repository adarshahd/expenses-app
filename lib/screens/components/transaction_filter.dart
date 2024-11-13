import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/models/transaction_filter.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

class TransactionFilter extends StatefulWidget {
  final TransactionFilterModel filter;

  const TransactionFilter({super.key, required this.filter});

  @override
  State<TransactionFilter> createState() => _TransactionFilterState();
}

enum TransactionType { credit, debit, all }

class _TransactionFilterState extends State<TransactionFilter> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  late TransactionFilterModel _filter;
  TransactionType _transactionType = TransactionType.all;
  Currency? _applicationCurrency;

  @override
  void initState() {
    super.initState();

    _filter = widget.filter;
    _startTimeController.text =
        DateFormat(Constants.dateTimeFormat).format(_filter.startDate);
    _endTimeController.text =
        DateFormat(Constants.dateTimeFormat).format(_filter.endDate);
    _minAmountController.text = _filter.minAmount.toString();
    _maxAmountController.text = _filter.maxAmount.toString();

    switch (_filter.type) {
      case null:
        _transactionType = TransactionType.all;
        break;
      case 'credit':
        _transactionType = TransactionType.credit;
        break;
      case 'debit':
        _transactionType = TransactionType.debit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Text(
            'Filters',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity(vertical: .2),
              ),
              segments: const <ButtonSegment<TransactionType>>[
                ButtonSegment<TransactionType>(
                  value: TransactionType.all,
                  label: Text("All"),
                  icon: Icon(Icons.list),
                ),
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
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(),
              labelText: 'Start Date',
            ),
            controller: _startTimeController,
            readOnly: true,
            onTap: () => _showDatePicker(true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(),
              labelText: 'End Date',
            ),
            controller: _endTimeController,
            readOnly: true,
            onTap: () => _showDatePicker(true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _minAmountController,
            decoration: InputDecoration(
              prefixIcon: _getAmountPrefixIcon(),
              border: const OutlineInputBorder(),
              hintText: 'Amount',
              labelText: 'Min amount',
            ),
            keyboardType: const TextInputType.numberWithOptions(),
            validator: (value) {
              double? amount = double.tryParse(value!);
              if (amount != null) {
                return null;
              }

              return 'Please enter a valid number';
            },
            onChanged: (value) => _filter.minAmount = double.tryParse(value)!,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxAmountController,
            decoration: InputDecoration(
              prefixIcon: _getAmountPrefixIcon(),
              border: const OutlineInputBorder(),
              hintText: 'Amount',
              labelText: 'Max amount',
            ),
            keyboardType: const TextInputType.numberWithOptions(),
            validator: (value) {
              double? amount = double.tryParse(value!);
              if (amount != null) {
                return null;
              }

              return 'Please enter a valid number';
            },
            onChanged: (value) => _filter.maxAmount = double.tryParse(value)!,
          ),
          const SizedBox(height: 32),
          Center(
            child: FilledButton(
              onPressed: () => _applyFilter(),
              child: const Text('Apply Filter'),
            ),
          ),
        ],
      ),
    );
  }

  _showDatePicker(bool isStartDate) async {
    DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      initialDate: isStartDate ? _filter.startDate : _filter.endDate,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 2 / 3,
        maxWidth: MediaQuery.of(context).size.width / 2,
      ),
    );

    setState(() {
      if (isStartDate) {
        _filter.startDate = dateTime ?? _filter.startDate;
        _startTimeController.text =
            DateFormat(Constants.dateTimeFormat).format(_filter.startDate);
      } else {
        _filter.endDate = dateTime ?? _filter.endDate;
        _endTimeController.text =
            DateFormat(Constants.dateTimeFormat).format(_filter.endDate);
      }
    });
  }

  _getAmountPrefixIcon() {
    if (_applicationCurrency == null ||
        _applicationCurrency!.symbol.length > 2) {
      return const Icon(Icons.money_outlined);
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Text(
          _applicationCurrency!.symbol,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  _applyFilter() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    switch (_transactionType) {
      case TransactionType.all:
        _filter.type = null;
        break;
      case TransactionType.debit:
        _filter.type = 'debit';
        break;
      case TransactionType.credit:
        _filter.type = 'credit';
      default:
        _filter.type = null;
    }

    Navigator.of(context).pop(_filter);
  }
}

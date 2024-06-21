import 'dart:convert';

import 'package:currency_picker/currency_picker.dart';
import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/account_transaction.dart';
import 'package:expenses_app/models/categories.dart';
import 'package:expenses_app/models/transaction_categories.dart';
import 'package:expenses_app/screens/components/category_form.dart';
import 'package:expenses_app/utils/constants.dart';
import 'package:expenses_app/utils/utils.dart';
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
  List<Category> _categories = [];
  Category? _category;
  TransactionCategory? _transactionCategory;
  bool _isCategoriesLoading = true;
  Currency? _applicationCurrency;

  @override
  void initState() {
    super.initState();
    _accountTransaction = widget.accountTransaction;
    _isFullForm = widget.isFullForm;

    DbHelper.instance
        .getSetting(Constants.settingApplicationCurrency)
        .then((setting) {
      setState(() {
        _applicationCurrency = Currency.from(json: jsonDecode(setting!.value));
      });
    });

    // If we have amount entered in the dialog/bottom sheet, populate the same
    // in the full form
    if (tempAmount.isNotEmpty && _isFullForm) {
      _amountController.text = tempAmount;
    }

    // Clear the amount field if the form is reopened from dialog/bottom sheet
    if (!_isFullForm) {
      tempAmount = '';
      _isCategoriesLoading = false;
    }

    _getCategories();

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
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: SegmentedButton<TransactionType>(
              showSelectedIcon: false,
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
          ),
          if (_isFullForm) const SizedBox(height: 20),
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
          const SizedBox(height: 20),
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              prefixIcon: _getAmountPrefixIcon(),
              border: const OutlineInputBorder(),
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
          if (_isFullForm) const SizedBox(height: 20),
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
          if (_isFullForm) const SizedBox(height: 20),
          if (_isFullForm)
            Center(
              child: _getCategoryDropdown(),
            ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
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
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  _saveTransaction() async {
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

      await DbHelper.instance.updateTransaction(_accountTransaction!);
      await DbHelper.instance.updateTransactionCategory(
        _transactionCategory!.id,
        _accountTransaction!.id,
        _category!.id,
      );
    } else {
      int transactionId = await DbHelper.instance.createTransaction(
        1,
        _transactionType == TransactionType.credit ? 'Income' : 'Expense',
        null,
        (amount * 100).floor(),
        _transactionType == TransactionType.credit ? 'credit' : 'debit',
        _transactionTime,
      );

      await DbHelper.instance.createTransactionCategory(
        transactionId,
        _category!.id,
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 2 / 3,
        maxWidth: MediaQuery.of(context).size.width / 2,
      ),
    );

    setState(() {
      _transactionTime = dateTime ?? _transactionTime;
      _transactionTimeController.text =
          DateFormat(Constants.dateTimeFormat).format(_transactionTime);
    });
  }

  _getCategories() async {
    _categories = await DbHelper.instance.getCategories();

    if (_accountTransaction != null) {
      _transactionCategory = await DbHelper.instance
          .getTransactionCategory(_accountTransaction!.id);

      if (_transactionCategory != null) {
        _category = await DbHelper.instance
            .getCategory(_transactionCategory!.categoryId);
      } else {
        // FIXME: Should set the category to default one, instead of hardcoding
        // to 1
        int transactionCategoryId =
            await DbHelper.instance.createTransactionCategory(
          _accountTransaction!.id,
          1,
        );

        _transactionCategory = await DbHelper.instance
            .getTransactionCategory(transactionCategoryId);
      }
    }

    // FIXME: Should set the category to default one, instead of hardcoding
    // to 1
    if (_transactionCategory == null) {
      _category = _categories.where((item) => item.id == 1).first;
    }

    setState(() {
      _isCategoriesLoading = false;
    });
  }

  _getCategoryDropdown() {
    if (_isCategoriesLoading) {
      return Container();
    }

    return DropdownButtonFormField<Category>(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
        labelText: 'Category',
      ),
      items: _getCategoryItems(),
      onChanged: (category) => _onCategoryUpdated(category),
      value: _category,
    );
  }

  List<DropdownMenuItem<Category>> _getCategoryItems() {
    List<DropdownMenuItem<Category>> items = [];
    for (Category category in _categories) {
      items.add(
        DropdownMenuItem<Category>(
          value: category,
          child: Text(category.title),
        ),
      );
    }

    // Show dropdown to add new category
    Category category = Category(id: -1, title: "Add new category");
    items.add(
      DropdownMenuItem<Category>(
        value: category,
        child: Text(category.title),
      ),
    );

    return items;
  }

  _onCategoryUpdated(Category? category) async {
    if (category != null && category.id == -1) {
      Category? backup = _category;

      setState(() {
        _category = category;
      });

      Category? newCategory;
      if (Utils.isLargeScreen(context)) {
        newCategory = await showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: Container(
                margin: const EdgeInsets.all(16),
                width: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.height * 3 / 4,
                child: const CategoryForm(
                  category: null,
                ),
              ),
            );
          },
        );
      } else {
        newCategory = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Container(
              height: MediaQuery.of(context).size.height * 3 / 4,
              margin: const EdgeInsets.all(16),
              child: const CategoryForm(
                category: null,
              ),
            );
          },
        );
      }

      if (newCategory == null) {
        setState(() {
          _category = backup;
        });
        return;
      }

      setState(() {
        _categories.add(newCategory!);

        _category = newCategory;
      });
      return;
    }

    if (category != null) {
      setState(() {
        _category = category;
      });
    }
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
}

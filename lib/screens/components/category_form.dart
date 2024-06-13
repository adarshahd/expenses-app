import 'dart:math';

import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/categories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CategoryForm extends StatefulWidget {
  final Category? category;

  const CategoryForm({super.key, this.category});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final GlobalKey<FormState> _categoryFormKey = GlobalKey();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;
  int _categoryColor = (Random().nextDouble() * 0xFFFFFF).toInt();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _categoryFormKey,
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Text(
            'Create new category',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
              hintText: 'Category Title',
              labelText: 'Category Title',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title for category';
              }

              return null;
            },
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Category Description',
            ),
            maxLines: 8,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 20),
          ListTile(
            title: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: Color(_categoryColor).withOpacity(0.6)),
                ),
                const SizedBox(width: 16),
                const Text('Chose color')
              ],
            ),
            onTap: () => _showColorPicker(),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              icon: _getSaveIcon(),
              onPressed: () {
                bool isFormValid = _categoryFormKey.currentState!.validate();
                if (isFormValid) {
                  _saveCategory();
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

  _saveCategory() async {
    setState(() {
      _isSaving = true;
    });

    if (!_categoryFormKey.currentState!.validate()) {
      return;
    }

    int categoryId = await DbHelper.instance.createCategory(
      _titleController.text.toString(),
      _descriptionController.text.toString(),
      _categoryColor,
    );
    Category? category = await DbHelper.instance.getCategory(categoryId);

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop(category);
  }

  _getSaveIcon() {
    if (_isSaving) {
      return const CircularProgressIndicator();
    }
    return const Icon(Icons.check_circle_outline);
  }

  _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chose category color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: Color(_categoryColor).withOpacity(0.5),
            onColorChanged: (newColor) {
              setState(() {
                _categoryColor = int.parse('0xff${newColor.toHexString()}');
              });
            },
          ),
        ),
        actions: [
          ElevatedButton.icon(
            label: const Text("Select"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

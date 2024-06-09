import 'package:expenses_app/db/db_helper.dart';
import 'package:expenses_app/models/categories.dart';
import 'package:flutter/material.dart';

class CategoryForm extends StatefulWidget {
  final Category? category;

  const CategoryForm({super.key, this.category});

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  late final Category? _category;
  final GlobalKey<FormState> _categoryFormKey = GlobalKey();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _category = widget.category;
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
}

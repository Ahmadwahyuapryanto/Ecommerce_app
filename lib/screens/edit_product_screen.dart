// lib/screens/edit_product_screen.dart

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product? product;

  const EditProductScreen({super.key, this.product});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController =
        TextEditingController(text: widget.product?.price.toString() ?? '');
    _categoryController =
        TextEditingController(text: widget.product?.category ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _imageController =
        TextEditingController(text: widget.product?.images.join(', ') ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) =>
                value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Harga tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
                validator: (value) =>
                value!.isEmpty ? 'Kategori tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                    labelText: 'URL Gambar (pisahkan dengan koma)'),
                validator: (value) =>
                value!.isEmpty ? 'URL Gambar tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      // Buat objek Product dengan benar
      final newProduct = Product(
        id: widget.product?.id ?? '', // Gunakan ID yang ada jika sedang mengedit
        name: _nameController.text,
        price: double.parse(_priceController.text),
        category: _categoryController.text,
        description: _descriptionController.text,
        images: _imageController.text.split(',').map((e) => e.trim()).toList(),
        rating: widget.product?.rating ?? Rating(rate: 0, count: 0),
      );

      if (widget.product == null) {
        // Jika produk baru, panggil addProduct
        _productService.addProduct(newProduct);
      } else {
        // Jika mengedit produk, panggil updateProduct
        _productService.updateProduct(newProduct);
      }
      Navigator.of(context).pop();
    }
  }
}
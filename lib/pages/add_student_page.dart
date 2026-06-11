import 'package:flutter/material.dart';
import '../main.dart';

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  List<dynamic> batches = [];
  int? selectedBatchId;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadBatches();
  }

  Future<void> loadBatches() async {
    try {
      final data = await supabase.from('batches').select().order('id');

      if (!mounted) return;

      setState(() {
        batches = data;
      });
    } catch (e) {
      showMessage('Failed to load batches: $e');
    }
  }

  Future<void> addStudent() async {
    final studentName = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (studentName.isEmpty) {
      showMessage('Please enter student name');
      return;
    }

    if (selectedBatchId == null) {
      showMessage('Please select a batch');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await supabase.from('students').insert({
        'student_name': studentName,
        'phone': phone,
        'batch_id': selectedBatchId,
      });

      nameController.clear();
      phoneController.clear();

      setState(() {
        selectedBatchId = null;
      });

      showMessage('Student added successfully');
    } catch (e) {
      showMessage('Failed to add student: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              value: selectedBatchId,
              decoration: const InputDecoration(
                labelText: 'Select Batch',
                prefixIcon: Icon(Icons.groups),
                border: OutlineInputBorder(),
              ),
              items: batches.map<DropdownMenuItem<int>>((batch) {
                return DropdownMenuItem<int>(
                  value: batch['id'] as int,
                  child: Text(batch['name'] ?? ''),
                );
              }).toList(),
              onChanged: loading
                  ? null
                  : (value) {
                      setState(() {
                        selectedBatchId = value;
                      });
                    },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loading ? null : addStudent,
                icon: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(loading ? 'Adding...' : 'Add Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
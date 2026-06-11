import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../main.dart';

class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});

  @override
  State<AttendanceReportPage> createState() => _AttendanceReportPageState();
}

class _AttendanceReportPageState extends State<AttendanceReportPage> {
  List<dynamic> batches = [];
  int? selectedBatchId;
  DateTime selectedDate = DateTime.now();
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
      setState(() => batches = data);
    } catch (e) {
      showMessage('Failed to load batches: $e');
    }
  }

  Future<void> downloadPdf() async {
    if (selectedBatchId == null) {
      showMessage('Please select a batch first');
      return;
    }

    setState(() => loading = true);

    try {
      final date = DateFormat('yyyy-MM-dd').format(selectedDate);

      final data = await supabase
          .from('attendance')
          .select('date, status, students(student_name, phone), batches(name)')
          .eq('batch_id', selectedBatchId!)
          .eq('date', date);

      if (data.isEmpty) {
        showMessage('No attendance found for this batch and date');
        return;
      }

      final pdf = pw.Document();
      final batchName = data.first['batches']?['name'] ?? 'Batch';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Coaching Attendance Report',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text('Batch: $batchName'),
                pw.Text('Date: $date'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: [
                    'SL',
                    'Student Name',
                    'Phone',
                    'Status',
                  ],
                  data: List.generate(data.length, (index) {
                    final item = data[index];
                    final student = item['students'];

                    return [
                      '${index + 1}',
                      student?['student_name'] ?? '',
                      student?['phone'] ?? '',
                      item['status'] ?? '',
                    ];
                  }),
                ),
              ],
            );
          },
        ),
      );

      final Uint8List bytes = await pdf.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'attendance_$date.pdf',
      );

      showMessage('PDF generated successfully');
    } catch (e) {
      showMessage('Download failed: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                      setState(() => selectedBatchId = value);
                    },
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              title: Text('Date: $dateText'),
              trailing: const Icon(Icons.calendar_month),
              onTap: loading ? null : pickDate,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loading ? null : downloadPdf,
                icon: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  loading ? 'Generating...' : 'Download PDF',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
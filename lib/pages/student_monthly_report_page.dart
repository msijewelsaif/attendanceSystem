import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../main.dart';

class StudentMonthlyReportPage extends StatefulWidget {
  const StudentMonthlyReportPage({super.key});

  @override
  State<StudentMonthlyReportPage> createState() =>
      _StudentMonthlyReportPageState();
}

class _StudentMonthlyReportPageState extends State<StudentMonthlyReportPage> {
  final searchController = TextEditingController();

  List<dynamic> students = [];
  List<dynamic> attendanceList = [];

  Map<String, dynamic>? selectedStudent;

  bool searching = false;
  bool loadingReport = false;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  int presentCount = 0;
  int absentCount = 0;
  int lateCount = 0;

  Future<void> searchStudents() async {
    final query = searchController.text.trim();

    if (query.isEmpty) {
      showMessage('Please enter student name or phone');
      return;
    }

    setState(() {
      searching = true;
      students = [];
      selectedStudent = null;
      attendanceList = [];
    });

    try {
      final data = await supabase
          .from('students')
          .select('id, student_name, phone, batch_id, batches(name)')
          .or('student_name.ilike.%$query%,phone.ilike.%$query%')
          .order('student_name');

      setState(() {
        students = data;
      });
    } catch (e) {
      showMessage('Search failed: $e');
    } finally {
      setState(() {
        searching = false;
      });
    }
  }

  Future<void> loadMonthlyAttendance(Map<String, dynamic> student) async {
    setState(() {
      selectedStudent = student;
      loadingReport = true;
      attendanceList = [];
      presentCount = 0;
      absentCount = 0;
      lateCount = 0;
    });

    try {
      final startDate = DateTime(selectedYear, selectedMonth, 1);
      final endDate = DateTime(selectedYear, selectedMonth + 1, 1);

      final start = DateFormat('yyyy-MM-dd').format(startDate);
      final end = DateFormat('yyyy-MM-dd').format(endDate);

      final data = await supabase
          .from('attendance')
          .select('date, status')
          .eq('student_id', student['id'])
          .gte('date', start)
          .lt('date', end)
          .order('date');

      int p = 0;
      int a = 0;
      int l = 0;

      for (final item in data) {
        if (item['status'] == 'Present') {
          p++;
        } else if (item['status'] == 'Absent') {
          a++;
        } else if (item['status'] == 'Late') {
          l++;
        }
      }

      setState(() {
        attendanceList = data;
        presentCount = p;
        absentCount = a;
        lateCount = l;
      });
    } catch (e) {
      showMessage('Failed to load attendance: $e');
    } finally {
      setState(() {
        loadingReport = false;
      });
    }
  }

  Future<Uint8List> createPdf() async {
    final pdf = pw.Document();

    final studentName = selectedStudent?['student_name'] ?? '';
    final phone = selectedStudent?['phone'] ?? '';
    final batchName = selectedStudent?['batches']?['name'] ?? '';
    final monthName = DateFormat('MMMM').format(
      DateTime(selectedYear, selectedMonth),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                'Student Monthly Attendance Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text('Student Name: $studentName'),
            pw.Text('Phone: $phone'),
            pw.Text('Batch: $batchName'),
            pw.Text('Month: $monthName $selectedYear'),

            pw.SizedBox(height: 15),

            pw.Table.fromTextArray(
              headers: ['Present', 'Absent', 'Late', 'Total Records'],
              data: [
                [
                  presentCount.toString(),
                  absentCount.toString(),
                  lateCount.toString(),
                  attendanceList.length.toString(),
                ]
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              'Attendance Details',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              headers: ['SL', 'Date', 'Status'],
              data: List.generate(attendanceList.length, (index) {
                final item = attendanceList[index];

                return [
                  '${index + 1}',
                  item['date'] ?? '',
                  item['status'] ?? '',
                ];
              }),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> downloadPdf() async {
    if (selectedStudent == null) {
      showMessage('Please select a student first');
      return;
    }

    if (attendanceList.isEmpty) {
      showMessage('No attendance found for this month');
      return;
    }

    final studentName = selectedStudent?['student_name'] ?? 'student';
    final monthName = DateFormat('MMMM').format(
      DateTime(selectedYear, selectedMonth),
    );

    final pdfBytes = await createPdf();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${studentName}_attendance_${monthName}_$selectedYear.pdf',
    );
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget summaryCard(String title, int value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (index) => index + 1);
    final years = List.generate(6, (index) => DateTime.now().year - index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Monthly Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by student name or phone',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: searching ? null : searchStudents,
                ),
              ),
              onSubmitted: (_) => searchStudents(),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                    ),
                    items: months.map((month) {
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(
                          DateFormat('MMMM').format(DateTime(2024, month)),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMonth = value!;
                      });

                      if (selectedStudent != null) {
                        loadMonthlyAttendance(selectedStudent!);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    items: years.map((year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value!;
                      });

                      if (selectedStudent != null) {
                        loadMonthlyAttendance(selectedStudent!);
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (searching) const CircularProgressIndicator(),

            if (students.isNotEmpty)
              Card(
                child: Column(
                  children: students.map((student) {
                    final batchName = student['batches']?['name'] ?? '';

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(student['student_name'] ?? ''),
                      subtitle: Text(
                        'Phone: ${student['phone'] ?? ''} | Batch: $batchName',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => loadMonthlyAttendance(student),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 15),

            if (selectedStudent != null)
              Card(
                elevation: 3,
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.school),
                  ),
                  title: Text(selectedStudent?['student_name'] ?? ''),
                  subtitle: Text(
                    'Batch: ${selectedStudent?['batches']?['name'] ?? ''}',
                  ),
                ),
              ),

            if (loadingReport)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),

            if (!loadingReport && selectedStudent != null) ...[
              Row(
                children: [
                  summaryCard('Present', presentCount, Icons.check_circle),
                  summaryCard('Absent', absentCount, Icons.cancel),
                  summaryCard('Late', lateCount, Icons.access_time),
                ],
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: downloadPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download Student Monthly PDF'),
                ),
              ),

              const SizedBox(height: 15),

              Card(
                child: Column(
                  children: [
                    const ListTile(
                      title: Text(
                        'Attendance Details',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (attendanceList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No attendance found for this month'),
                      )
                    else
                      ...attendanceList.map((item) {
                        return ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(item['date'] ?? ''),
                          trailing: Text(
                            item['status'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
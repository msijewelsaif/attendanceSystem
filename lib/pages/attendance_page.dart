import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';

class AttendancePage extends StatefulWidget {
  final int batchId;
  final String batchName;

  const AttendancePage({
    super.key,
    required this.batchId,
    required this.batchName,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  List<dynamic> students = [];
  Map<int, String> attendanceStatus = {};

  bool loading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadStudents();
  }

  Future<void> loadStudents() async {
    setState(() {
      loading = true;
    });

    try {
      final data = await supabase
          .from('students')
          .select()
          .eq('batch_id', widget.batchId)
          .order('id');

      if (!mounted) return;

      setState(() {
        students = data;
        attendanceStatus.clear();

        for (final student in students) {
          attendanceStatus[student['id'] as int] = 'Present';
        }
      });
    } catch (e) {
      showMessage('Failed to load students: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> saveAttendance() async {
    if (students.isEmpty) {
      showMessage('No students found');
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('User not logged in');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final records = students.map((student) {
        final studentId = student['id'] as int;

        return {
          'student_id': studentId,
          'batch_id': widget.batchId,
          'teacher_id': user.id,
          'date': today,
          'status': attendanceStatus[studentId] ?? 'Present',
        };
      }).toList();

      await supabase.from('attendance').insert(records);

      showMessage('Attendance saved successfully');
    } catch (e) {
      showMessage('Failed to save attendance: $e');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
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

  Widget statusChip(String status) {
    Color color;

    if (status == 'Present') {
      color = Colors.green;
    } else if (status == 'Absent') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return Text(
      status,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batchName),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline, size: 60),
                      const SizedBox(height: 10),
                      const Text('No students found in this batch'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: loadStudents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blue.withOpacity(0.08),
                      ),
                      child: Text(
                        'Date: $today | Total Students: ${students.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final studentId = student['id'] as int;
                          final selectedStatus =
                              attendanceStatus[studentId] ?? 'Present';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(
                                student['student_name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                student['phone'] ?? 'No phone number',
                              ),
                              trailing: DropdownButton<String>(
                                value: selectedStatus,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Present',
                                    child: Text('Present'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Absent',
                                    child: Text('Absent'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Late',
                                    child: Text('Late'),
                                  ),
                                ],
                                onChanged: saving
                                    ? null
                                    : (value) {
                                        if (value == null) return;

                                        setState(() {
                                          attendanceStatus[studentId] = value;
                                        });
                                      },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: saving ? null : saveAttendance,
                          icon: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            saving ? 'Saving...' : 'Save Attendance',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
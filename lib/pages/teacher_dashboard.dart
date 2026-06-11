import 'package:flutter/material.dart';
import '../main.dart';
import 'attendance_page.dart';
import 'attendance_report_page.dart';
import 'login_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List batches = [];

  Future<void> loadBatches() async {
    final data = await supabase.from('batches').select().order('id');
    setState(() => batches = data);
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    loadBatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select Batch for Attendance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...batches.map((batch) {
            return Card(
              child: ListTile(
                title: Text(batch['name']),
                leading: const Icon(Icons.groups),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendancePage(
                        batchId: batch['id'],
                        batchName: batch['name'],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceReportPage()),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Attendance Report'),
          )
        ],
      ),
    );
  }
}
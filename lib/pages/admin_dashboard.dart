import 'package:flutter/material.dart';

import '../main.dart';
import 'add_student_page.dart';
import 'add_teacher_page.dart';
import 'attendance_report_page.dart';
import 'login_page.dart';
import 'student_monthly_report_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String adminName = "Admin";
  int totalStudents = 0;
  int totalTeachers = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final profile = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          adminName = profile['name'] ?? 'Admin';
        }
      }

      final students =
          await supabase.from('students').select('id');

      final teachers = await supabase
          .from('users')
          .select('id')
          .eq('role', 'teacher');

      if (!mounted) return;

      setState(() {
        totalStudents = students.length;
        totalTeachers = teachers.length;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Widget dashboardCard({
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
      ),
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 35),
              const SizedBox(height: 10),
              Text(
                value,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: ListTile(
                leading: const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.admin_panel_settings),
                ),
                title: Text(
                  adminName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text("Administrator"),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                statCard(
                  "Students",
                  totalStudents.toString(),
                  Icons.school,
                ),
                statCard(
                  "Teachers",
                  totalTeachers.toString(),
                  Icons.people,
                ),
              ],
            ),

            const SizedBox(height: 20),

            dashboardCard(
              icon: Icons.person_add,
              title: "Add Teacher",
              page: const AddTeacherPage(),
            ),

            dashboardCard(
              icon: Icons.school,
              title: "Add Student",
              page: const AddStudentPage(),
            ),

            dashboardCard(
              icon: Icons.download,
              title: "Attendance Reports",
              page: const AttendanceReportPage(),
            ),

            dashboardCard(
              icon: Icons.person_search,
              title: "Student Monthly Report",
              page: const StudentMonthlyReportPage(),
            ),
          ],
        ),
      ),
    );
  }
}
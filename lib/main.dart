import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/login_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://smftafkpxdvncbzlvdpw.supabase.co',
    anonKey: 'sb_publishable_c2oStv4oyil6sc61PYD3xA_3UZoU-m4',
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<String?> getUserRole() async {
    final authUser = supabase.auth.currentUser;

    if (authUser == null) {
      return null;
    }

    try {
      final data = await supabase
          .from('users')
          .select('role')
          .eq('id', authUser.id)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return data['role']?.toString();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coaching Attendance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final role = snapshot.data;

          if (role == 'admin') {
            return const AdminDashboard();
          }

          if (role == 'teacher') {
            return const TeacherDashboard();
          }

          return const LoginPage();
        },
      ),
    );
  }
}
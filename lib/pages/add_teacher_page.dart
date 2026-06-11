import 'package:flutter/material.dart';
import '../main.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({super.key});

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> addTeacher() async {
    final teacherName = nameController.text.trim();
    final teacherEmail = emailController.text.trim();
    final teacherPassword = passwordController.text.trim();

    if (teacherName.isEmpty) {
      showMessage('Please enter teacher name');
      return;
    }

    if (teacherEmail.isEmpty) {
      showMessage('Please enter teacher email');
      return;
    }

    if (teacherPassword.length < 6) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await supabase.auth.signUp(
        email: teacherEmail,
        password: teacherPassword,
      );

      final user = response.user;

      if (user == null) {
        throw 'Teacher account creation failed';
      }

      await supabase.from('users').insert({
        'id': user.id,
        'name': teacherName,
        'email': teacherEmail,
        'role': 'teacher',
      });

      nameController.clear();
      emailController.clear();
      passwordController.clear();

      showMessage('Teacher added successfully');
    } catch (e) {
      showMessage('Failed to add teacher: $e');
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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Teacher Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Teacher Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loading ? null : addTeacher,
                icon: loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(loading ? 'Adding...' : 'Add Teacher'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
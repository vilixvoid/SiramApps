import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siram/viewmodel/LoginViewModel.dart';
import 'package:siram/main.dart';
import 'package:siram/view/screens/home/HomeScreen.dart';
import 'package:siram/view/navigation/NavigationBottom.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();

    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {

    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final viewModel = context.read<LoginViewModel>();

    try {
      final user = await viewModel.login(username, password);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

      Future.microtask(() {
        messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text("Login berhasil!"),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e, s) {

      messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    // ❗ PENTING: JANGAN watch seluruh screen
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Center(
              child: Image.asset('assets/images/vector_login.png', height: 250),
            ),

            const SizedBox(height: 40),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat Datang\ndi SIRAM",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Masukkan username anda",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFB),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isObscure,
                    decoration: InputDecoration(
                      hintText: "Masukkan password anda",
                      filled: true,
                      fillColor: const Color(0xFFF8FAFB),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _isObscure = !_isObscure);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ✅ HANYA BUTTON YANG LISTEN
                  Consumer<LoginViewModel>(
                    builder: (_, viewModel, __) {
                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7BCEF5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: viewModel.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siram/view/screens/auth/LoginScreen.dart';
import 'package:siram/viewmodel/LoginViewModel.dart';
import 'package:siram/viewmodel/ProfileViewModel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProfileViewModel>().fetchProfile();
    });
  }

  Future<void> _handleLogout() async {
    await context.read<LoginViewModel>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: Consumer<ProfileViewModel>(
        builder: (_, viewModel, __) {
          return Stack(
            children: [
              Container(
                height: 350,
                decoration: const BoxDecoration(
                  color: Color(0xFF7BCEF5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Profil Saya",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: _handleLogout,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                    ),

                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF7BCEF5),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Nama
                    if (viewModel.isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      Text(
                        viewModel.profile?.name ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    const SizedBox(height: 4),

                    Text(
                      viewModel.profile?.username != null
                          ? '@${viewModel.profile!.username}'
                          : '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Info cards
                    Expanded(
                      child: viewModel.state == ProfileState.error
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    viewModel.errorMessage,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => viewModel.fetchProfile(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7BCEF5),
                                    ),
                                    child: const Text(
                                      'Coba Lagi',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  _buildInfoCard(
                                    icon: Icons.badge_outlined,
                                    label: 'Nama Lengkap',
                                    value: viewModel.profile?.name ?? '-',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoCard(
                                    icon: Icons.person_outline,
                                    label: 'Username',
                                    value: viewModel.profile?.username ?? '-',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoCard(
                                    icon: Icons.email_outlined,
                                    label: 'Email',
                                    value: viewModel.profile?.email ?? '-',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoCard(
                                    icon: Icons.phone_outlined,
                                    label: 'Nomor Telepon',
                                    value: viewModel.profile?.phone ?? '-',
                                  ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF7BCEF5).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF7BCEF5), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

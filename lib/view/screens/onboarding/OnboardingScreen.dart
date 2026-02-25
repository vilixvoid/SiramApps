import 'package:flutter/material.dart';
import 'package:siram/view/screens/auth/LoginScreen.dart';

// ================= MODEL =================
class OnboardingContent {
  final String image;
  final String title;
  final String description;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}

// ================= SCREEN =================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;
  late PageController _controller;

  final List<OnboardingContent> contents = [
    OnboardingContent(
      image: 'assets/images/vector_onboarding1.png',
      title: "Monitoring\nSistem Air Terpadu.",
      description:
          "Pantau kondisi sistem air secara real-time dalam satu dashboard terintegrasi.",
    ),
    OnboardingContent(
      image: 'assets/images/vector_onboarding2.png',
      title: "Analisis cepat & akurat.",
      description:
          "Dapatkan insight performa sistem untuk membantu pengambilan keputusan maintenance.",
    ),
    OnboardingContent(
      image: 'assets/images/vector_onboarding3.png',
      title: "Maintenance Lebih Efisien.",
      description:
          "Kelola jadwal dan tindakan perawatan dengan mudah dan terorganisir.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void nextPage() {
   if (currentIndex == contents.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // ================= SLIDER =================
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: contents.length,
                onPageChanged: (index) {
                  setState(() => currentIndex = index);
                },
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          contents[i].image,
                          height: 280,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          contents[i].title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          contents[i].description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ================= DOTS =================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                contents.length,
                (index) => buildDot(index),
              ),
            ),

            const SizedBox(height: 30),

            // ================= BUTTON =================
            Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BCEF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  currentIndex == contents.length - 1
                      ? "Get Started"
                      : "Next",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= DOT WIDGET =================
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 10,
      width: currentIndex == index ? 28 : 10,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: currentIndex == index
            ? const Color(0xFF7BCEF5)
            : const Color(0xFF7BCEF5).withOpacity(0.3),
      ),
    );
  }
}
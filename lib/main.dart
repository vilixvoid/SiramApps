import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:siram/core/services/ApiServices.dart';
import 'package:siram/data/datasources/remote/HomeRemoteDataSource.dart';
import 'package:siram/data/repositories/AuthRepository.dart';
import 'package:siram/data/repositories/HomeRepository.dart';
import 'package:siram/viewmodel/HomeViewModel.dart';
import 'package:siram/viewmodel/LoginViewModel.dart';
import 'view/screens/onboarding/SplashScreen.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // ✅ Load token dari storage sebelum app start
  final apiService = ApiService();
  await apiService.loadToken();

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginViewModel>(
          create: (_) => LoginViewModel(AuthRepository(apiService)),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (_) =>
              HomeViewModel(HomeRepository(HomeRemoteDatasource(apiService))),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Siram App',
        scaffoldMessengerKey: messengerKey,
        home: const SplashScreen(),
      ),
    );
  }
}

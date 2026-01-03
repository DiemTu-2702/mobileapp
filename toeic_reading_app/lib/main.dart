import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/home/presentation/pages/main_screen.dart';
import 'features/test_reading/presentation/bloc/test_list_bloc.dart';
import 'core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent())),
        BlocProvider(create: (_) => di.sl<TestListBloc>()),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'TOEIC Reading App',
            debugShowCheckedModeBanner: false,

            // --- THEME SÁNG ---
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.grey[100],
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.white), // Icon quay lại màu trắng
              ),
              cardColor: Colors.white,
            ),

            // --- THEME TỐI (Đã chỉnh sửa AppBar) ---
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Color(0xFF1F1F1F), // Màu xám đen thay vì xanh
                foregroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              cardColor: const Color(0xFF2C2C2C),
              dialogBackgroundColor: const Color(0xFF2C2C2C),
              textTheme: const TextTheme(
                bodyMedium: TextStyle(color: Colors.white),
                titleMedium: TextStyle(color: Colors.white),
              ),
            ),

            themeMode: themeMode,
            home: const AppRouter(),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return const MainScreen();
      },
    );
  }
}
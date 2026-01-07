import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- AUTH FEATURE ---
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';

// --- TEST FEATURE ---
import '../../features/test_reading/domain/usecases/get_available_tests_usecase.dart';
import '../../features/test_reading/domain/usecases/get_test_details_usecase.dart';
import '../../features/test_reading/domain/usecases/submit_test_usecase.dart';
import '../../features/test_reading/domain/repositories/test_repository.dart';
import '../../features/test_reading/data/repositories/test_repository_impl.dart';
import '../../features/test_reading/data/datasources/test_remote_datasource.dart';
import '../../features/test_reading/presentation/bloc/test_detail_bloc.dart';
import '../../features/test_reading/presentation/bloc/test_list_bloc.dart';
// ---AI_TUTOR FEATURE---
import '../../features/ai_tutor/data/ai_remote_datasource.dart';
import '../../features/ai_tutor/presentation/bloc/ai_bloc.dart';

final sl = GetIt.instance; // sl là viết tắt của service locator

Future<void> init() async {
  // --- 0. External Dependencies (Firebase Instances) ---
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);


  // 1. Presentation
  sl.registerFactory(() => AuthBloc(
    signInUseCase: sl(),
    signUpUseCase: sl(),
    checkAuthStatusUseCase: sl(),
  ));

  sl.registerFactory(() => TestListBloc(getAvailableTestsUseCase: sl()));
  sl.registerFactory(() => TestDetailBloc(
    getTestDetailsUseCase: sl(),
    submitTestUseCase: sl(),
  ));
// --- AI TUTOR (MỚI) ---
  sl.registerLazySingleton(() => AiRemoteDataSource());
  // 2. Use Cases - Auth
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));       // <<< THÊM: Đăng ký SignUpUseCase
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));

  // 2. Use Cases - Test

  sl.registerLazySingleton(() => GetAvailableTestsUseCase(sl()));
  sl.registerLazySingleton(() => GetTestDetailsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitTestUseCase(sl()));
 // 2. tutor Bloc
  sl.registerFactory(() => AiBloc(dataSource: sl()));

  // 3. Repositories

  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<TestRepository>(() => TestRepositoryImpl(remoteDataSource: sl()));

  // 4. Data Sources (Cập nhật để sử dụng Firebase instances)

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(
      authClient: sl(),
      firestore: sl(),
    ),
  );

  sl.registerLazySingleton<TestRemoteDataSource>(
        () => TestRemoteDataSourceImpl(firestore: sl()),
  );
}
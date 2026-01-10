import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/datasource/auth_remote_datasource.dart';
import 'data/datasource/fake_auth_datasource.dart';
import 'data/auth_repository_impl.dart';
import 'domain/auth_repository.dart';


/// Auth Dependency Injection
/// ------------------------------------------------------------
/// Auth için tüm bağımlılıkların bağlandığı tek yer.
///
/// ⚠️ GERÇEK SWAP NOKTASI:
/// FakeAuthDataSource → N8nAuthDataSource
///
/// Feature / UI tarafında tek satır değişmez.


final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FakeAuthDataSource(ref: ref); // 🔁 N8nAuthDataSource()
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

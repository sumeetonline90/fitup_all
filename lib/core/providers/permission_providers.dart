import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/injection.dart';
import '../../services/permission_service.dart';

part 'permission_providers.g.dart';

@riverpod
PermissionService permissionService(Ref ref) => getIt<PermissionService>();

@riverpod
Future<AppPermissionState> permissionState(Ref ref) async {
  return ref.watch(permissionServiceProvider).getPermissionState();
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/utils/migration_utils.dart';
import 'auth_service.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

/// Authentication wrapper that provides parallel implementation
/// Allows gradual migration from AuthService to AuthBloc
class AuthWrapper extends StatelessWidget {
  final Widget child;
  
  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: MigrationUtils.isFeatureEnabled(MigrationUtils.authBlocEnabled),
      initialData: false,
      builder: (context, snapshot) {
        final useBlocAuth = snapshot.data ?? false;
        
        if (useBlocAuth) {
          return BlocProvider(
            create: (context) => AuthBloc()..add(const AuthInitialize()),
            child: child,
          );
        } else {
          // Use legacy AuthService
          return child;
        }
      },
    );
  }
}

/// Authentication state provider that works with both implementations
class AuthStateProvider extends StatelessWidget {
  final Widget Function(BuildContext context, bool isAuthenticated, String userType) builder;
  
  const AuthStateProvider({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: MigrationUtils.isFeatureEnabled(MigrationUtils.authBlocEnabled),
      initialData: false,
      builder: (context, snapshot) {
        final useBlocAuth = snapshot.data ?? false;
        
        if (useBlocAuth) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isAuthenticated = state is AuthAuthenticated;
              final userType = state is AuthAuthenticated ? state.userType : '';
              return builder(context, isAuthenticated, userType);
            },
          );
        } else {
          // Use legacy AuthService
          return builder(context, AuthService.isLoggedIn, AuthService.currentUserType);
        }
      },
    );
  }
}

/// Authentication actions provider that works with both implementations
class AuthActionsProvider {
  static Future<bool> login(BuildContext context, String email, String password) async {
    final useBlocAuth = await MigrationUtils.isFeatureEnabled(MigrationUtils.authBlocEnabled);

    if (useBlocAuth) {
      if (!context.mounted) return false;
      final authBloc = context.read<AuthBloc>();
      authBloc.add(AuthLogin(email: email, password: password));

      // Wait for authentication result
      await for (final state in authBloc.stream) {
        if (state is AuthAuthenticated) {
          return true;
        } else if (state is AuthError) {
          return false;
        }
      }
      return false;
    } else {
      return await AuthService.login(email, password);
    }
  }
  
  static Future<void> logout(BuildContext context) async {
    final useBlocAuth = await MigrationUtils.isFeatureEnabled(MigrationUtils.authBlocEnabled);

    if (useBlocAuth) {
      if (!context.mounted) return;
      context.read<AuthBloc>().add(const AuthLogout());
    } else {
      await AuthService.logout();
    }
  }
  
  static Future<bool> register(
    BuildContext context, {
    required String email,
    required String password,
    required String name,
    required String userType,
    Map<String, dynamic>? additionalData,
  }) async {
    final useBlocAuth = await MigrationUtils.isFeatureEnabled(MigrationUtils.authBlocEnabled);

    if (useBlocAuth) {
      if (!context.mounted) return false;
      final authBloc = context.read<AuthBloc>();
      authBloc.add(AuthRegister(
        email: email,
        password: password,
        name: name,
        userType: userType,
        additionalData: additionalData,
      ));

      // Wait for registration result
      await for (final state in authBloc.stream) {
        if (state is AuthRegistrationSuccess) {
          return true;
        } else if (state is AuthError) {
          return false;
        }
      }
      return false;
    } else {
      final result = await AuthService.register(
        email: email,
        password: password,
        name: name,
        userType: userType,
        additionalData: additionalData,
      );
      return result.isSuccess;
    }
  }
  
  static String getCurrentUserType(BuildContext context) {
    // Try to get from BLoC first if available
    try {
      final authBloc = context.read<AuthBloc>();
      return authBloc.currentUserType;
    } catch (e) {
      // Fall back to AuthService
      return AuthService.currentUserType;
    }
  }
  
  static String getCurrentUserName(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      return authBloc.currentUserName;
    } catch (e) {
      return AuthService.currentUserName;
    }
  }
  
  static String getCurrentUserId(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      return authBloc.currentUserId;
    } catch (e) {
      return AuthService.currentUserId;
    }
  }
  
  static Map<String, dynamic> getCurrentUserData(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      return authBloc.currentUserData;
    } catch (e) {
      return AuthService.currentUserData;
    }
  }
  
  static bool isAuthenticated(BuildContext context) {
    try {
      final authBloc = context.read<AuthBloc>();
      return authBloc.isAuthenticated;
    } catch (e) {
      return AuthService.isLoggedIn;
    }
  }
}

/// Utility class for migration helpers
class AuthMigrationHelpers {
  /// Enable AuthBloc for testing
  static Future<void> enableAuthBloc() async {
    await MigrationUtils.enableFeature(MigrationUtils.authBlocEnabled);
  }
  
  /// Disable AuthBloc (rollback to AuthService)
  static Future<void> disableAuthBloc() async {
    await MigrationUtils.disableFeature(MigrationUtils.authBlocEnabled);
  }
  
  /// Check if AuthBloc is enabled
  static Future<bool> isAuthBlocEnabled() async {
    return await MigrationUtils.isFeatureEnabled(MigrationUtils.authBlocEnabled);
  }
  
  /// Get authentication status from either implementation
  static Future<Map<String, dynamic>> getAuthStatus() async {
    final useBlocAuth = await isAuthBlocEnabled();
    
    return {
      'implementation': useBlocAuth ? 'AuthBloc' : 'AuthService',
      'isAuthenticated': useBlocAuth ? false : AuthService.isLoggedIn, // BLoC would need context
      'userType': useBlocAuth ? '' : AuthService.currentUserType,
      'userName': useBlocAuth ? '' : AuthService.currentUserName,
      'migrationEnabled': useBlocAuth,
    };
  }
}

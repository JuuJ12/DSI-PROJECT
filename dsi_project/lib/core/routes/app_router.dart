import 'package:dsi_project/core/widgets/splash_wideget.dart';
import 'package:dsi_project/features/auth/screens/login_screen.dart';
import 'package:dsi_project/features/auth/screens/register_screen.dart';
import 'package:dsi_project/features/chatbot/tela_chat_bot.dart';
import 'package:dsi_project/features/crud_atv_fisica/list_atividades_screen.dart';
import 'package:dsi_project/features/home/home_screen.dart';
import 'package:dsi_project/features/mapa_diabetes/map_screen.dart';
import 'package:dsi_project/features/Agendamento.dart';
import 'package:dsi_project/features/Recomendacoes.dart';
import 'package:go_router/go_router.dart';

late GoRouter appRouter;

enum AppRoutes {
  splash,
  login,
  signup,
  chatbot,
  home,
  mealTracker,
  medications,
  settings,
  profilePage,
  changePassword,
  editAccount,
  alarm,
  metrics,
  atividades,
  mapaDiabetesGoogle,
  mapaDiabetes,
}

GoRouter createRouter() {
  return GoRouter(
    // App should open normally on the splash screen. During map testing
    // we temporarily pointed initialLocation to '/mapa-diabetes'. Revert
    // here to the normal startup route.
    initialLocation: '/splash',

    routes: [
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash.name,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoutes.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoutes.signup.name,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: AppRoutes.home.name,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/chatbot',
        name: AppRoutes.chatbot.name,
        builder: (context, state) => ChatbotScreen(),
      ),
      GoRoute(
        path: '/atividades',
        name: AppRoutes.atividades.name,
        builder: (context, state) => const ListAtividadesScreen(),
      ),
      // Legacy Google Maps route removed after migration to flutter_map.
      GoRoute(
        path: '/mapa-diabetes',
        name: AppRoutes.mapaDiabetes.name,
        builder: (context, state) => const MapScreen(),
      ),
      // GoRoute(
      //   path: '/recommendations',
      //   builder: (context, state) => const RecommendationsScreen(),
      // ),
      // GoRoute(
      //   path: '/mealTracker',
      //   name: AppRoutes.mealTracker.name,
      //   builder: (context, state) => MealTracker(),
      // ),
      // GoRoute(
      //   path: '/metrics',
      //   name: AppRoutes.metrics.name,
      //   builder: (context, state) => Metrics(),
      // ),
      // GoRoute(
      //   path: '/medications',
      //   name: AppRoutes.medications.name,
      //   pageBuilder: (context, state) => const MaterialPage(
      //     fullscreenDialog: true,
      //     child: MedicationsScreen(),
      //   ),
      // ),
      // GoRoute(
      //   path: '/profile',
      //   name: AppRoutes.profilePage.name,
      //   builder: (context, state) => ProfileScreen(),
      // ),
      // GoRoute(
      //   path: '/settings',
      //   name: AppRoutes.settings.name,
      //   builder: (context, state) => SettingsScreen(),
      //   routes: [
      //     GoRoute(
      //       path: 'change-password',
      //       name: AppRoutes.changePassword.name,
      //       pageBuilder: (context, state) =>
      //           MaterialPage(child: ChangePasswordScreen()),
      //     ),
      //     GoRoute(
      //       path: 'edit-account',
      //       name: AppRoutes.editAccount.name,
      //       pageBuilder: (context, state) =>
      //           MaterialPage(child: EditAccountScreen()),
      //     ),
      //   ],
      // ),
      // GoRoute(
      //   path: '/alarm/:medId',
      //   name: AppRoutes.alarm.name,
      //   builder: (context, state) {
      //     final medId = state.pathParameters['medId']!;
      //     return ReminderAlarmScreen(medicationId: medId);
      //   },
      // ),
    ],
  );
}

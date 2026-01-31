import 'package:flutter/material.dart';
import 'package:peer_view/app_route/app_routes.dart';
import 'package:peer_view/constants/app_colors.dart';
import 'package:peer_view/ui/role_selection_page.dart';

class AppRoutesGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case AppRoutes.roleSelection:
        return _animatedRoute(
          RoleSelectionPage(),
          args?["animation"],
          args?["duration"],
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text("Error", style: TextStyle(color: AppColors.red(1))),
            ),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static _animatedRoute(
    Widget page,
    AppRouteAnimationType? type,
    int? duration,
  ) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, __) => page,
      transitionDuration: Duration(milliseconds: duration ?? 300),
      transitionsBuilder: (context, animation, __, child) {
        switch (type) {
          case AppRouteAnimationType.fade:
            return FadeTransition(opacity: animation, child: child);

          case AppRouteAnimationType.scale:
            return ScaleTransition(scale: animation, child: child);

          case AppRouteAnimationType.slide:
            return SlideTransition(
              position: Tween(
                begin: const Offset(1, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );

          case AppRouteAnimationType.rotation:
            return RotationTransition(turns: animation, child: child);

          default:
            return FadeTransition(opacity: animation, child: child);
        }
      },
    );
  }
}

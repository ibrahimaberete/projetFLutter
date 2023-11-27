import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import 'authenticate/authenticate_screen.dart';
import 'home/home_screen.dart';

class SplashScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppUser?>(context);
    if (user == null) {
      return AuthenticateScreen();
    } else {
      return HomeScreen();
    }
  }
}

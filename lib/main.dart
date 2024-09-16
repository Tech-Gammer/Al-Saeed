import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'homepage.dart';
import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   Stripe.publishableKey=dotenv.env["STRIPE_PUBLISH_KEY"]!;
//   await Stripe.instance.applySettings();
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//    runApp(MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  Stripe.publishableKey = dotenv.env["STRIPE_PUBLISH_KEY"]!;
  await Stripe.instance.applySettings();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/frontPage': (context) => FrontPage(),
        // Other routes...
      },
      debugShowCheckedModeBanner: false,
      home: FrontPage(),
    );
  }
}

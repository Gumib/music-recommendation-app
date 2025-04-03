import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'components/toggle_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

Future<void> _initHive() async {
  // Get device directory for storing Hive data
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path); // Initialize Hive with path
  await Hive.openBox('music_recommendations_cache'); // Open your box
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TogglePage(),
    );
  }
}

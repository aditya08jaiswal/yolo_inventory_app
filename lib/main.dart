import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'inventory_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  createState() => new MyAppState();
}

class MyAppState extends State<MyApp> {
  Widget check = LoginPage();
  final routes = <String, WidgetBuilder>{
    LoginPage.tag: (context) => LoginPage(),
    InventoryPage.tag: (context) => InventoryPage(),
  };
  SharedPreferences sharedPreferences;

  bool _testValue;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((SharedPreferences sp) {
      sharedPreferences = sp;
      sharedPreferences.setInt("callMapping", 1);
      _testValue = sharedPreferences.getBool('Logged_In');
      // will be null if never previously saved
      if (_testValue == null) {
        _testValue = false;
        check = LoginPage();
        persist(_testValue); // set an initial value
      } else if (_testValue) {
        print('MAIN DART FILE');
        sharedPreferences.setInt("callMapping", 1);
        check = InventoryPage();
      }
      setState(() {});
    });
  }

  void persist(bool value) {
    setState(() {
      _testValue = value;
    });
    sharedPreferences?.setBool('Logged_In', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF337ab7),
        fontFamily: 'Nunito',
      ),
      home: check,
      routes: routes,
    );
  }
}

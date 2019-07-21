import 'dart:convert';
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Post {
  final String phone;
  final String password;

  Post({this.phone, this.password});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      phone: json['phone'],
      password: json['password'],
    );
  }

  Map toMap() {
    var map = new Map<String, dynamic>();
    map["phone"] = phone;
    map["password"] = password;

    return map;
  }
}

Future<Map<String, dynamic>> createPost(
    String url, Map body, BuildContext context) async {
  var body1 = jsonEncode(body);
  print("INVENTORY PAGE CREATE POST BODY : " + body1);
  print("INVENTORY PAGE CREATE POST URL : " + url);

  Map<String, String> userHeader = {'content-type': 'application/json'};
  return await http
      .post(url, body: body1, headers: userHeader)
      .then((http.Response response) {
    final int statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 400 || json == null) {
      SharedPreferences sharedPreferences;
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        sharedPreferences = sp;
        sharedPreferences.setInt("callMapping", 0);
        sharedPreferences?.setBool('Logged_In', false);
      });
      Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.tag, (Route<dynamic> route) => false);
      throw new Exception("Error while fetching data");
    }
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    return responseBody;
  });
}

class InventoryPage extends StatefulWidget {
  static String tag = 'inventory-page';

  InventoryPage({Key key}) : super(key: key);

  @override
  createState() => InventoryPageState();
}

class Inventory {
  static String loginInventory = 'loginInventory';

  // ignore: non_constant_identifier_names
  String CREATE_POST_URL = Constants.SERVER_ADDRESS +
      '/' +
      Constants.PLATFORM +
      '/' +
      loginInventory +
      '/';

  Future<dynamic> callPostApi(BuildContext context) async {
    print("INVENTORY PAGE CALL POST API CREATE POST URL : " + CREATE_POST_URL);

    String url = Constants.SERVER_ADDRESS +
        '/erp/getMachineInventorySummary/?appsessiontoken=' +
        Constants.TOKEN;

    return url;
  }

  Future<Map<String, dynamic>> fetchPost(
      String url, BuildContext context) async {
    print("INVENTORY PAGE CALL POST API CREATE POST URL CONSTANT TOKEN : " +
        Constants.TOKEN);
    http.Response response =
        await http.get(url, headers: {'content-type': 'application/json'});
    print("INVENTORY PAGE FETCH POST STATUS CODE : " +
        response.statusCode.toString());
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return jsonDecode(response.body);
    } else {
      print("INVENTORY PAGE FETCH POST STATUS CODE : " +
          response.statusCode.toString());

      SharedPreferences sharedPreferences;
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        sharedPreferences = sp;
        sharedPreferences.setInt("callMapping", 0);
        sharedPreferences?.setBool('Logged_In', false);
      });
      Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.tag, (Route<dynamic> route) => false);
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }
}

class AppBarChoice {
  const AppBarChoice({this.title});

  final String title;
}

class InventoryPageState extends State<InventoryPage>
    with WidgetsBindingObserver {
  InventoryPageState() {
    print('HELLO INVENTORY PAGE');
  }

  @override
  void initState() {
    super.initState();
    setState(() {});
    SharedPreferences sharedPreferences;
    Inventory inventory = new Inventory();
    String url = '';

    SharedPreferences.getInstance().then((SharedPreferences sp) {
      print('CALL MAPPING : ' + sp.getInt("callMapping").toString());
      sharedPreferences = sp;
      if (sharedPreferences.getInt("callMapping") == 1) {
        sharedPreferences.setInt("callMapping", 0);
        url = Constants.SERVER_ADDRESS +
            '/erp/getMachineInventorySummary/?appsessiontoken=' +
            sharedPreferences.getString("appsessiontoken");
        print("INITSTATE : " + url);

        inventory.fetchPost(url, context).then((responseFetch) {
          print("INITSTATE RESPONSE FETCH : " + responseFetch.toString());

          setState(() {
            Constants.BASIC_DISPATCH =
                responseFetch['body']['basic']['ready_to_dispatch'];
            Constants.BASIC_ASSEMBLED =
                responseFetch['body']['basic']['can_be_assembled'];
            Constants.WELLNESS_DISPATCH =
                responseFetch['body']['wellness']['ready_to_dispatch'];
            Constants.WELLNESS_ASSEMBLED =
                responseFetch['body']['wellness']['can_be_assembled'];
            Constants.ADVANCED_DISPATCH =
                responseFetch['body']['advanced']['ready_to_dispatch'];
            Constants.ADVANCED_ASSEMBLED =
                responseFetch['body']['advanced']['can_be_assembled'];
          });

          print('BASIC DISPATCH : ' + Constants.BASIC_DISPATCH.toString());
          print('BASIC ASSEMBLED : ' + Constants.BASIC_ASSEMBLED.toString());
          print(
              'WELLNESS DISPATCH : ' + Constants.WELLNESS_DISPATCH.toString());
          print('WELLNESS ASSEMBLED : ' +
              Constants.WELLNESS_ASSEMBLED.toString());
          print(
              'ADVANCED DISPATCH : ' + Constants.ADVANCED_DISPATCH.toString());
          print('ADVANCED ASSEMBLED : ' +
              Constants.ADVANCED_ASSEMBLED.toString());
        });
      }
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    print('DISPOSE INVENTORY PAGE');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        print('INACTIVE INVENTORY PAGE');

        SharedPreferences.getInstance().then((SharedPreferences sp) {
          sp.setInt("callMapping", 1);
        });

        break;

      case AppLifecycleState.resumed:
        print('RESUMED INVENTORY PAGE');
        break;

      case AppLifecycleState.paused:
        print('PAUSED INVENTORY PAGE');
        break;

      case AppLifecycleState.suspending:
        print('SUSPENDING INVENTORY PAGE  ');
        break;
    }
  }

  List<AppBarChoice> listOfAppBarChoices = <AppBarChoice>[
    AppBarChoice(title: 'Logout'),
  ];

  void _selectAppBarChoice(AppBarChoice select) {
    setState(() {
      print("MENU CHOICE WORKING");

      Constants.USERNAME = '';
      Constants.PASSWORD = '';
      Constants.BASIC_DISPATCH = 0;
      Constants.BASIC_ASSEMBLED = 0;
      Constants.WELLNESS_DISPATCH = 0;
      Constants.WELLNESS_ASSEMBLED = 0;
      Constants.ADVANCED_DISPATCH = 0;
      Constants.ADVANCED_ASSEMBLED = 0;

      SharedPreferences sharedPreferences;
      SharedPreferences.getInstance().then((SharedPreferences sp) {
        sharedPreferences = sp;
        sharedPreferences.setInt("callMapping", 0);
        sharedPreferences?.setBool('Logged_In', false);
      });
      Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.tag, (Route<dynamic> route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAppBar = new AppBar(
      title: Text('Inventory Panel',
          style: TextStyle(fontStyle: FontStyle.normal, color: Colors.white)),
      actions: <Widget>[
        PopupMenuButton<AppBarChoice>(
          onSelected: _selectAppBarChoice,
          itemBuilder: (BuildContext context) {
            return listOfAppBarChoices.map((AppBarChoice choice) {
              return PopupMenuItem<AppBarChoice>(
                value: choice,
                child: Text(choice.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontStyle: FontStyle.normal,
                        fontSize: 20.0,
                        color: Colors.black)),
              );
            }).toList();
          },
        ),
      ],
    );

    final refreshButton = new RaisedButton(
      padding: const EdgeInsets.all(8.0),
      textColor: Colors.black,
      color: Color(0xFF337ab7),
      onPressed: () {
        String url;
        Inventory inventory = new Inventory();

        SharedPreferences sharedPreferences;
        SharedPreferences.getInstance().then((SharedPreferences sp) {
          sharedPreferences = sp;

          url = Constants.SERVER_ADDRESS +
              '/erp/getMachineInventorySummary/?appsessiontoken=' +
              sharedPreferences.getString("appsessiontoken");
          print(url);

          inventory.fetchPost(url, context).then((responseFetch) {
            print("REFRESH BUTTON PRESSED RESPONSE FETCH : " +
                responseFetch.toString());

            setState(() {
              Constants.BASIC_DISPATCH =
                  responseFetch['body']['basic']['ready_to_dispatch'];
              Constants.BASIC_ASSEMBLED =
                  responseFetch['body']['basic']['can_be_assembled'];
              Constants.WELLNESS_DISPATCH =
                  responseFetch['body']['wellness']['ready_to_dispatch'];
              Constants.WELLNESS_ASSEMBLED =
                  responseFetch['body']['wellness']['can_be_assembled'];
              Constants.ADVANCED_DISPATCH =
                  responseFetch['body']['advanced']['ready_to_dispatch'];
              Constants.ADVANCED_ASSEMBLED =
                  responseFetch['body']['advanced']['can_be_assembled'];
            });

            print('BASIC DISPATCH : ' + Constants.BASIC_DISPATCH.toString());
            print('BASIC ASSEMBLED : ' + Constants.BASIC_ASSEMBLED.toString());
            print('WELLNESS DISPATCH : ' +
                Constants.WELLNESS_DISPATCH.toString());
            print('WELLNESS ASSEMBLED : ' +
                Constants.WELLNESS_ASSEMBLED.toString());
            print('ADVANCED DISPATCH : ' +
                Constants.ADVANCED_DISPATCH.toString());
            print('ADVANCED ASSEMBLED : ' +
                Constants.ADVANCED_ASSEMBLED.toString());
          });
        });

        Fluttertoast.showToast(
          msg: "Refresh",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIos: 1,
          backgroundColor: Colors.lightBlue,
        );
      },
      child: Text("Refresh",
          style: TextStyle(
              fontStyle: FontStyle.normal,
              fontSize: 20.0,
              color: Colors.white)),
    );

    final space = const SizedBox(height: 35.0);

    final Color cardBackgroundColor = const Color(0xFF337ab7);
    final Color cardDetailColor = const Color(0xFFF5F5F5);

    final basicCard = Card(
      elevation: 5.0,
      color: cardDetailColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 55,
            color: cardBackgroundColor,
            child: ListTile(
              leading: Icon(
                Icons.assignment,
                color: Colors.white,
                size: 30.0,
              ),
              title: Text('Basic',
                  style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontSize: 20.0,
                      color: Colors.white)),
              onTap: () {
                print('Basic Card tapped');
              },
            ),
          ),
          InkWell(
            splashColor: cardBackgroundColor,
            onTap: () {},
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Ready to dispatch',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                              Text('${Constants.BASIC_DISPATCH}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Can be assembled',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                              Text('${Constants.BASIC_ASSEMBLED}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final wellnessCard = Card(
      elevation: 5.0,
      color: cardDetailColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 55,
            color: cardBackgroundColor,
            child: ListTile(
              leading: Icon(
                Icons.assignment,
                color: Colors.white,
                size: 30.0,
              ),
              title: Text('Wellness',
                  style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontSize: 20.0,
                      color: Colors.white)),
              onTap: () {
                print('Wellness tapped');
              },
            ),
          ),
          InkWell(
            splashColor: cardBackgroundColor,
            onTap: () {},
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Ready to dispatch',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                              Text('${Constants.WELLNESS_DISPATCH}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Can be assembled',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                              Text('${Constants.WELLNESS_ASSEMBLED}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final advancedCard = Card(
      elevation: 5.0,
      color: cardDetailColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 55,
            color: cardBackgroundColor,
            child: ListTile(
              leading: Icon(
                Icons.assignment,
                color: Colors.white,
                size: 30.0,
              ),
              title: Text('Advanced',
                  style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontSize: 20.0,
                      color: Colors.white)),
              onTap: () {
                print('Advanced Card tapped');
              },
            ),
          ),
          InkWell(
            splashColor: cardBackgroundColor,
            onTap: () {},
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Ready to dispatch',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                              Text('${Constants.ADVANCED_DISPATCH}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Column(
                            children: <Widget>[
                              Text('Can be assembled',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                              Text('${Constants.ADVANCED_ASSEMBLED}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.normal,
                                      color: cardBackgroundColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: inventoryAppBar,
      body: DropdownButtonHideUnderline(
        child: SafeArea(
          top: true,
          bottom: true,
          right: true,
          left: true,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              space,
              basicCard,
              space,
              wellnessCard,
              space,
              advancedCard,
              space,
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: true,
        bottom: true,
        right: true,
        left: true,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: refreshButton,
        ),
      ),
    );
  }
}

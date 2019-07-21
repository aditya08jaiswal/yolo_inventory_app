import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'inventory_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_country_picker/country.dart';
import 'package:flutter_country_picker/flutter_country_picker.dart';

TextEditingController usernameController = new TextEditingController();
TextEditingController passwordController = new TextEditingController();

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

Future<Map<String, dynamic>> createPost(String url, Map body) async {
  var body1 = jsonEncode(body);
  print("LOGIN PAGE CREATE POST BODY : " + body1);
  print("LOGIN PAGE CREATE POST URL : " + url);
  Map<String, String> userHeader = {'content-type': 'application/json'};
  return await http
      .post(url, body: body1, headers: userHeader)
      .then((http.Response response) {
    final int statusCode = response.statusCode;
    print("CREATE POST RESPONSE CODE : " + response.statusCode.toString());
    if (statusCode < 200 || statusCode >= 400 || json == null) {
      Fluttertoast.showToast(
        msg: "Wrong Credentials",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 1,
        backgroundColor: Colors.lightBlue,
      );
      throw new Exception("Error while fetching data");
    }
    Map<String, dynamic> mm = jsonDecode(response.body);
    return mm;
  });
}

class Inventory {
  static String loginInventory = 'loginInventory';

  String CREATE_POST_URL = Constants.SERVER_ADDRESS +
      '/' +
      Constants.PLATFORM +
      '/' +
      loginInventory +
      '/';

  Future<dynamic> callPostApi(String userPhone, String userPassword) async {
    print("LOGIN PAGE CALL POST API CREATE POST URL : " + CREATE_POST_URL);
    Post newPost = new Post(phone: userPhone, password: userPassword);

    Map<String, dynamic> response = await createPost(CREATE_POST_URL, newPost.toMap());

    SharedPreferences sharedPreferences;
    await SharedPreferences.getInstance().then((SharedPreferences sp) {
      sharedPreferences = sp;
      sharedPreferences.setString("appsessiontoken", response['body']['appsessiontoken']);
      print("CALL POST API APPSESSION TOKEN: " + sharedPreferences.getString("appsessiontoken"));
      Constants.TOKEN = response['body']['appsessiontoken'];
    });

    String url = Constants.SERVER_ADDRESS +
        '/erp/getMachineInventorySummary/?appsessiontoken=' +
        sharedPreferences?.getString("appsessiontoken");

    return url;

  }

  Future<Map<String, dynamic>> fetchPost(String url) async {
    http.Response response = await http.get(url, headers: {'content-type': 'application/json'});

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.
      return jsonDecode(response.body);
    } else {
      print("LOGIN PAGE FETCH POST STATUS CODE : " +  response.statusCode.toString());
      Fluttertoast.showToast(
        msg: "Wrong Credentials",
        toastLength: Toast.LENGTH_SHORT,
        timeInSecForIos: 1,
        backgroundColor: Colors.lightBlue,
      );
      throw new Exception("Error while fetching data");
    }
  }
}

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';
  static List<String> list = [];
  static Map<String, int> mapping = new Map();

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  SharedPreferences sharedPreferences;
  Country _countrySelected;
  String dialingCodeOfSelectedCountry = "91";

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((SharedPreferences sp) {
      sharedPreferences = sp;
      setState(() {});
    });
  }

  void persist(bool value) {
    sharedPreferences?.setBool('Logged_In', value);
  }

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
      tag: 'hero',
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 48.0,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Image.asset('assets/yolo_logo.png'),
        ),
      ),
    );

    final countryCode = CountryPicker(
      dense: false,
      showFlag: true,
      showDialingCode: true,
      showName: false,
      onChanged: (Country country) {
        setState(() {
          _countrySelected = country;
          dialingCodeOfSelectedCountry = _countrySelected.dialingCode.toString();
          print('DIALING CODE OF SELECTED COUNTRY : ' + dialingCodeOfSelectedCountry);
        });
      },
      selectedCountry: _countrySelected,
    );

    final phone = TextFormField(
      controller: usernameController,
      keyboardType: TextInputType.number,
      autofocus: true,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Phone Number',
      ),
      style: TextStyle(
          fontStyle: FontStyle.normal, fontSize: 20.0, color: Colors.black),
    );

    final phoneField = Container(
      padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
      decoration: new BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          border: new Border.all(color: Color(0xFF337ab7))),
      child: Row(
        children: <Widget>[
          countryCode,
          Expanded(child: phone),
        ],
      ),
    );

    final password = TextFormField(
      controller: passwordController,
      autofocus: false,
      obscureText: true,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'Password',
      ),
      style: TextStyle(
          fontStyle: FontStyle.normal, fontSize: 20.0, color: Colors.black),
    );

    final passwordField = Container(
        padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
        decoration: new BoxDecoration(
            borderRadius: BorderRadius.circular(32.0),
            border: new Border.all(color: Color(0xFF337ab7))),
        child: password);

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: RaisedButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
        onPressed: () {
          String userPhone = dialingCodeOfSelectedCountry + usernameController.text;
          String userPassword = passwordController.text;

          Constants.USERNAME = userPhone;
          Constants.PASSWORD = userPassword;

          print('USERNAME : ' + Constants.USERNAME.toString());
          print('PASSWORD : ' + Constants.PASSWORD.toString());

          Inventory inventory = new Inventory();
          inventory.callPostApi(userPhone, userPassword).then((url) {

            print("LOGIN BUTTON PRESSED : " + url);

            inventory.fetchPost(url).then((responseFetch) {
              persist(true);
              print("LOGIN BUTTON PRESSED RESPONSE FETCH : " + responseFetch.toString());
              Constants.BASIC_DISPATCH = responseFetch['body']['basic']['ready_to_dispatch'];
              Constants.BASIC_ASSEMBLED = responseFetch['body']['basic']['can_be_assembled'];
              Constants.WELLNESS_DISPATCH = responseFetch['body']['wellness']['ready_to_dispatch'];
              Constants.WELLNESS_ASSEMBLED = responseFetch['body']['wellness']['can_be_assembled'];
              Constants.ADVANCED_DISPATCH = responseFetch['body']['advanced']['ready_to_dispatch'];
              Constants.ADVANCED_ASSEMBLED = responseFetch['body']['advanced']['can_be_assembled'];
              sharedPreferences.setInt("callMapping", 1);
              Navigator.of(context).pushReplacementNamed(InventoryPage.tag);
            });
          });

          print('BASIC DISPATCH : ' + Constants.BASIC_DISPATCH.toString());
          print('BASIC ASSEMBLED : ' + Constants.BASIC_ASSEMBLED.toString());
          print('WELLNESS DISPATCH : ' + Constants.WELLNESS_DISPATCH.toString());
          print('WELLNESS ASSEMBLED : ' + Constants.WELLNESS_ASSEMBLED.toString());
          print('ADVANCED DISPATCH : ' + Constants.ADVANCED_DISPATCH.toString());
          print('ADVANCED ASSEMBLED : ' + Constants.ADVANCED_ASSEMBLED.toString());

        },
        padding: EdgeInsets.all(14),
        color: Color(0xFF337ab7),
        child: Text('LOGIN',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.normal,
                fontSize: 20.0,
                color: Colors.white)),
      ),
    );

    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(left: 24.0, right: 24.0),
                  children: <Widget>[
                    logo,
                    SizedBox(height: 48.0),
                    phoneField,
                    SizedBox(height: 8.0),
                    passwordField,
                    SizedBox(height: 24.0),
                    loginButton
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

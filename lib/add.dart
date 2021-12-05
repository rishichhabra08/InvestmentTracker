import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class Add extends StatefulWidget {
  static const routeName = '/add';
  @override
  _AddState createState() => _AddState();
}

class _AddState extends State<Add> {
  GlobalKey _formKey = GlobalKey<FormState>();
  GlobalKey _listKey = GlobalKey();
  TextEditingController _stockName = TextEditingController();
  TextEditingController _stockQty = TextEditingController();
  TextEditingController _stockRealPrice = TextEditingController();
  var chosenName;
  var chosenSymbol;
  var chosenType;
  FocusNode qtyNode;
  FocusNode cpNode;
  List<Map<String, String>> nameSymbol = [];
  List guesses = [];
  bool editMode = false;
  var arguments;
  var response;
  var error = '';
  var totalInvested;
  var cryptoCheck = false;
  Database database;

  SharedPreferences prefs;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    //use only when editing table
    editTable();
    qtyNode = FocusNode();
    cpNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    qtyNode.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() async {
    prefs = await SharedPreferences.getInstance();
    super.didChangeDependencies();
  }

  // static const autoMatch = "/auto-complete";
  static const autoMatch = "/v6/finance/autocomplete";
  // static const String _baseUrl = "apidojo-yahoo-finance-v1.p.rapidapi.com";
  static const String _baseUrl = "yfapi.net";
  // static const Map<String, String> _headers = {
  //   'x-rapidapi-key': "32a20cdaecmsh2d3d6b08aae9fabp1a76f2jsn70170b14021d",
  //   'x-rapidapi-host': "apidojo-yahoo-finance-v1.p.rapidapi.com"
  // };
  static const Map<String, String> _headers = {
    'x-api-key': "7Og7HU44F63kifTSnwp8GaLEZ200AlfJ6m2lrpfM",
    'accept': 'application/json',
  };

  void guessStock(String name) async {
    var query = {'lang': 'en', 'query': name};
    Uri uri = Uri.https(_baseUrl, autoMatch, query);
    // var uri = "https://yfapi.net/v6/finance/autocomplete/${name}";
    print(uri);
    final response = await http.get(uri, headers: _headers);
    print(response.body);

    if (response.statusCode == 200) {
      var result = json.decode(response.body);
      makeList(result);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load json data');
    }
  }

  void guessCrypto(String name) async {
    String _cryptoUrl = "https://api.coingecko.com/api/v3/coins/$name";

    final response = await http.get(_cryptoUrl);

    var result = json.decode(response.body);

    setState(() {
      if (result['error'] == null) {
        cryptoCheck = true;
        print(result);
        print(result["market_data"]['current_price']['usd']);
        print(result['name']);
        print(result['symbol']);
        chosenName = result['id'];
        chosenSymbol = result['symbol'];
      } else {
        print('error');
        chosenName = null;
        chosenSymbol = null;
        cryptoCheck = false;
      }
    });
  }

  void makeList(var result) {
    guesses = [];
    nameSymbol = [];
    // print(result["quotes"].length);
    // result["quotes"].forEach((r) {
    //   if (r['shortname'] == null && r['longname'] == null) {
    //     return;
    //   } else {
    //     if (r['shortname'] == null) {
    //       nameSymbol.add({r["longname"]: r["symbol"]});
    //     } else {
    //       nameSymbol.add({r["shortname"]: r["symbol"]});
    //     }
    //   }
    // });
    print(result["ResultSet"]);
    result["ResultSet"]["Result"].forEach((r) {
      print(r);
      if (r['name'] == null) {
        return;
      } else {
        // if (r['shortname'] == null) {
        //   nameSymbol.add({r["longname"]: r["symbol"]});
        // } else {
        //   nameSymbol.add({r["shortname"]: r["symbol"]});
        // }
        nameSymbol.add({r["name"]: r["symbol"]});
        print(nameSymbol);
      }
    });

    nameSymbol.forEach((element) {
      guesses.add(element.keys.first);
    });
    print(guesses.length);
    setState(() {});
  }

  // use only in case of editing Table
  Future<bool> editTable() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    // await deleteDatabase(path);
    print("inside edit table");
    try {
      database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("creating");
        await db.execute(
            'CREATE TABLE Test (symbol TEXT UNIQUE,name TEXT, quantity FLOAT(7,5), costprice FLOAT(10,3),type TEXT)');
      });
      try {
        // await database.rawUpdate(
        //       'UPDATE Test SET name = \'$name\', quantity = $quantity, costprice = $costPrice, type = \'$type\' WHERE symbol = \'$symbol\'');
        // await database
        // .execute('ALTER TABLE test ADD COLUMN type TEXT DEFAULT "stocks"');
        // await database.rawQuery('DESCRIBE test');
        // await database.delete('test', where: 'symbol = "YESBANK.BO"');
        // List list = await database.rawQuery('SELECT * FROM test');
        List list =
            await database.rawQuery('SELECT * FROM test WHERE type="stocks"');
        print("List");
        print(list);
        List list2 =
            await database.rawQuery('SELECT * FROM test WHERE type="crypto"');
        print("list2");
        print(list2);
      } catch (e) {
        print(e);
      }
    } catch (e) {
      error = e;
      print(error);
    }
    setState(() {});
    database.close();
    return true;
  }

  Future<bool> saveOrEditdata(String symbol, String name, double quantity,
      double costPrice, String type) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    // await deleteDatabase(path);

    try {
      print("saveoreditdata");
      database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("creating");
        await db.execute(
            'CREATE TABLE Test (symbol TEXT UNIQUE,name TEXT, quantity FLOAT(7,5), costprice FLOAT(10,3),type TEXT)');
      });
      if (editMode) {
        try {
          await database.rawUpdate(
              'UPDATE Test SET name = \'$name\', quantity = $quantity, costprice = $costPrice, type = \'$type\' WHERE symbol = \'$symbol\'');
        } catch (e) {
          print("error $e");
          return false;
        }
        print("Successfully edited $symbol, $name, $quantity,$costPrice,$type");
      } else {
        try {
          await database.rawInsert(
              'INSERT INTO Test VALUES (\'$symbol\', \'$name\', $quantity,$costPrice,\'$type\')');
        } catch (e) {
          print("error $e");
          return false;
        }
        print("Successfully added $symbol, $name, $quantity,$costPrice,$type");
      }
    } catch (e) {
      error = e;
      print(error);
    }
    setState(() {});
    database.close();
    return true;
  }

  void setEditMode() {
    if (!editMode)
      setState(() {
        print(arguments);
        print(arguments);
        // arguments = arguments.toList();
        print("yo boii ${arguments['symbol']}");
        chosenSymbol = arguments['symbol'];
        _stockName.text = arguments['name'];
        chosenName = arguments['name'];
        _stockQty.text = arguments['quantity'].toString();
        _stockRealPrice.text = arguments['costPrice'].toString();
        chosenType = arguments['type'];
        editMode = true;
        totalInvested = double.tryParse(_stockQty.text) *
            double.tryParse(_stockRealPrice.text);
      });
    setState(() {});
  }

  bool checkDataHide() {
    print('$chosenName,$totalInvested');
    if (_stockQty.text == null ||
        chosenName == '' ||
        chosenSymbol == '' ||
        chosenName == null ||
        chosenSymbol == null ||
        chosenType == null ||
        chosenType == '' ||
        totalInvested == null) {
      print(true);
      return true;
    } else {
      print(false);
      return false;
    }
  }

  bool checkValidData = true;

  @override
  Widget build(BuildContext context) {
    print("Check name $chosenName ${chosenName == ''}");
    arguments = ModalRoute.of(context).settings.arguments;
    if (arguments != null) setEditMode();
    return Scaffold(
        backgroundColor: Color.fromRGBO(42, 42, 42, 1),
        floatingActionButton: checkDataHide() != true
            ? FloatingActionButton(
                onPressed: () async {
                  setState(() {
                    loading = true;
                  });
                  double quantity = double.tryParse(_stockQty.text);
                  double costPrice = double.tryParse(_stockRealPrice.text);
                  if (quantity == null || costPrice == null) {
                    checkValidData = false;
                  }
                  print(
                      'details ===> $quantity, $costPrice,$chosenName,$chosenSymbol,$chosenType');
                  if (checkValidData == false) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Okay"),
                          ),
                        ],
                        backgroundColor: Color.fromRGBO(42, 42, 42, 1),
                        content: Text(
                          error == ''
                              ? "Please enter Unique And valid Data"
                              : error,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    );
                  } else {
                    response = await saveOrEditdata(chosenSymbol, chosenName,
                        quantity, costPrice, chosenType);
                    print('response $response');
                    if (response) {
                      Navigator.of(context).pop(['yo']);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Okay"),
                            ),
                          ],
                          backgroundColor: Color.fromRGBO(42, 42, 42, 1),
                          content: Text(
                            error == ''
                                ? "Please enter Unique And valid Data"
                                : error,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  setState(() {
                    loading = false;
                  });
                },
                child: Icon(Icons.done),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              SafeArea(
                child: Container(
                  width: double.maxFinite,
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(15),
                  // color: Colors.orange,
                  child: Column(
                    children: [
                      checkDataHide() != true
                          ? Container(
                              height: MediaQuery.of(context).size.height * 0.05,
                              width: double.maxFinite,
                              margin: EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${totalInvested}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            )
                          : Container(),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            selector("crypto"),
                            selector("stocks"),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                autocorrect: false,
                                cursorColor: Colors.white,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                                controller: _stockName,
                                decoration: InputDecoration(
                                  suffixIcon: chosenType == "crypto"
                                      ? cryptoCheck
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            )
                                          : Icon(
                                              Icons.check,
                                              color: Colors.red,
                                            )
                                      : null,
                                  alignLabelWithHint: true,
                                  hintText: "Enter Name",
                                  hintStyle: TextStyle(color: Colors.white),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(159, 105, 46, 1),
                                    ),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  print("Submit");
                                  String finalValue = value.trim();
                                  print(finalValue.isEmpty);
                                  if (finalValue.isNotEmpty) {
                                    if (chosenType == "crypto") {
                                      print("Crypto");
                                      guessCrypto(value);
                                    } else {
                                      print("Stock");
                                      guessStock(value);
                                    }
                                  } else
                                    setState(() {
                                      guesses = [];
                                    });
                                },
                              ),
                              guesses.isNotEmpty
                                  ? Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.4,
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(20),
                                        ),
                                      ),
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.of(context).size.height *
                                                .5,
                                      ),
                                      child: guessCard(),
                                    )
                                  : Container(),
                              SizedBox(
                                height: 30,
                              ),
                              TextField(
                                focusNode: qtyNode,
                                autocorrect: false,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                cursorColor: Colors.white,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                                controller: _stockQty,
                                decoration: InputDecoration(
                                  alignLabelWithHint: true,
                                  hintText: "Enter Quantity",
                                  hintStyle: TextStyle(color: Colors.white),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(159, 105, 46, 1),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              TextField(
                                focusNode: cpNode,
                                autocorrect: false,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                cursorColor: Colors.white,
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                                controller: _stockRealPrice,
                                onChanged: (value) {
                                  print(value.isEmpty);
                                  setState(() {
                                    if (value.isEmpty) {
                                      totalInvested = null;
                                    } else {
                                      totalInvested = double.tryParse(
                                              _stockQty.text) *
                                          double.tryParse(_stockRealPrice.text);
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  alignLabelWithHint: true,
                                  hintText: "Enter Cost Price",
                                  hintStyle: TextStyle(color: Colors.white),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color.fromRGBO(159, 105, 46, 1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading
                  ? Container(
                      color: Color.fromRGBO(0, 0, 0, 0.4),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Container(),
            ],
          ),
        ));
  }

  Widget selector(String name) {
    print(chosenType.toString().toLowerCase());
    print(name);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (name == "crypto") {
            chosenType = 'crypto';
            guesses = [];
            guessCrypto(_stockName.text);
          } else {
            chosenType = "stocks";
            guessStock(_stockName.text);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: chosenType == name
              ? Color.fromRGBO(184, 130, 71, 1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(name),
      ),
    );
  }

  Widget guessCard() {
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      key: _listKey,
      itemCount: nameSymbol.length,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                guesses[index].toString() ?? "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  letterSpacing: 2,
                  wordSpacing: 2,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                chosenName = guesses[index];
                chosenSymbol = nameSymbol[index].values.last;
                _stockName.text = chosenName;
                print("$chosenName, $chosenSymbol");
                nameSymbol = [];
                guesses = [];
                qtyNode.requestFocus();
              });
            },
          ),
          Divider(
            color: Color.fromRGBO(159, 105, 46, 1),
            height: 10,
          ),
        ],
      ),
    );
  }
}

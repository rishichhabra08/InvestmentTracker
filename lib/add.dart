import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:finance_quote/finance_quote.dart';
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
  FocusNode qtyNode;
  FocusNode cpNode;
  List<Map<String, String>> nameSymbol = [];
  List guesses = [];
  bool editMode = false;
  var arguments;
  var response;

  static const String _baseUrl = "apidojo-yahoo-finance-v1.p.rapidapi.com";
  static const Map<String, String> _headers = {
    'x-rapidapi-key': "32a20cdaecmsh2d3d6b08aae9fabp1a76f2jsn70170b14021d",
    'x-rapidapi-host': "apidojo-yahoo-finance-v1.p.rapidapi.com"
  };

  static const autoMatch = "/auto-complete";
  SharedPreferences prefs;
  bool loading = false;

  @override
  void initState() {
    super.initState();
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

  void guessStock(String name) async {
    var query = {"q": name};
    Uri uri = Uri.https(_baseUrl, autoMatch, query);
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

  void makeList(var result) {
    guesses = [];
    nameSymbol = [];
    print(result["quotes"].length);
    result["quotes"].forEach((r) {
      nameSymbol.add({r["shortname"]: r["symbol"]});
    });

    nameSymbol.forEach((element) {
      guesses.add(element.keys.first);
    });
    print(guesses.length);
    setState(() {});
  }

  Future<bool> saveOrEditdata(
      String symbol, String name, double quantity, double costPrice) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    // await deleteDatabase(path);
    Database database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      print("creating");
      await db.execute(
          'CREATE TABLE Test (symbol TEXT UNIQUE,name TEXT, quantity FLOAT(7,5), costprice FLOAT(10,3))');
    });
    if (editMode) {
      try {
        await database.rawUpdate(
            'UPDATE Test SET name = \'$name\', quantity = $quantity, costprice = $costPrice WHERE symbol = \'$symbol\'');
      } catch (e) {
        print("error $e");
        return false;
      }
      print("Successfully edited $symbol, $name, $quantity,$costPrice");
    } else {
      try {
        await database.rawInsert(
            'INSERT INTO Test VALUES (\'$symbol\', \'$name\', $quantity,$costPrice)');
      } catch (e) {
        print("error $e");
        return false;
      }
      print("Successfully added $symbol, $name, $quantity,$costPrice");
    }
    database.close();
    return true;
  }

  void setEditMode() {
    setState(() {
      print(arguments);
      print(arguments.toList());
      arguments = arguments.toList();
      chosenSymbol = arguments[0];
      _stockName.text = arguments[1];
      chosenName = arguments[1];
      _stockQty.text = arguments[2].toString();
      _stockRealPrice.text = arguments[3].toString();
      editMode = true;
      print("yo boii");
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    arguments = ModalRoute.of(context).settings.arguments;
    if (arguments != null) setEditMode();
    return Scaffold(
        backgroundColor: Color.fromRGBO(42, 42, 42, 1),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            setState(() {
              loading = true;
            });
            double quantity = double.tryParse(_stockQty.text);
            double costPrice = double.tryParse(_stockRealPrice.text);
            if (quantity == null || costPrice == null) {
            } else {
              response = await saveOrEditdata(
                  chosenSymbol, chosenName, quantity, costPrice);
              print(response);
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
                      "Please enter Unique And valid Data",
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
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Stack(
          children: [
            SafeArea(
              child: Container(
                width: double.maxFinite,
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                // color: Colors.orange,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        autofocus: true,
                        autocorrect: false,
                        cursorColor: Colors.white,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        controller: _stockName,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          hintText: "Enter Name",
                          hintStyle: TextStyle(color: Colors.white),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color.fromRGBO(159, 105, 46, 1),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          String finalValue = value.trim();
                          print(finalValue.isEmpty);
                          if (finalValue.isNotEmpty)
                            guessStock(value);
                          else
                            setState(() {
                              guesses = [];
                            });
                        },
                      ),
                      guesses.isNotEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * .5,
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
                        keyboardType: TextInputType.number,
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
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.white,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        controller: _stockRealPrice,
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
        ));
  }

  Widget guessCard() {
    return ListView.builder(
      key: _listKey,
      itemCount: nameSymbol.length,
      itemBuilder: (context, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                guesses[index],
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

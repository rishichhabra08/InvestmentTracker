import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:finance_quote/finance_quote.dart';
import 'package:flutter/material.dart';
import 'package:investment_tracker/add.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List dbdata = [];
  var _once = true;
  var height;
  var width;
  TextEditingController _converter = TextEditingController(text: '79');
  double converter = 79;
  List<String> symbols = [];
  List names = [];
  List types = [];
  List value = [];
  List initInvestment = [];
  List<double> price = [];
  List finalInvestment = [];
  List percentagediff = [];
  List<double> quantity = [];
  Map finalValue = {};
  List costPrice = [];
  double totalInvestmentValue;
  var received;
  Database database;
  var databasesPath;
  bool loading = false;

  @override
  void initState() {
    getDataFromDatabase();
    // Timer.periodic(Duration(seconds: 5), (timer) {
    //   setState(() {
    //     // print('periodic');
    //     fetchData();
    //   });
    // });
    super.initState();
  }

  void getDataFromDatabase() async {
    setState(() {
      loading = true;
    });
    print('getDataFromDatabase');
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    try {
      database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("creating");
        await db.execute(
            'CREATE TABLE Test (symbol TEXT UNIQUE,name TEXT, quantity FLOAT(7,5), costprice FLOAT(10,3),type TEXT)');
      });
      dbdata = await database.rawQuery('SELECT * FROM Test');
    } catch (e) {
      print(e);
    }

    // print(database);
    database.close();
    fetchData();
  }

  void fetchData() async {
    List<String> stocksymbols = [];
    List<String> cryptoids = [];
    setState(() {
      loading = true;
      totalInvestmentValue = 0;
      initInvestment = [];
      finalInvestment = [];
      symbols = [];
      names = [];
      types = [];
      value = [];
      price = [];
      percentagediff = [];
      quantity = [];
      costPrice = [];
    });

    dbdata.forEach((r) {
      names.add(r['name']);
      types.add(r['type']);
      quantity.add(r['quantity']);
      costPrice.add(r['costprice']);
      initInvestment.add(r['quantity'] * r['costprice']);
      symbols.add(r['symbol']);
      if (r['type'] == "stocks") {
        stocksymbols.add(r['symbol']);
      } else {
        cryptoids.add(r['name']);
      }
    });
    //stocks fetch data
    final Map<String, Map<String, String>> quotePrice =
        await FinanceQuote.getPrice(
            quoteProvider: QuoteProvider.yahoo, symbols: stocksymbols);

    //crypto fetch data
    var cryptourlString = cryptoids.join(",");
    String _cryptoUrl =
        "https://api.coingecko.com/api/v3/simple/price?ids=$cryptourlString&vs_currencies=usd";
    final response = await http.get(_cryptoUrl);
    var resultCrypto = json.decode(response.body);
    // print(resultCrypto);

    // print(quotePrice);

    int i = symbols.length;
    for (int x = 0; x < i; x++) {
      double priceValue;
      if (types[x] == "stocks") {
        if (quotePrice[symbols[x]]['currency'] != 'INR') {
          priceValue =
              double.parse(quotePrice[symbols[x]]['price']) * converter;
          initInvestment[x] = initInvestment[x] * converter;
        } else {
          priceValue = double.parse(quotePrice[symbols[x]]['price']);
        }
        price.add(priceValue);
        double finalInvestmentValue = price[x] * quantity[x];
        finalInvestment.add(finalInvestmentValue);
        double diff = double.tryParse(
            (((finalInvestment[x] - initInvestment[x]) / initInvestment[x]) *
                    100)
                .toStringAsFixed(2));
        percentagediff.add(diff);
      } else {
        int j = cryptoids.length;
        priceValue = (resultCrypto[names[x]]['usd']) * converter;
        initInvestment[x] = initInvestment[x] * converter;
        price.add(priceValue);
        double finalInvestmentValue = price[x] * quantity[x];
        finalInvestment.add(finalInvestmentValue);
        double diff = double.tryParse(
            (((finalInvestment[x] - initInvestment[x]) / initInvestment[x]) *
                    100)
                .toStringAsFixed(2));
        percentagediff.add(diff);
      }
    }

    //
    print("check");

    totalInvestmentValue = 0;

    for (int x = 0; x < symbols.length; x++) {
      // print("x == $x");
      totalInvestmentValue += finalInvestment[x];
      // print(
      // '${names[x]},${costPrice[x]},${quantity[x]},${price[x]},${percentagediff[x]},${initInvestment[x]},${finalInvestment[x]}');
      finalValue[symbols[x]] = {
        'name': names[x],
        'type': types[x],
        'costPrice': costPrice[x],
        'currentPrice': price[x],
        'quantity': quantity[x],
        'diff': percentagediff[x],
        'currentValue': finalInvestment[x],
        'initalValue': initInvestment[x]
      };
    }

    setState(() {
      loading = false;
    });
  }

  Future<bool> deleteData(String symbol) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    // await deleteDatabase(path);
    Database database = await openDatabase(
      path,
      version: 1,
    );
    try {
      await database.rawDelete('DELETE FROM Test WHERE  symbol = \'$symbol\'');
    } catch (e) {
      print("error $e");
      return false;
    }
    print("Successfully deleted $symbol");

    database.close();
    return true;
  }

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    if (_once) {
      setState(() {
        height = MediaQuery.of(context).size.height;
        width = MediaQuery.of(context).size.width;
        _once = false;
      });
    }
    // print(dbdata.isEmpty);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Color.fromRGBO(42, 42, 42, 1),
      // drawer: drawerWidget(),
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              child: Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 3.8,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.add,
                                color: Color.fromRGBO(159, 105, 46, 1),
                              ),
                              onPressed: () {
                                Navigator.of(context)
                                    .pushNamed(Add.routeName)
                                    .then((value) => setState(() {
                                          getDataFromDatabase();
                                        }));
                              },
                            ),
                          ],
                        ),
                        Expanded(
                          child: Container(
                            height: height * 0.3,
                            margin: EdgeInsets.fromLTRB(20, 8, 20, 8),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Color.fromRGBO(187, 138, 63, 1),
                              boxShadow: [
                                BoxShadow(
                                    blurRadius: 10,
                                    color: Colors.black38,
                                    spreadRadius: 10)
                              ],
                            ),
                            child: Center(
                              child: Text(
                                dbdata.isEmpty
                                    ? "Please Add Stocks In portfolio"
                                    : loading
                                        ? "Calculating..."
                                        : "\₹${totalInvestmentValue.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 30,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        // Container(
                        //   margin: EdgeInsets.symmetric(horizontal: 23),
                        //   alignment: Alignment.centerRight,
                        //   child: Text(
                        //     "Refreshes every 5 second!!",
                        //     style: TextStyle(
                        //       fontStyle: FontStyle.italic,
                        //       color: Colors.white,
                        //     ),
                        //   ),
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "\$ - ₹ ",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerRight,
                              width: width * 0.2,
                              height: 20,
                              margin: EdgeInsets.only(top: 20),
                              child: TextField(
                                controller: _converter,
                                decoration:
                                    InputDecoration(border: InputBorder.none),
                                keyboardType: TextInputType.numberWithOptions(),
                                onChanged: (value) {
                                  setState(() {
                                    converter =
                                        double.tryParse(_converter.text);
                                  });
                                },
                                // "\$ - ₹ $converter",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 50),
                    child: Divider(
                      color: Colors.black38,
                      thickness: 3,
                    ),
                  ),
                  finalValue != null
                      ? Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => fetchData(),
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: ListView.builder(
                                itemCount: symbols.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      stockDetailCard(symbols[index],
                                          finalValue[symbols[index]], context)
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
          loading
              ? Container(
                  color: Color.fromRGBO(0, 0, 0, 0.4),
                  child: Center(
                      // child: CircularProgressIndicator(),
                      ),
                )
              : Container(),
        ],
      ),
    );
  }

  // Drawer drawerWidget() {
  //   return Drawer(
  //     child: SafeArea(
  //       child: ListView(
  //         padding: EdgeInsets.zero,
  //         children: <Widget>[
  //           // DrawerHeader(
  //           //   decoration: BoxDecoration(
  //           //     color: Colors.black,
  //           //   ),
  //           //   child: Text("Investment Tracker"),
  //           // ),
  //           ListTile(
  //             title: Text('Item 1'),
  //           ),
  //           ListTile(
  //             title: Text('Item 2'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  //   ;
  // }

  Widget stockDetailCard(var symb, Map data, BuildContext context) {
    // print('symbol $symb, data $data');
    Color color = data == null
        ? Colors.transparent
        : data["diff"] < 0
            ? Colors.red
            : Colors.green;
    return data == null
        ? Container()
        : Hero(
            tag: data,
            child: GestureDetector(
              // onLongPress: () {
              //   print("Hittt");
              //   showDialog(
              //     context: context,
              //     builder: (context) => detailedDialog(data),
              //   );
              // },
              child: Container(
                margin: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 10, color: Colors.black26, spreadRadius: 0)
                  ],
                ),
                width: double.maxFinite,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Card(
                      color: Color.fromRGBO(41, 41, 41, 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        margin: EdgeInsets.only(bottom: 10),
                        width: double.maxFinite,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Text(
                                '${data['name']} (${data['type']})',
                                // 'sdnjcndsjcnsdjhvbhjdvbhdvdfbdfhbdfhvbdfhv',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(5, 5, 10, 0),
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        // color: Colors.amberAccent,
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Qty. ${data['quantity'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          // color: Color.fromRGBO(159, 105, 46, 1),
                                          // color: Colors.blue,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(5, 5, 10, 0),
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: Colors.amberAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '₹ ${data['currentPrice'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color:
                                              Color.fromRGBO(159, 105, 46, 1),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 5, 10, 0),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: color,
                                      child: Text(
                                        '${data['diff']}%',
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(5, 5, 10, 0),
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        // color: Colors.amberAccent,
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'CP. ${data['costPrice'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          // color: Color.fromRGBO(159, 105, 46, 1),
                                          // color: Colors.blue,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(
                            //   height: 10,
                            // ),

                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: Container(
                            //         child: Text(
                            //           data['name'],
                            //           // 'sdnjcndsjcnsdjhvbhjdvbhdvdfbdfhbdfhvbdfhv',
                            //           style: TextStyle(
                            //             color: Colors.white,
                            //             fontSize: 20,
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     // Container(
                            //     //   margin: EdgeInsets.fromLTRB(5, 5, 10, 0),
                            //     //   child: Container(
                            //     //     padding: EdgeInsets.all(5),
                            //     //     decoration: BoxDecoration(
                            //     //       shape: BoxShape.rectangle,
                            //     //       color: Colors.amberAccent,
                            //     //       borderRadius: BorderRadius.circular(10),
                            //     //     ),
                            //     //     child: Text(
                            //     //       '₹ ${data['currentPrice'].toStringAsFixed(2)}',
                            //     //       style: TextStyle(
                            //     //         color: Color.fromRGBO(159, 105, 46, 1),
                            //     //         fontSize: 15,
                            //     //       ),
                            //     //     ),
                            //     //   ),
                            //     // ),
                            //     // Container(
                            //     //   margin: EdgeInsets.fromLTRB(0, 5, 10, 0),
                            //     //   child: CircleAvatar(
                            //     //     radius: 25,
                            //     //     backgroundColor: color,
                            //     //     child: Text(
                            //     //       '${data['diff']}%',
                            //     //       style: TextStyle(
                            //     //           color: Colors.black, fontSize: 11),
                            //     //     ),
                            //     //   ),
                            //     // )
                            //   ],
                            // ),
                            SizedBox(
                              height: 12,
                            ),
                            Row(
                              children: [
                                Container(
                                  child: Text(
                                    ' \₹ ${data['currentValue'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                  ),
                                ),
                                // SizedBox(
                                //   width: 20,
                                // ),
                                // Container(
                                //   child: Icon(
                                //     Icons.production_quantity_limits,
                                //     color: Colors.white,
                                //   ),
                                // )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      // alignment: Alignment.topRight,
                      // heightFactor: 1,
                      right: -5,
                      bottom: -5,
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white,
                                ),
                              ],
                              color: Color.fromRGBO(41, 41, 41, 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Color.fromRGBO(159, 105, 46, 1),
                                  ),
                                  onPressed: () async {
                                    bool response = await deleteData(symb);
                                    if (!response) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text("Okay"),
                                            ),
                                          ],
                                          backgroundColor:
                                              Color.fromRGBO(42, 42, 42, 1),
                                          content: Text(
                                            "Please enter Unique And valid Data",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        getDataFromDatabase();
                                      });
                                    }
                                  }),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white,
                                ),
                              ],
                              color: Color.fromRGBO(41, 41, 41, 1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Color.fromRGBO(159, 105, 46, 1),
                                  ),
                                  onPressed: () async {
                                    print(
                                        ' sending args => $symb,${data['name']},${data['quantity']},${data['costPrice']},${data['type']}');
                                    received = await Navigator.of(context)
                                        .pushNamed(Add.routeName, arguments: {
                                      "symbol": symb,
                                      "name": data['name'],
                                      'quantity': data['quantity'],
                                      'costPrice': data['costPrice'],
                                      'type': data['type'],
                                    });
                                    print(received);
                                    if (received != null) {
                                      setState(() {
                                        getDataFromDatabase();
                                      });
                                    }
                                  }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  // Widget detailedDialog(data) {
  //   print(data);
  //   return SimpleDialog(
  //     backgroundColor: Colors.orange[200],
  //     title: Container(
  //       alignment: Alignment.center,
  //       child: Text(
  //         data['name'],
  //       ),
  //     ),
  //     children: [
  //       Container(
  //         child: Column(
  //           children: [
  //             Text(data["name"]),
  //             Text(data["costPrice"].toString()),
  //             Text(data["currentPrice"].toString()),
  //             Text(data["quantity"].toString()),
  //           ],
  //         ),
  //       )
  //     ],
  //   );
  // }
}

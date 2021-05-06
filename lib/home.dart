import 'dart:async';
import 'dart:ui';

import 'package:finance_quote/finance_quote.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:investment_tracker/add.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List dbdata = [];
  var _once = true;
  var height;
  List<String> symbols = [];
  List names = [];
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

  @override
  void didChangeDependencies() async {
    await getData();
    super.didChangeDependencies();
  }

  void getData() async {
    symbols = [];
    names = [];
    value = [];
    initInvestment = [];
    price = [];
    finalInvestment = [];
    percentagediff = [];
    quantity = [];
    costPrice = [];
    totalInvestmentValue = 0;
    Map finalValue = {};
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    Database database = await openDatabase(
      path,
      version: 1,
    );
    dbdata = await database.rawQuery('SELECT * FROM Test');
    // print(dbdata);
    database.close();
    fetchData();
  }

  void fetchData() async {
    dbdata.forEach((r) {
      names.add(r['name']);
      quantity.add(r['quantity']);
      costPrice.add(r['costprice']);
      initInvestment.add(r['quantity'] * r['costprice']);
      symbols.add(r['symbol']);
    });
    final Map<String, Map<String, String>> quotePrice =
        await FinanceQuote.getPrice(
            quoteProvider: QuoteProvider.yahoo, symbols: symbols);
    // print("quotePrice $quotePrice");
    // print(quotePrice);
    int i = symbols.length;
    for (int x = 0; x < i; x++) {
      // print('price ${quotePrice[symbols[x]]['price']}');
      double priceValue;
      if (quotePrice[symbols[x]]['currency'] != 'INR') {
        priceValue = double.parse(quotePrice[symbols[x]]['price']) * 75;
      } else {
        priceValue = double.parse(quotePrice[symbols[x]]['price']);
      }
      price.add(priceValue);
      double finalInvestmentValue = price[x] * quantity[x];
      finalInvestment.add(finalInvestmentValue);
      double diff = double.tryParse(
          (((finalInvestment[x] - initInvestment[x]) / initInvestment[x]) * 100)
              .toStringAsFixed(2));
      // print(diff);
      percentagediff.add(diff);
    }
    for (int x = 0; x < i; x++) {
      totalInvestmentValue += finalInvestment[x];
      finalValue[symbols[x]] = {
        'name': names[x],
        'costPrice': costPrice[x],
        'currentPrice': price[x],
        'quantity': quantity[x],
        'diff': percentagediff[x],
        'currentValue': finalInvestment[x],
        'initalValue': initInvestment[x]
      };
    }
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    if (_once) {
      setState(() {
        height = MediaQuery.of(context).size.height;
        _once = false;
      });
    }
    // Timer.periodic(Duration(seconds: 5), (t) {
    //   getData();
    // });
    return Scaffold(
      backgroundColor: Color.fromRGBO(42, 42, 42, 1),
      body: SafeArea(
        child: Container(
            child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 3.8,
              // color: Colors.blue[100],
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
                                    getData();
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
                          "\₹${totalInvestmentValue.toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 50),
              child: Divider(
                color: Colors.black38,
                thickness: 3,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => getData(),
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
                    )),
              ),
            ),
          ],
        )),
      ),
    );
  }

  Widget stockDetailCard(var symb, Map data, BuildContext context) {
    // print('symbol $symb, data $data');
    Color color = data['diff'] < 0 ? Colors.red : Colors.green;
    return GestureDetector(
      onLongPress: () {},
      child: Container(
        margin: EdgeInsets.all(25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(blurRadius: 10, color: Colors.black26, spreadRadius: 0)
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
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                width: double.maxFinite,
                height: height * 0.11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            child: Text(
                              data['name'],
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
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
                              style:
                                  TextStyle(color: Colors.black, fontSize: 11),
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      child: Text(
                        ' \₹ ${data['currentValue']}',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
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
                                      onPressed: () => Navigator.pop(context),
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
                                getData();
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
                            received = await Navigator.of(context)
                                .pushNamed(Add.routeName, arguments: {
                              symb,
                              data['name'],
                              data['quantity'],
                              data['costPrice']
                            });
                            print(received);
                            if (received != null) {
                              setState(() {
                                getData();
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
    );
  }
}

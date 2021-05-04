import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_tracker/add.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var dbdata;
  @override
  void didChangeDependencies() async {
    await getData();
    super.didChangeDependencies();
  }

  void getData() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'data.db');
    Database database = await openDatabase(
      path,
      version: 1,
    );
    dbdata = await database.rawQuery('SELECT * FROM Test');
    print(dbdata);
    database.close();
  }

  void fetchData() {
    print(dbdata);
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(Duration(seconds: 5), (t) {
      fetchData();
    });
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
                          Navigator.of(context).pushNamed(Add.routeName);
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
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
                      // child: ,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }
}

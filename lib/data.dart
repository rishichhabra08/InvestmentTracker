import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';

class Data {
  final String symbol;
  final int quantity;
  final int costPrice;

  Data({this.symbol, this.quantity, this.costPrice});
}

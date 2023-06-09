import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class Database{
  dynamic db;

  Database(String address, String port, String name) {
    db = Db('mongodb://$address:$port/$name');
    db.open();
  }
}

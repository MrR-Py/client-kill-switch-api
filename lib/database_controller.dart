import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class Database {
  Db? db;

  Future<bool> init(String address, String port, String name) async {
    db = Db('mongodb://$address:$port/$name');
    await db?.open();
    print('Connected to database');
    return true;
  }

  Future<List<String>> checkPermission(String appUID, String apiKey) async {
      dynamic expirationDate;
      dynamic allowExecution;

      var collectionName = 'apps';
      await db?.dropCollection(collectionName);
      var coll = db?.collection(collectionName);
      var res =
      await coll?.find(where.eq('UID', appUID).eq('apiKey', apiKey)).toList();

      if(res?.length != 0) {
      expirationDate = res?.first['expirationDate'];
      allowExecution = res?.first['allowExecution'];
      }
      return [expirationDate.toString(), allowExecution.toString()];
  }
}

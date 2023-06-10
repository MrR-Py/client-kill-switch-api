import 'dart:convert';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:crypto/crypto.dart';

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

    if (res?.length != 0) {
      expirationDate = res?.first['expirationDate'];
      allowExecution = res?.first['allowExecution'];
    }
    return [expirationDate.toString(), allowExecution.toString()];
  }

  Future<int> addApp(String appName, String expirationDate, String appUID,
      String apiKey) async {
    var collectionName = 'apps';
    var appUID;
    var apiKey;
    await db?.dropCollection(collectionName);
    var coll = db?.collection(collectionName);
    var res = await coll?.find(where.eq('name', appName)).toList();
    if (res?.length == 0) {
      // TODO: Secure apiKey
      coll?.insertOne({
        'appName': appName,
        'expirationDate': expirationDate,
        'appUID': appUID,
        'apiKey': apiKey
      });
      return 0;
    }
    return 1;
  }

  Future<int> modApp(String appUID, String apiKey, String varToChange, String args) async{
    var collectionName = 'apps';
    await db?.dropCollection(collectionName);
    var coll = db?.collection(collectionName);
    var res = await coll?.findOne(where.eq('appUID', appUID).eq('apiKey', apiKey));
    if(res == null) return 1;
    res[varToChange] = args;
    await coll?.save(res);
    return 0;
  }

  Future<int> deleteApp(String appUID, String apiKey) async {
    var collectionName = 'apps';
    await db?.dropCollection(collectionName);
    var coll = db?.collection(collectionName);
    await coll?.deleteOne(where.eq('appUID', appUID).eq('apiKey', apiKey));
    return 0;
  }
}

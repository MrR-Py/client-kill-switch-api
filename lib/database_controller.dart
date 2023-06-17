import 'package:mongo_dart/mongo_dart.dart';

// Database as a class is needed so that it is possible that a connection can
// occur once and only once.
class Database {
  Db? db;

  // Init function to connect to database,
  Future<bool> init(String address, String port, String name) async {
    db = Db('mongodb://$address:$port/$name');
    await db?.open();
    print('Connected to database');
    return true;
  }

  // Database check for relevant data whether an app is "allowed" to start
  // or not
  Future<List<String>> checkPermission(String appUID, String apiKey) async {
    dynamic expirationDate;
    dynamic allowExecution;

    var collectionName = 'apps';
    var coll = db?.collection(collectionName);
    var res = await coll
        ?.find(where.eq('appUID', appUID).eq('apiKey', apiKey))
        .toList();

    if (res?.length != 0) {
      expirationDate = res?.first['expirationDate'];
      allowExecution = res?.first['allowExecution'];
    }
    return [expirationDate.toString(), allowExecution.toString()];
  }

  // Adds a database entry for an app
  Future<int> addApp(String appName, String expirationDate, String appUID,
      String apiKey, bool allowExecution) async {
    var collectionName = 'apps';
    var coll = db?.collection(collectionName);
    var res = await coll?.find(where.eq('appName', appName)).toList();
    if (res == null) return -1;
    if (res.length == 0) {
      // TODO: Secure apiKey
      coll?.insertOne({
        'appName': appName,
        'expirationDate': expirationDate,
        'appUID': appUID,
        'apiKey': apiKey,
        'allowExecution': allowExecution
      });
      return 0;
    }
    return 1;
  }

  // Modifies an entry for an app in the database
  Future<int> modApp(
      String appUID, String apiKey, String varToChange, String args) async {
    var collectionName = 'apps';
    var coll = db?.collection(collectionName);
    var res =
        await coll?.findOne(where.eq('appUID', appUID).eq('apiKey', apiKey));
    if (res == null) return 1;
    await coll?.update(where.eq('appUID', appUID).eq('apiKey', apiKey),
        modify.set(varToChange, args));
    return 0;
  }

  // Deletes an entry for an app in a database
  Future<int> deleteApp(String appUID, String apiKey) async {
    var collectionName = 'apps';
    var coll = db?.collection(collectionName);
    await coll?.deleteOne(where.eq('appUID', appUID).eq('apiKey', apiKey));
    return 0;
  }
}

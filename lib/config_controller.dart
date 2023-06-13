import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class Config {
  dynamic dbPort;
  dynamic dbAddress;
  dynamic dbName;

  dynamic serverPort;
  //dynamic serverAddress;

  dynamic appMasterKey;
  Config(String configFilePath) {

    if (!File(configFilePath).existsSync()) {
      var fileCreate = File(configFilePath);
      while(true) {
        print(
            'No config file found! To create a new one, please insert a new password:');
        String? passwordClear = stdin.readLineSync();
        print('Confirm password: ');
        String? passwordConfirm = stdin.readLineSync();
        if (passwordClear == passwordConfirm) {
          break;
        }
        else {
          print('That didn\'t work, please try again');
        }
      }
      var passwordClearEncoded = utf8.encode(passwordClear!);
      var passwordHashed = sha512.convert(passwordClearEncoded);

      var jsonTemplate = """
      {
        "database": {
          "port": 27017,
          "address": "localhost",
          "name": "client-kill-switch"
        },
        "server" :{
          "port": 8080
        },
        "app": {
          "masterKey": "$passwordHashed"
        }
      }
      """;

      fileCreate.create();
      fileCreate.openWrite();
      fileCreate.writeAsStringSync(jsonTemplate);
    }
    var configFile = File(configFilePath);
    var configJson = jsonDecode(configFile.readAsStringSync());
    assert(configJson is Map);

    dbPort = configJson['database']['port'];
    dbAddress = configJson['database']['address'];
    dbName = configJson['database']['name'];

    serverPort = configJson['server']['port'].toString();
    //serverAddress = configJson['server']['address'];

    appMasterKey = configJson['app']['masterKey'].toString();
    return;
  }

}

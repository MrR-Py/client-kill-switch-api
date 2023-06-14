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
  dynamic appPassword;
  Config(String configFilePath) {

    dynamic masterPasswordClear;
    dynamic appPasswordClear;

    if (!File(configFilePath).existsSync()) {
      print('No config file found! Creating new one');
      var fileCreate = File(configFilePath);
      while(true) {
        stdin.echoMode = false;
        print(
            'Please insert a master Password: ');
        masterPasswordClear = stdin.readLineSync();
        print('Confirm password: ');
        String? masterPasswordConfirm = stdin.readLineSync();
        if (masterPasswordClear == masterPasswordConfirm) {
          break;
        }
        else {
          print('That didn\'t work, please try again');
        }
      }
      var masterPasswordClearEncoded = utf8.encode(masterPasswordClear!);
      var masterPasswordHashed = sha512.convert(masterPasswordClearEncoded);

      while(true) {
        stdin.echoMode = false;
        print('Set an app password:');
        appPasswordClear = stdin.readLineSync();
        print('Please confirm password:');
        String? appPasswordConfirm = stdin.readLineSync();
        if(appPasswordClear == appPasswordConfirm) {
          break;
        }
        else {
          print('That didn\'t work, please try again!');
        }
      }

      var appPasswordClearEncoded = utf8.encode(appPasswordClear);
      var appPasswordHashed = sha512.convert(appPasswordClearEncoded);


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
          "masterKey": "$masterPasswordHashed",
          "appPassword": "$appPasswordHashed"
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
    appPassword = configJson['app']['appPassword'].toString();
    return;
  }

}

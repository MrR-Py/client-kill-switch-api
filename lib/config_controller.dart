import 'dart:convert';
import 'dart:io';

class Config {
  dynamic dbPort;
  dynamic dbAddress;
  dynamic dbName;

  dynamic serverPort;
  //dynamic serverAddress;

  Config(String configFilePath) {
    var jsonTemplate = """
    {
      "database": {
        "port": 27017,
        "address": "localhost",
        "name": "client-kill-switch"
      },
      "server" :{
        "port": 8080
      }
    }
    """;

    if (!File(configFilePath).existsSync()) {
      var fileCreate = File(configFilePath);
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
    return;
  }
}

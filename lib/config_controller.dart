import 'dart:convert';
import 'dart:io';

class Config {
  dynamic dbPort;
  dynamic dbAddress;
  dynamic dbName;

  dynamic serverPort;
  //dynamic serverAddress;

  Config(String configFilePath) {
    // TODO: create file if needed
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
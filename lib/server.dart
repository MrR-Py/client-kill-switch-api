import 'package:client_kill_switch_api/config_controller.dart';
import 'package:client_kill_switch_api/database_controller.dart';

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

class Server {
  var _router;

  Router init(Database database, Config config) {
    Response _rootHandler(Request request) {
      return Response.ok('Client Kill Switch v0.0.1');
    }

    Future<Response> _getPermissionToRun(Request request) async {
      var jsonTemplateString = """
      {
        "expirationDate": "1970-01-01",
        "allowExecution": false,
        "systemTime": "1970-01-01"
      }
      """;

      var jsonTemplate = jsonDecode(jsonTemplateString);
      assert(jsonTemplate is Map);

      var appUID = params(request, 'uid');
      final String query = await request.readAsString();
      Map queryParams = Uri(query: query).queryParameters;
      if (queryParams.isNotEmpty) {
        var jsonBody = jsonDecode(queryParams.keys.first);
        assert(jsonBody is Map);
        var apiKeyUserInput = jsonBody['apiKey'];

        List<String> checkResult =
            await database.checkPermission(appUID, apiKeyUserInput);
        jsonTemplate['expirationDate'] = checkResult[0].toString();
        jsonTemplate['allowExecution'] = checkResult[1].toString();
        jsonTemplate['systemTime'] = "${DateTime.now().year}-${DateTime.now().month}-"
            "${DateTime.now().day}";

        return Response.ok(base64.encode(utf8.encode(jsonTemplate.toString())));
      }
      return Response.internalServerError();
    }

    Future<Response> _modifyAppList(Request request) async {
      if (request.method == 'POST') {
        final String query = await request
            .readAsString(); //await base64.decode(utf8.decode(request.readAsString() as List<int>)) as String;
        Map queryParams = Uri(query: query).queryParameters;
        if (queryParams.isNotEmpty) {
          var jsonBody = jsonDecode(queryParams.keys.first);
          assert(jsonBody is Map);
          var masterKey = jsonBody['masterKey'];

          if (masterKey != config.appMasterKey)
            return Response.unauthorized("Bad API Key");

          int command = int.parse(jsonBody['command']);
          switch (command) {
            case 1:
            // add app
              var appName = jsonBody['appName'];
              var appUID = jsonBody['appUID'];
              var expirationDate = jsonBody['expirationDate'];
              var apiKey = jsonBody['apiKey'];
              var allowExecution = jsonBody['allowExecution'];
              var exitCode = await database.addApp(appName, expirationDate, appUID, apiKey, allowExecution);
              switch(exitCode) {
                case -1:
                  return Response.internalServerError();
                case 0:
                  return Response.ok("200 OK");
                case 1:
                  return Response.ok('{"errorCode": "1"}');
              }
              break;

            case 2:
            // delete app
              var appUID = jsonBody['appUID'];
              var apiKey = jsonBody['apiKey'];
              await database.deleteApp(appUID, apiKey);
              break;

            case 3:
            // modify app
              var appUID = jsonBody['appUID'];
              var apiKey = jsonBody['apiKey'];
              List<dynamic> changes = jsonBody['changes'];
              for (int i = 0; i < changes.length; i++) {
                var varToChange = changes[i][0];
                var args = changes[i][1];
                await database.modApp(appUID, apiKey, varToChange, args);
              }
              break;
          }
          return Response.ok("200 OK");
        }
        return Response.internalServerError();
      }
      return Response.badRequest();
    }

    // Configure routes
    _router = Router()
      ..get('/', _rootHandler)
      ..get('/app/<uid>', _getPermissionToRun)
      ..post('/modApp', _modifyAppList);

    return _router;
  }
}

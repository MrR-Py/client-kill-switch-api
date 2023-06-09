import 'package:client_kill_switch_api/config_controller.dart';
import 'package:client_kill_switch_api/database_controller.dart';

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

class Server {
  var _router;

  Router init(Database database) {
    Response _rootHandler(Request request) {
      return Response.ok('Client Kill Switch v0.0.1');
    }

    // TODO: RSA implementation (Maybe ECC?)
    Response _getRsaPublicKey(Request request) {
      return Response.ok('Feature not yet implemented');
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

        return Response.ok(jsonTemplate.toString());
      }
      return Response.internalServerError();
    }

    Future<Response> _modifyAppList(Request request) async {
      if (request.method == 'POST') {
        final String query = await request.readAsString();
        Map queryParams = Uri(query: query).queryParameters;
        if (queryParams.isNotEmpty) {
          var jsonBody = jsonDecode(queryParams.keys.first);
          assert(jsonBody is Map);
          var masterKey = jsonBody['apiKey'];
          // TODO: Compare masterKey to actual Key for security
          int command = jsonBody['command'] as int;
          switch (command) {
            case 1:
              // add app
              var appUID = jsonBody['appUID'];
              var expirationDate = jsonBody['expirationDate'];
              var apiKey = jsonBody['apiKey'];
              break;

            case 2:
              // delete app
              var appUID = jsonBody['appUID'];
              var apiKey = jsonBody['apiKey'];
              break;

            case 3:
              // modify app
              var appUID = jsonBody['appUID'];
              var apiKey = jsonBody['apiKey'];
              List<List> changes = jsonBody['changes'];
              for (int i = 0; i < changes.length; i++) {
                switch (changes[i][0]) {
                  case 'appUID':
                    // TODO: change app UID
                    break;
                  case 'apiKey':
                    // TODO: change the api key
                    break;
                  case 'expirationDate':
                }
              }
              break;
          }
        }
        return Response.internalServerError();
      }
      return Response.badRequest();
    }

    // Configure routes
    _router = Router()
      ..get('/', _rootHandler)
      ..get('/rsaPublicKey', _getRsaPublicKey)
      ..get('/app/<uid>', _getPermissionToRun)
      ..post('/modApp', _modifyAppList);

    return _router;
  }
}

import 'package:client_kill_switch_api/config_controller.dart';
import 'package:client_kill_switch_api/database_controller.dart';

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Server {
  var _router;

  // Init function is needed because writing that code in the constructor is
  // 1) Bad practice, and
  // 2) Not possible as it would result in multiple syntax errors.
  Router init(Database database, Config config) {
    Response rootHandler(Request request) {
      return Response.ok('Client Kill Switch v0.0.1');
    }

    // Checks the database with database.checkPermission and returns the result.
    Future<Response> getPermissionToRun(Request request) async {

      // Json template with placeholders
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

        // Edit JSON template with the correct data.
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

    // Function that gets called to modify database entries of apps. Needs the
    // master password of the app, which is different from any API key and
    // the general app password.
    Future<Response> modifyAppList(Request request) async {
      if (request.method == 'POST') {
        final String query = await request
            .readAsString();
        Map queryParams = Uri(query: query).queryParameters;
        if (queryParams.isNotEmpty) {
          var jsonBody = jsonDecode(queryParams.keys.first);
          assert(jsonBody is Map);
          var masterKey = jsonBody['masterKey'];

          if (masterKey != config.appMasterKey) {
            return Response.unauthorized("Bad API Key");
          }

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
                  return Response.ok('{"code": "0", "message": "ok"}');
                case 1:
                  return Response.ok('{"code": "1", '
                      '"message":"app already exists"}');
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
          return Response.ok('{"code": "0", "message": "ok"}');
        }
        return Response.internalServerError();
      }
      return Response.badRequest();
    }

    // Configure routes
    _router = Router()
      ..get('/', rootHandler)
      ..get('/app/<uid>', getPermissionToRun)
      ..post('/modApp', modifyAppList);

    return _router;
  }
}

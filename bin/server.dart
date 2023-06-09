import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/rsaPublicKey', _getRsaPublicKey)
  ..get('/app/<uid>/<encryptedPassword>', _getPermissionToRun)
  ..post('/modApp', _modifyAppList)
;

Response _rootHandler(Request request) {
  return Response.ok('Client Kill Switch v0.0.1');
}

Response _getRsaPublicKey(Request request) {
  return Response.ok('Feature not yet implemented');
}

Response _getPermissionToRun(Request request) {
  final encryptedUid = request.params['encryptedUid'];
  final encryptedPassword = request.params['encryptedPassword'];
  return Response.ok('Feature not yet implemented');
}

Future<Response> _modifyAppList(Request request) async {
  if (request.method == 'POST') {
      final String query = await request.readAsString();
      Map queryParams = Uri(query: query).queryParameters;
      if(queryParams.isNotEmpty) {
      var jsonBody = jsonDecode(queryParams.keys.first);
      assert(jsonBody is Map);
      var masterKey = jsonBody['apiKey'];
      // TODO: Compare masterKey to actual Key for security
      int command = jsonBody['command'] as int;
      switch(command){
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
          for(int i = 0; i < changes.length; i++) {
            switch(changes[i][0]) {
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

  void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}

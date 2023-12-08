import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../db/setup_db.dart';

final _db = DBSetup();

String defaultDate = DateTime.now().toString().substring(0, 10);
int defaultQuantity = 1;

class IngredientController {
  Future getAllIngredients(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List data = [];

    try {
      var query =
          'select i.ingredient_id, i.name, i.icon, c.name from ingredient i, category c where i.category_id = c.category_id';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          var ingredient = toJson(row.colAt(0), row.colAt(1), row.colAt(2),
              defaultDate, defaultQuantity, row.colAt(3));
          print(row.assoc());
          data.add(ingredient);
        }
        // 200: OK
        return Response.ok(json.encode({'success': true, 'data': data}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 404: Not Found
        return Response.notFound(
            json.encode({'success': false, 'error': 'No ingredients found'}));
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  Future getIngredientsByCategory(Request req, String category) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List data = [];

    try {
      var query =
          'select i.ingredient_id, i.name, i.icon, c.name from ingredient i, category c where i.category_id = c.category_id and c.name = "$category"';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          var ingredient = toJson(row.colAt(0), row.colAt(1), row.colAt(2),
              defaultDate, defaultQuantity, row.colAt(3));
          data.add(ingredient);
        }
        // 200: OK
        return Response.ok(json.encode({'success': true, 'data': data}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 404: Not Found
        return Response.notFound(
            json.encode({'success': false, 'error': 'No ingredients found'}));
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  Future getAllTags(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List data = [];

    try {
      var query = 'select i.ingredient_id, i.name, c.name, i.icon from ingredient i, category c where i.category_id = c.category_id';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          var tag = toJsonbyTag(row.colAt(0), row.colAt(1), row.colAt(2), row.colAt(3));
          data.add(tag);
        }
        // 200: OK
        return Response.ok(json.encode({'success': true, 'data': data}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 404: Not Found
        return Response.notFound(
            json.encode({'success': false, 'error': 'No tags found'}));
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }
}

toJson(id, name, icon, date, quantity, category) => {
      'ingredientId': id,
      'ingredientName': name,
      'icon': icon,
      'expiryDate': date,
      'quantity': quantity,
      'category': category
    };

toJsonbyTag(id, name, category, icon) => {
      'ingredientId': id,
      'ingredientName': name,
      'category': category,
      'icon': icon
    };

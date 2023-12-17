import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../db/setup_db.dart';

final _db = DBSetup();

class PantryController {
  // Test data
  final List data = json.decode(File('pantry.json').readAsStringSync());

  Future getAllIngredients(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List categorizedData = [];

    try {
      var query =
          'select p.pantry_ingredient_id, i.name, i.icon, p.experation_date, p.quantity, c.name as category from pantry_ingredient p, ingredient i, category c where p.ingredient_id = i.ingredient_id and i.category_id = c.category_id';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          var ingredient = toJson(row.colAt(0), row.colAt(1), row.colAt(2),
              row.colAt(3), row.colAt(4), row.colAt(5));
          print(row.assoc());
          categorizedData.add(ingredient);
        }
        // 200: OK
        return Response.ok(
            json.encode({'success': true, 'data': categorizedData}),
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

    try {
      // 400: Bad Request
      if (category.isEmpty) {
        return Response.notFound(
            json.encode({'success': false, 'error': 'Category is empty'}));
      } else {
        final List categorizedData = [];
        var query =
            'select p.pantry_ingredient_id, i.name, i.icon, p.experation_date, p.quantity, c.name as category from pantry_ingredient p, ingredient i, category c where p.ingredient_id = i.ingredient_id and i.category_id = c.category_id and c.name = "$category"';
        var result = await connObj.execute(query);
        if (result.rows.isNotEmpty) {
          for (final row in result.rows) {
            var ingredient = toJson(row.colAt(0), row.colAt(1), row.colAt(2),
                row.colAt(3), row.colAt(4), row.colAt(5));
            print(row.assoc());
            categorizedData.add(ingredient);
          }
          // 200: OK
          return Response.ok(
              json.encode({'success': true, 'data': categorizedData}),
              headers: {'Content-Type': 'application/json'});
        } else {
          return Response.notFound(json.encode(
              {'success': false, 'error': 'Category $category not found'}));
        }
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  Future getIngredientById(Request req, String ingredientId) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    try {
      // 400: Bad Request
      if (ingredientId.isEmpty) {
        return Response.notFound(
            json.encode({'success': false, 'error': 'Ingredient is empty'}));
      }

      final ingredientIdN = int.tryParse(ingredientId);
      var query =
          'select p.pantry_ingredient_id, i.name, i.icon, p.experation_date, p.quantity, c.name as category from pantry_ingredient p, ingredient i, category c where p.ingredient_id = i.ingredient_id and i.category_id = c.category_id and p.pantry_ingredient_id = $ingredientIdN';
      var result = await connObj.execute(query);
      if (result.rows.isNotEmpty) {
        final ingredientData = toJson(
            result.rows.first.colAt(0),
            result.rows.first.colAt(1),
            result.rows.first.colAt(2),
            result.rows.first.colAt(3),
            result.rows.first.colAt(4),
            result.rows.first.colAt(5));
        // 200: OK
        return Response.ok(
            json.encode({'success': true, 'data': ingredientData}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 404: Not Found
        return Response.notFound(json.encode(
            {'success': false, 'error': 'Ingredient $ingredientId not found'}));
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  Future addIngredients(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    try {
      final payload = await req.readAsString();
      final List<Map<String, dynamic>> ingredients =
          List<Map<String, dynamic>>.from(
              json.decode(payload).map((item) => item as Map<String, dynamic>));
      print('ingredients added');

      // 400: Bad Request
      if (ingredients.isEmpty) {
        return Response.badRequest(
            body: json
                .encode({'success': false, 'error': 'No ingredients provided'}),
            headers: {'Content-Type': 'application/json'});
      }

      final List<Map<String, dynamic>> existingIngredients = [];

      for (final ingredient in ingredients) {
        if (ingredient['ingredientId'] == null ||
            ingredient['ingredientName'] == null ||
            ingredient['expiryDate'] == null ||
            ingredient['quantity'] == null ||
            ingredient['category'] == null) {
          return Response.badRequest(
              body: json.encode({
                'success': false,
                'error':
                    'Missing ingredientId, name, category, quantity, or unit'
              }),
              headers: {'Content-Type': 'application/json'});
        }

        if (existingIngredients.any((element) =>
            element['ingredientId'] == ingredient['ingredientId'])) {
          return Response(409,
              body: json.encode({
                'success': false,
                'error':
                    'Ingredient ${ingredient['ingredientId']} already exists'
              }),
              headers: {'Content-Type': 'application/json'});
        }

        existingIngredients.add(ingredient);
      }

      final List<Map<String, dynamic>> addedIngredients = [];
      var pantryId = 1;

      for (final ingredient in existingIngredients) {
        var query =
            'insert into pantry_ingredient (pantry_ingredient_id, pantry_id, ingredient_id, experation_date, quantity) values (null, $pantryId, ${ingredient['ingredientId']}, "${ingredient['expiryDate']}", ${ingredient['quantity']})';
        var result = await connObj.execute(query);
        if (result.affectedRows == BigInt.from(1)) {
          addedIngredients.add(ingredient);
        } else {
          return Response(500,
              body: json.encode({
                'success': false,
                'error':
                    'Failed to add ingredient ${ingredient['ingredientId']}'
              }),
              headers: {'Content-Type': 'application/json'});
        }
      }

      // 201: Created
      return Response(201,
          body: json.encode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  Future addIngredientToCart(Request req, String ingredientId) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    try {
      // 400: Bad Request
      if (ingredientId.isEmpty) {
        return Response.notFound(
            json.encode({'success': false, 'error': 'Ingredient is empty'}));
      }
      final ingredientIdN = int.tryParse(ingredientId);
      var query =
          'insert into cart_ingredient (cart_ingredient_id, cart_id, ingredient_id) values (null, 1, $ingredientIdN)';

      var result = await connObj.execute(query);
      if (result.affectedRows == BigInt.from(1)) {
        // 201: Created
        return Response(201,
            body: json.encode({'success': true}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 500: Internal Server Error
        return Response(500,
            body: json.encode({
              'success': false,
              'error': 'Failed to add ingredient $ingredientIdN to cart'
            }),
            headers: {'Content-Type': 'application/json'});
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  Future<Response> updateIngredient(Request req, String ingredientId) async {
    final payload = await req.readAsString();
    final quantity = json.decode(payload)['quantity'];
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = data.firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);

    // 400: Bad Request
    if (quantity <= 0) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Quantity must be greater than 0'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 404: Not Found
    else if (ingredientData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Ingredient $ingredientId not found'}));
    }

    // 200: OK
    else {
      ingredientData['quantity'] = quantity;

      File('pantry.json').writeAsStringSync(json.encode(data));

      return Response.ok(json.encode({'success': true}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future deleteIngredient(Request req, String ingredientId) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    try {
      // 400: Bad Request
      if (ingredientId.isEmpty) {
        return Response.notFound(
            json.encode({'success': false, 'error': 'Ingredient is empty'}));
      }
      final ingredientIdN = int.tryParse(ingredientId);
      var query =
          'delete from pantry_ingredient where pantry_ingredient_id = $ingredientIdN';

      var result = await connObj.execute(query);
      if (result.affectedRows == BigInt.from(1)) {
        // 200: OK
        return Response(200,
            body: json.encode({'success': true}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 500: Internal Server Error
        return Response(500,
            body: json.encode({
              'success': false,
              'error': 'Failed to delete ingredient $ingredientIdN'
            }),
            headers: {'Content-Type': 'application/json'});
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
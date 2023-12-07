import 'dart:io';
import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../db/setup_db.dart';

final _db = DBSetup();

class CartController {
  final List data = json.decode(File('cart.json').readAsStringSync());

  Future getAllIngredients(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List ingredients = [];

    try {
      var query =
          'select c.cart_ingredient_id, i.name, i.icon from ingredient i, cart_ingredient c where c.ingredient_id = i.ingredient_id';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          var ingredient = toJson(row.colAt(0), row.colAt(1), row.colAt(2));
          print(row.assoc());
          ingredients.add(ingredient);
        }
        // 200: OK
        return Response.ok(json.encode({'success': true, 'data': ingredients}),
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
    }
  }

  getIngredientById(Request req, String ingredientId) {
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = data.firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);

    // 404: Not Found
    if (ingredientData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Ingredient $ingredientId not found'}));
    }

    // 200: OK
    else {
      return Response.ok(json.encode({'success': true, 'data': ingredientData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future addIngredients(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    try {
      final payload = await req.readAsString();
       final List<Map<String, dynamic>> ingredients = List<Map<String, dynamic>>.from(json.decode(payload).map((item) => item as Map<String, dynamic>));

      // 400: Bad Request
      if (ingredients.isEmpty) {
        return Response.badRequest(
            body: json.encode({
              'success': false,
              'error': 'Missing ingredients'
            }),
            headers: {'Content-Type': 'application/json'});
      }

      // 409: Conflict
      // else if (data.any((element) =>
      //     element['ingredientId'] == ingredient['ingredientId'])) {
      //   return Response(409,
      //       body: json.encode({
      //         'success': false,
      //         'error': 'Ingredient ${ingredient['ingredientId']} already exists'
      //       }),
      //       headers: {'Content-Type': 'application/json'});
      // }

      // 201: Created
      else {
        for (final ingredient in ingredients) {
          var cartId = 1;
          var query =
              'insert into cart_ingredient (cart_ingredient_id, cart_id, ingredient_id) values (null, $cartId, ${ingredient['ingredientId']})';
          var result = await connObj.execute(query);
        }

        return Response(201,
            body: json.encode({'success': true, 'data': ingredients}),
            headers: {'Content-Type': 'application/json'});
      }

    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
    }
  }

  Future<Response> addIngredientToPantry(
      Request req, String ingredientId) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredient = json.decode(payload);

    // 400: Bad Request
    if (ingredient['ingredientId'] == null ||
        ingredient['ingredientName'] == null ||
        ingredient['expiryDate'] == null ||
        ingredient['quantity'] == null ||
        ingredient['category'] == null) {
      return Response.badRequest(
          body: json.encode({
            'success': false,
            'error': 'Missing ingredientId, name, category, quantity, or unit'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 409: Conflict
    if (data.any(
        (element) => element['ingredientId'] == ingredient['ingredientId'])) {
      return Response(409,
          body: json.encode({
            'success': false,
            'error': 'Ingredient ${ingredient['ingredientId']} already exists'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 201: Created
    else {
      data.add(ingredient);
      File('pantry.json').writeAsStringSync(json.encode(data));
      return Response(201,
          body: json.encode({'success': true, 'data': ingredient}),
          headers: {'Content-Type': 'application/json'});
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

      return Response.ok(json.encode({'success': true, 'data': ingredientData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future deleteIngredient(Request req, String cartId) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    try {
      // 404: Not Found
      if (cartId.isEmpty) {
        return Response.notFound(json.encode(
            {'success': false, 'error': 'Cart ID not found'}));
      }

      final cartIdN = int.tryParse(cartId);
      var query =
          'delete from cart_ingredient where cart_ingredient_id = $cartIdN';

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
              'error': 'Failed to delete ingredient $cartIdN'
            }),
            headers: {'Content-Type': 'application/json'});
      }

    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
    }

      

  //   final ingredientIdN = int.tryParse(ingredientId);
  //   final ingredientData = data.firstWhere(
  //       (element) => element['ingredientId'] == ingredientIdN,
  //       orElse: () => null);

  //   // 404: Not Found
  //   if (ingredientData == null) {
  //     return Response.notFound(json.encode(
  //         {'success': false, 'error': 'Ingredient $ingredientId not found'}));
  //   }

  //   // 200: OK
  //   else {
  //     data.remove(ingredientData);

  //     File('pantry.json').writeAsStringSync(json.encode(data));

  //     return Response.ok(json.encode({'success': true, 'data': ingredientData}),
  //         headers: {'Content-Type': 'application/json'});
  //   }
  }
}

toJson(id, name, icon) => {
      'cartId': id,
      'ingredientName': name,
      'icon': icon
    };

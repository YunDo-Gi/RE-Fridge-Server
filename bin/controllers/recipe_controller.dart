import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';

import '../db/setup_db.dart';

final _db = DBSetup();

class RecipeController {
  // Test data
  final List data = json.decode(File('recipe.json').readAsStringSync());
  final List pantry = json.decode(File('pantry.json').readAsStringSync());

  Future getAllRecipes(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List recipes = [];

    // Get all recipes
    try {
      var query =
          'select r.recipe_id, r.name, group_concat(i.name) as ingredients from recipe r join recipe_ingredient ri on r.recipe_id = ri.recipe_id join ingredient i on i.ingredient_id = ri.ingredient_id group by r.recipe_id';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          var recipe = toJson(
            row.colAt(0),
            row.colAt(1),
            row.colAt(2),
          );
          print(row.assoc());
          recipes.add(recipe);
        }
        // 200: OK
        return Response.ok(json.encode({'success': true, 'data': recipes}),
            headers: {'Content-Type': 'application/json'});
      } else {
        // 404: Not Found
        return Response.notFound(
            json.encode({'success': false, 'error': 'No recipe found'}));
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }
  }

  getFullfilledRecipes(Request req) async {
    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    final List ingredients = [];

    // Get all ingredients
    try {
      var query =
          'select i.name from pantry_ingredient pi, ingredient i where pi.ingredient_id = i.ingredient_id';
      var result = await connObj.execute(query);

      if (result.rows.isNotEmpty) {
        for (final row in result.rows) {
          ingredients.add(row.colAt(0));
        }
      } else {
        // 404: Not Found
        return Response.notFound(
            json.encode({'success': false, 'error': 'No ingredient found'}));
      }
    } catch (e) {
      print("Exception: $e");
    }

    // 400: Bad Request
    if (ingredients.isEmpty) {
      return Response.badRequest(
          body: json.encode({'success': false, 'error': 'Missing ingredients'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      final List fullfilledRecipes = [];

      try {
        var query =
            'select r.recipe_id, r.name, group_concat(i.name) as ingredients from recipe r join recipe_ingredient ri on r.recipe_id = ri.recipe_id join ingredient i on i.ingredient_id = ri.ingredient_id group by r.recipe_id';
        var result = await connObj.execute(query);

        if (result.rows.isNotEmpty) {
          for (final row in result.rows) {
            var recipe = toJson(
              row.colAt(0),
              row.colAt(1),
              row.colAt(2),
            );
            recipes.add(recipe);
          }

          // Count number of fullfilled ingredients
          for (var recipe in recipes) {
            var count = 0;
            for (var ingredient in recipe['ingredients']) {
              if (ingredients.contains(ingredient)) {
                count++;
              } else {
                continue;
              }
            }

            // Add fullfill count to recipe
            recipe['fullfillCount'] = count;
            fullfilledRecipes.add(recipe);

            // Add recipe to fullfilledRecipes if at least half of the ingredients are fullfilled
            // if (recipe['ingredients'].length / 2 <= count) {
            //   recipe['fullfillCount'] = count;
            //   fullfilledRecipes.add(recipe);
            // } else {
            //   continue;
            // }
          }
        } else {
          // 404: Not Found
          return Response.notFound(
              json.encode({'success': false, 'error': 'No recipe found'}));
        }
      } catch (e) {
        print("Exception: $e");
      } finally {
        await connObj.close();
        print("dbConnector: Connection closed");
      }

      // Sort recipes by number of fullfilled ingredients
      fullfilledRecipes
          .sort((a, b) => b['fullfillCount'].compareTo(a['fullfillCount']));

      return Response.ok(
          json.encode({'success': true, 'data': fullfilledRecipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeById(Request req, String recipeId) {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 200: OK
    else {
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getNeededIngredients(Request req, String recipeId) async {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 200: OK
    else {
      final List neededIngredients = [];
      for (var ingredient in recipeData['ingredients']) {
        if (!pantry.contains(ingredient)) {
          neededIngredients.add(ingredient);
        } else {
          continue;
        }
      }

      return Response.ok(
          json.encode({'success': true, 'data': neededIngredients}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  Future<Response> addRecipe(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> recipe = json.decode(payload);

    // 400: Bad Request
    if (recipe['recipeId'] == null ||
        recipe['recipeName'] == null ||
        recipe['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid recipe data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 409: Conflict
    if (data.any((element) => element['recipeId'] == recipe['recipeId'])) {
      return Response(409,
          body: json.encode({
            'success': false,
            'error': 'Recipe ${recipe['recipeId']} already exists'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 201: Created
    else {
      data.add(recipe);
      return Response(HttpStatus.created,
          body: json.encode({'success': true, 'data': recipe}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  deleteRecipe(Request req, String recipeId) {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 200: OK
    else {
      data.remove(recipeData);
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }
}

toJson(recipeId, recipeName, ingredients) {
  List<String> ingredientsList = ingredients.split(",");

  return {
    'recipeId': recipeId,
    'recipeName': recipeName,
    'ingredients': ingredientsList,
  };
}

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

  // functions for future development

  Future<Response> addRecipe(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> recipe = json.decode(payload);

    // 400: Bad Request
    if (recipe['recipeName'] == null || recipe['ingredients'] == null) {
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

    // Connect to database
    final conn = _db.dbConnector();
    var connObj = await conn;

    // Add recipe
    try {
      var query =
          'insert into recipe (recipe_id, name) values (null, "${recipe['recipeName']}")';
      var result = await connObj.execute(query);
      print(result.rows.first.colAt(0));

      if (result.rows.isEmpty) {
        // 404: Not Found
        return Response.notFound(
            json.encode({'success': false, 'error': 'Recipe not found'}));
      } else {
        var recipeId = result.rows.first.colAt(0);
        print("Recipe added");
        // Add recipe ingredients
        try {
          for (var ingredient in recipe['ingredients']) {
            var query =
                "select ingredient_id from ingredient where name = '$ingredient'";
            var result = await connObj.execute(query);

            if (result.rows.isEmpty) {
              // 404: Not Found
              return Response.notFound(json
                  .encode({'success': false, 'error': 'Ingredient not found'}));
            } else {
              var ingredientId = result.rows.first.colAt(0);
              query =
                  'insert into recipe_ingredient (recipe_ingredient_id, recipe_id, ingredient_id) values (null, $recipeId, $ingredientId)';
              result = await connObj.execute(query);

              if (result.rows.isEmpty) {
                // 404: Not Found
                return Response.notFound(json.encode({
                  'success': false,
                  'error': 'Ingredient $ingredient not found'
                }));
              } else {
                // 201: Created
                return Response(201,
                    body: json.encode({'success': true}),
                    headers: {'Content-Type': 'application/json'});
              }
            }
          }
        } catch (e) {
          print("Exception: $e");
        }
      }
    } catch (e) {
      print("Exception: $e");
    } finally {
      await connObj.close();
      print("dbConnector: Connection closed");
    }

    return Response(201,
        body: json.encode({'success': true, 'data': recipe}),
        headers: {'Content-Type': 'application/json'});
  }

  Future<Response> deleteRecipe(Request req, String recipeId) async {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    } else {
      // Connect to database
      final conn = _db.dbConnector();
      var connObj = await conn;

      try {
        var query = 'delete from recipe where recipe_id = $recipeIdN';
        var result = await connObj.execute(query);

        if (result.rows.isEmpty) {
          // 404: Not Found
          return Response.notFound(
              json.encode({'success': false, 'error': 'Recipe not found'}));
        } else {
          print("Recipe deleted");
          // 200: OK
          return Response.ok(json.encode({'success': true}),
              headers: {'Content-Type': 'application/json'});
        }
      } catch (e) {
        print("Exception: $e");

        return Response.notFound(
            json.encode({'success': false, 'error': 'Recipe not found'}));
      } finally {
        await connObj.close();
        print("dbConnector: Connection closed");
      }
    }
  }

  updateRecipe(Request req, String recipeId) async {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 400: Bad Request
    final payload = await req.readAsString();
    final Map<String, dynamic> recipe = json.decode(payload);
    if (recipe['recipeName'] == null || recipe['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid recipe data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      recipeData['recipeName'] = recipe['recipeName'];
      recipeData['ingredients'] = recipe['ingredients'];
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  addIngredient(Request req, String recipeId) async {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 400: Bad Request
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredient = json.decode(payload);
    if (ingredient['ingredientName'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      recipeData['ingredients'].add(ingredient['ingredientName']);
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  deleteIngredient(Request req, String recipeId, String ingredientId) async {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 400: Bad Request
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = recipeData['ingredients'].firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);
    if (ingredientData == null) {
      return Response.badRequest(
          body: json.encode({
            'success': false,
            'error': 'Ingredient $ingredientId not found'
          }),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      recipeData['ingredients'].remove(ingredientData);
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  updateIngredient(Request req, String recipeId, String ingredientId) async {
    final recipeIdN = int.tryParse(recipeId);
    final recipeData = data.firstWhere(
        (element) => element['recipeId'] == recipeIdN,
        orElse: () => null);

    // 404: Not Found
    if (recipeData == null) {
      return Response.notFound(json
          .encode({'success': false, 'error': 'Recipe $recipeId not found'}));
    }

    // 400: Bad Request
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = recipeData['ingredients'].firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredient = json.decode(payload);
    if (ingredientData == null || ingredient['ingredientName'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      ingredientData['ingredientName'] = ingredient['ingredientName'];
      return Response.ok(json.encode({'success': true, 'data': recipeData}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredient(Request req, String ingredientId) async {
    final ingredientIdN = int.tryParse(ingredientId);
    final ingredientData = pantry.firstWhere(
        (element) => element['ingredientId'] == ingredientIdN,
        orElse: () => null);

    // 404: Not Found
    if (ingredientData == null) {
      return Response.notFound(json.encode(
          {'success': false, 'error': 'Ingredient $ingredientId not found'}));
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (recipe['ingredients'].contains(ingredientData['ingredientName'])) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredients(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredients = json.decode(payload);

    // 400: Bad Request
    if (ingredients['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (recipe['ingredients'].containsAll(ingredients['ingredients'])) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredientsAnd(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredients = json.decode(payload);

    // 400: Bad Request
    if (ingredients['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (recipe['ingredients'].containsAll(ingredients['ingredients'])) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredientsOr(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredients = json.decode(payload);

    // 400: Bad Request
    if (ingredients['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (recipe['ingredients']
            .any((element) => ingredients['ingredients'].contains(element))) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredientsNot(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredients = json.decode(payload);

    // 400: Bad Request
    if (ingredients['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (!recipe['ingredients']
            .any((element) => ingredients['ingredients'].contains(element))) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredientsAndNot(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredients = json.decode(payload);

    // 400: Bad Request
    if (ingredients['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (!recipe['ingredients'].any(
                (element) => ingredients['ingredients'].contains(element)) &&
            recipe['ingredients'].containsAll(ingredients['ingredients'])) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
          headers: {'Content-Type': 'application/json'});
    }
  }

  getRecipeByIngredientsOrNot(Request req) async {
    final payload = await req.readAsString();
    final Map<String, dynamic> ingredients = json.decode(payload);

    // 400: Bad Request
    if (ingredients['ingredients'] == null) {
      return Response.badRequest(
          body: json.encode(
              {'success': false, 'error': 'Invalid ingredient data provided'}),
          headers: {'Content-Type': 'application/json'});
    }

    // 200: OK
    else {
      final List recipes = [];
      for (var recipe in data) {
        if (!recipe['ingredients'].any(
                (element) => ingredients['ingredients'].contains(element)) ||
            recipe['ingredients'].containsAll(ingredients['ingredients'])) {
          recipes.add(recipe);
        } else {
          continue;
        }
      }

      return Response.ok(json.encode({'success': true, 'data': recipes}),
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
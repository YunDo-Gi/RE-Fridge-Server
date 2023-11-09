import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/recipe_controller.dart';

final _recipeController = RecipeController();

class RecipeApi {
  Handler get handler {

    var router = Router();

    // GET: Show all recipes
    router.get('/', _recipeController.getAllRecipes);

    // GET: Show recipes that fullfill more than half of ingredients needed
    router.get('/fullfill', _recipeController.getFullfilledRecipes);

    // Show specific recipe
    router.get('/<recipeId>', _recipeController.getRecipeById);

    // POST: Add recipe
    router.post('/', _recipeController.addRecipe);

    // DELETE: Delete recipe
    router.delete('/<recipeId>', _recipeController.deleteRecipe);
        

    return router;
  }
}

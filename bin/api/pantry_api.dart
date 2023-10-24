import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/pantry_controller.dart';

class PantryApi {
  Handler get handler {
    final pantryController = PantryController();

    var router = Router();

    // GET: Show all ingredients in pantry
    router.get('/', pantryController.getAllIngredients);

    // GET: Show specific category in pantry
    router.get('/<category>', pantryController.getIngredientsByCategory);

    // Show specific ingredient in pantry
    router.get('/ingredient/<ingredientId>', pantryController.getIngredientById);

    // POST: Add ingredient to pantry
    router.post('/ingredient', pantryController.addIngredient);
    
    // PATCH: Update ingredient in pantry
    router.patch('/ingredient/<ingredientId>', pantryController.updateIngredient);

    // DELETE: Delete ingredient from pantry
    router.delete('/ingredient/<ingredientId>', pantryController.deleteIngredient);
        

    return router;
  }
}

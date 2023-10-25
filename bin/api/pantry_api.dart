import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/pantry_controller.dart';

final _pantryController = PantryController();

class PantryApi {
  Handler get handler {

    var router = Router();

    // GET: Show all ingredients in pantry
    router.get('/', _pantryController.getAllIngredients);

    // GET: Show specific category in pantry
    router.get('/<category>', _pantryController.getIngredientsByCategory);

    // Show specific ingredient in pantry
    router.get('/ingredient/<ingredientId>', _pantryController.getIngredientById);

    // POST: Add ingredient to pantry
    router.post('/ingredient', _pantryController.addIngredient);
    
    // PATCH: Update ingredient in pantry
    router.patch('/ingredient/<ingredientId>', _pantryController.updateIngredient);

    // DELETE: Delete ingredient from pantry
    router.delete('/ingredient/<ingredientId>', _pantryController.deleteIngredient);
        

    return router;
  }
}

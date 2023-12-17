import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/ingredient_controller.dart';

final _ingredientController = IngredientController();

class IngredientApi {
  Handler get handler {
    var router = Router();

    // GET: Show all ingredients
    router.get('/', _ingredientController.getAllIngredients);

    // GET: Show specific category of ingredients
    router.get(
        '/category/<category>', _ingredientController.getIngredientsByCategory);

    // GET: Show all tags
    router.get('/tag', _ingredientController.getAllTags);

    return router;
  }
}
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'pantry_api.dart';
import 'cart_api.dart';
import 'recipe_api.dart';

class InitApi {
  Handler get handler {
    var router = Router();
    
    router.mount('/pantry', PantryApi().handler);
    router.mount('/cart', CartApi().handler);
    router.mount('/recipe', RecipeApi().handler);

    return router;
  }
}
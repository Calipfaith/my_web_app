import '../models/product.dart';

class CatalogService {
  Future<List<Product>> getProducts() async {
    return products;
  }
}
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final categories = [
    {"name": "Men", "image": "assets/men.png"},
    {"name": "Women", "image": "assets/women.png"},
    {"name": "Electronics", "image": "assets/electronics.png"},
    {"name": "Accessories", "image": "assets/accessories.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                "Shop by category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3 / 2,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final name = category["name"] as String;
                  final image = category["image"] as String;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/productGrid',
                        arguments: {"category": name},
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Image.asset(
                                image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                "Recommended",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              // Simple horizontal list of recommended items
              Container(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _recommendedCard(context, "Sneakers", "assets/sneakers.png", 120),
                    _recommendedCard(context, "Handbag", "assets/handbag.png", 250),
                    _recommendedCard(context, "Headphones", "assets/headphones.png", 180),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recommendedCard(BuildContext context, String name, String image, double price) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/productDetail',
            arguments: {"name": name, "price": price, "image": image},
          );
        },
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Container(
            width: 120,
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
                SizedBox(height: 6),
                Text(
                  name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text("RM${price.toStringAsFixed(0)}"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

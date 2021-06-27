class Crypto {
  final String price;
  final String name;
  Crypto({required this.price, required this.name});
  factory Crypto.fromJson(json) {
    return Crypto(
        price: json['price'],
        name: json['name']
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'name': name
    };
  }
}


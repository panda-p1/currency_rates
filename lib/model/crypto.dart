import '../constants.dart';
import '../tools.dart';


class Crypto {
  final String price;
  final String name;
  final String queryName;
  final String? changePercent;
  Crypto({required this.price, required this.queryName, this.changePercent, required this.name});
  factory Crypto.fromJson(json) {
    return Crypto(
        price: json['price'],
        name: json['name'],
        queryName: json['queryName'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'name': name,
      'queryName': queryName
    };
  }
}


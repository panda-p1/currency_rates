import 'package:currencies_pages/screens/home_screen.dart';
Currency_Pairs stringCurPairsToEnum(String str) {
  try {
    return Currency_Pairs.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum stringCurPairsToEnum type!!");
    return Currency_Pairs.values.first;
  }
}

class Crypto {
  final String price;
  final String name;
  final Currency_Pairs type;
  Crypto({required this.price, required this.name, required this.type});
  factory Crypto.fromJson(json) {
    return Crypto(
        price: json['price'],
        name: json['name'],
        type: stringCurPairsToEnum(json['type'])
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'name': name,
      'type': type.toString().substring(type.toString().indexOf('.') + 1)
    };
  }
}


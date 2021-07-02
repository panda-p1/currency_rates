import '../constants.dart';
import '../tools.dart';


class Crypto {
  final String price;
  final String name;
  final Currency_Pairs type;
  Crypto({required this.price, required this.name, required this.type});
  factory Crypto.fromJson(json) {
    return Crypto(
        price: json['price'],
        name: json['name'],
        type: Utils.stringCurPairsToEnum(json['type'])
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'name': name,
      'type': Utils.getValueAfterDot(type)
    };
  }
}



enum Grad_Direction {
  up,
  down
}

String enumToString(Grad_Direction dir) {
  if(dir == Grad_Direction.down) {
    return 'down';
  }
  if(dir == Grad_Direction.up) {
    return 'up';
  }
  throw Exception();
}

T stringToEnum<T>(String str, Iterable<T> values) {
  try {
    return values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum type!!");
    return values.first;
  }
}


class Currencies {
  final num brent;
  final Grad_Direction brentChange;
  final num btc;
  final Grad_Direction btcChange;
  final num btcusd;
  final Grad_Direction btcusdChange;
  final num eur;
  final Grad_Direction eurChange;
  final num eurusd;
  final Grad_Direction eurusdChange;
  final num usd;
  final Grad_Direction usdChange;
  final double delay;
  final String time;

  Currencies({
    required this.brent, required this.brentChange,
    required this.btc, required this.btcChange, required this.btcusd, required this.btcusdChange,
    required this.eur, required this.eurChange, required this.eurusd, required this.eurusdChange,
    required this.usd, required this.usdChange, required this.delay, required this.time
  });

  factory Currencies.fromJson(json) {
    return Currencies(
        brent: json['brent'], brentChange: stringToEnum<Grad_Direction>(json['brentChange'],
        Grad_Direction.values), btc: json['btc'], btcChange: stringToEnum<Grad_Direction>(json['btcChange'], Grad_Direction.values), btcusd: json['btcusd'],
        btcusdChange: stringToEnum<Grad_Direction>(json['btcusdChange'], Grad_Direction.values),
        eur: json['eur'], eurChange: stringToEnum<Grad_Direction>(json['eurChange'], Grad_Direction.values), eurusd: json['eurusd'],
        eurusdChange: stringToEnum<Grad_Direction>(json['eurusdChange'], Grad_Direction.values), usd: json['usd'],
        usdChange: stringToEnum<Grad_Direction>(json['usdChange'], Grad_Direction.values),
        delay: json['delay'], time: json['time']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brent': brent, 'brentChange': enumToString(brentChange), 'btc': btc,
      'btcChange':enumToString(btcChange), 'btcusd': btcusd, 'btcusdChange':enumToString(btcusdChange), 'eur': eur,
      'eurChange':enumToString(eurChange), 'eurusd': eurusd, 'eurusdChange':enumToString(eurusdChange), 'usd': usd,
      'usdChange':enumToString(usdChange), 'delay': delay, 'time': time
    };
  }
}
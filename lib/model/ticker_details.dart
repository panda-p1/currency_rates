class TickerDetails {
  final String symbol;
  final String priceChange;
  final String priceChangePercent;
  final String weightedAvgPrice;
  final String prevClosePrice;
  final String lastPrice;
  final String lastQty;
  final String bidPrice;
  final String askPrice;
  final String openPrice;
  final String highPrice;
  final String lowPrice;
  final String volume;
  final String quoteVolume;
  final int openTime;
  final int closeTime;
  final int firstId;
  final int lastId;
  final int count;

  TickerDetails(
      {
        required this.symbol,
        required this.priceChange,
        required this.priceChangePercent,
        required this.weightedAvgPrice,
        required this.prevClosePrice,
        required this.lastPrice,
        required this.lastQty,
        required this.bidPrice,
        required this.askPrice,
        required this.openPrice,
        required this.highPrice,
        required this.lowPrice,
        required this.volume,
        required this.quoteVolume,
        required this.openTime,
        required this.closeTime,
        required this.firstId,
        required this.lastId,
        required this.count
      });

  factory TickerDetails.fromJson(Map<String, dynamic> json) => TickerDetails(
    symbol: json['symbol'],
    priceChange: json['priceChange'],
    priceChangePercent: json['priceChangePercent'],
    weightedAvgPrice : json['weightedAvgPrice'],
    prevClosePrice : json['prevClosePrice'],
    lastPrice : json['lastPrice'],
    lastQty : json['lastQty'],
    bidPrice : json['bidPrice'],
    askPrice : json['askPrice'],
    openPrice : json['openPrice'],
    highPrice : json['highPrice'],
    lowPrice : json['lowPrice'],
    volume : json['volume'],
    quoteVolume : json['quoteVolume'],
    openTime : json['openTime'],
    closeTime : json['closeTime'],
    firstId : json['firstId'],
    lastId : json['lastId'],
    count : json['count'],
  );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['symbol'] = this.symbol;
    data['priceChange'] = this.priceChange;
    data['priceChangePercent'] = this.priceChangePercent;
    data['weightedAvgPrice'] = this.weightedAvgPrice;
    data['prevClosePrice'] = this.prevClosePrice;
    data['lastPrice'] = this.lastPrice;
    data['lastQty'] = this.lastQty;
    data['bidPrice'] = this.bidPrice;
    data['askPrice'] = this.askPrice;
    data['openPrice'] = this.openPrice;
    data['highPrice'] = this.highPrice;
    data['lowPrice'] = this.lowPrice;
    data['volume'] = this.volume;
    data['quoteVolume'] = this.quoteVolume;
    data['openTime'] = this.openTime;
    data['closeTime'] = this.closeTime;
    data['firstId'] = this.firstId;
    data['lastId'] = this.lastId;
    data['count'] = this.count;
    return data;
  }
}
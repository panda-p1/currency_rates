const DEFAULT_DELAY = 4.0;

const double heightForSignal = 50;

enum Modal_RequestType {
  local,
  internet
}

enum Price_Changes {
  equal,
  increased,
  decreased
}
enum Grad_Direction {
  up,
  down
}
enum Statuses {
  unknown,
  online,
  offline
}
enum Currency_Type {
  brent,
  eur,
  eurusd,
  usd,
  eth,
  doge
}
enum Theme_Types {
  light,
  dark
}
enum Currency_Pairs {
  btcusd,
  ethusd,
  dogeusd,
  btcrub,
  btceur,
  eurusd,
  eurrub,
  usdrub
}

enum Default_Currency_Pairs {
  btcusd,
  ethusd,
  dogeusd,
  btcrub,
  btceur,
  eurusd,
  eurrub,
  usdrub
}
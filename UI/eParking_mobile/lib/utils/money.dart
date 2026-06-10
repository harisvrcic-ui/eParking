import 'package:decimal/decimal.dart';

Decimal moneyFromJson(dynamic value) {
  if (value == null) return Decimal.zero;
  if (value is Decimal) return value;
  return Decimal.parse(value.toString());
}

Decimal moneyFromText(String text) => Decimal.parse(text.trim());

String formatMoney(Decimal value) => value.toStringAsFixed(2);

String formatMoneyKm(Decimal value) => '${formatMoney(value)} KM';

String formatMoneyFromJson(dynamic value) => formatMoney(moneyFromJson(value));

String formatMoneyKmFromJson(dynamic value) => formatMoneyKm(moneyFromJson(value));

double moneyToApi(Decimal value) => value.toDouble();

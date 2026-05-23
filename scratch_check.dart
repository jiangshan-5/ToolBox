import 'package:csv/csv.dart';
void main() {
  final csv = Csv();
  print(csv.runtimeType);
  // print methods by checking compile-time or testing basic conversion
  final csvString = csv.encode([[1, 2], [3, 4]]);
  print(csvString);
}

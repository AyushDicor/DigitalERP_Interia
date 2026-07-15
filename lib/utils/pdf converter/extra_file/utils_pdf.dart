import 'package:newdigitalerp/utils/indian_number.dart';
import 'package:intl/intl.dart';

class Utils {
  static formatPrice(double price) => ' ${price.toInr()}';
  static formatDate(DateTime date) => DateFormat.yMd().format(date);
}

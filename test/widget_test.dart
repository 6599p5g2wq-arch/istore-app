import 'package:flutter_test/flutter_test.dart';
import 'package:istore/theme.dart';

void main() {
  test('fmtPrice formats thousands', () {
    expect(fmtPrice(12500), '12,500 د.ل');
    expect(fmtPrice(500), '500 د.ل');
  });
}

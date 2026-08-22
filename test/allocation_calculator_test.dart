import 'package:flutter_test/flutter_test.dart';

import 'package:duitku/core/finance/allocation_calculator.dart';

void main() {
  test('50/30/20 split of a round amount sums back exactly', () {
    final split = AllocationCalculator.split(
      5000000,
      needsPercent: 50,
      wantsPercent: 30,
      savingsPercent: 20,
    );
    expect(split.needs, 2500000);
    expect(split.wants, 1500000);
    expect(split.savings, 1000000);
    expect(split.needs + split.wants + split.savings, 5000000);
  });

  test('an amount that does not divide evenly still sums back exactly', () {
    final split = AllocationCalculator.split(
      1000001,
      needsPercent: 50,
      wantsPercent: 30,
      savingsPercent: 20,
    );
    expect(split.needs + split.wants + split.savings, 1000001);
    // The remainder goes to the largest bucket (needs, 50%).
    expect(split.needs, greaterThanOrEqualTo(500000));
  });

  test('percentages that do not add up to 100 are normalized proportionally',
      () {
    final split = AllocationCalculator.split(
      1000000,
      needsPercent: 40,
      wantsPercent: 40,
      savingsPercent: 40,
    );
    expect(split.needs + split.wants + split.savings, 1000000);
    expect(split.needs, closeTo(333333, 1));
  });

  test('zero amount produces a zero split without dividing by zero', () {
    final split = AllocationCalculator.split(
      0,
      needsPercent: 50,
      wantsPercent: 30,
      savingsPercent: 20,
    );
    expect(split.needs, 0);
    expect(split.wants, 0);
    expect(split.savings, 0);
  });
}

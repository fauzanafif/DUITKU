class AllocationSplit {
  const AllocationSplit({
    required this.needs,
    required this.wants,
    required this.savings,
  });

  final double needs;
  final double wants;
  final double savings;
}

/// Splits an income amount into three buckets by percentage. The rounding
/// remainder is always assigned to the largest bucket so the three parts
/// sum back to exactly the original amount — never a rupiah more or less.
class AllocationCalculator {
  const AllocationCalculator._();

  static AllocationSplit split(
    double amount, {
    required double needsPercent,
    required double wantsPercent,
    required double savingsPercent,
  }) {
    final totalPercent = needsPercent + wantsPercent + savingsPercent;
    if (totalPercent <= 0 || amount <= 0) {
      return const AllocationSplit(needs: 0, wants: 0, savings: 0);
    }

    var needs = (amount * needsPercent / totalPercent).roundToDouble();
    var wants = (amount * wantsPercent / totalPercent).roundToDouble();
    var savings = (amount * savingsPercent / totalPercent).roundToDouble();

    final remainder = amount - (needs + wants + savings);
    if (remainder != 0) {
      if (needsPercent >= wantsPercent && needsPercent >= savingsPercent) {
        needs += remainder;
      } else if (wantsPercent >= savingsPercent) {
        wants += remainder;
      } else {
        savings += remainder;
      }
    }

    return AllocationSplit(needs: needs, wants: wants, savings: savings);
  }
}

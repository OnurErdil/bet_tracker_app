class BetCalculator {
  static double calculateNetProfit({
    required double odd,
    required double stake,
    required String result,
  }) {
    switch (result) {
      case 'kazandi':
        return calculatePayout(odd: odd, stake: stake, result: result) - stake;
      case 'kaybetti':
        return -stake;
      case 'iade':
      case 'beklemede':
      default:
        return 0;
    }
  }

  static double calculatePayout({
    required double odd,
    required double stake,
    required String result,
  }) {
    switch (result) {
      case 'kazandi':
        return odd * stake;
      case 'iade':
        return stake;
      case 'kaybetti':
      case 'beklemede':
      default:
        return 0;
    }
  }
}

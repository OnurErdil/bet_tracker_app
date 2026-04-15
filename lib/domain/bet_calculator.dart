class BetCalculator {
  // Net kâr/zararı hesaplar.
  //
  // Sonuç mantığı:
  // - kazandi   => toplam geri ödeme - stake
  // - kaybetti  => stake kadar zarar
  // - iade      => net etki yok
  // - beklemede => net etki yok
  static double calculateNetProfit({
    required double odd,
    required double stake,
    required String result,
  }) {
    switch (result) {
      case 'kazandi':
        return calculatePayout(
          odd: odd,
          stake: stake,
          result: result,
        ) - stake;
      case 'kaybetti':
        return -stake;
      case 'iade':
      case 'beklemede':
      default:
        return 0;
    }
  }

  // Toplam geri ödemeyi hesaplar.
  //
  // Sonuç mantığı:
  // - kazandi   => oran x stake
  // - iade      => sadece stake geri döner
  // - kaybetti  => geri ödeme yok
  // - beklemede => henüz kesinleşmediği için 0 kabul edilir
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

import '../config/pricing_config.dart';

class OngkirService {
  /// Hitung ongkir berdasarkan jarak tempuh (KM).
  ///
  /// Rumus:
  ///   max(minimum, roundUpToNearest(jarakKm * tarifPerKm, pembulatan))
  double hitungOngkir(double jarakKm) {
    final raw = jarakKm * PricingConfig.ongkirPerKm;
    final rounded = _roundUp(raw, PricingConfig.ongkirRounding);
    return rounded > PricingConfig.ongkirMinimum
        ? rounded
        : PricingConfig.ongkirMinimum;
  }

  /// Hitung biaya layanan berdasarkan ongkir.
  double hitungBiayaLayanan(double ongkir) {
    return PricingConfig.hitungBiayaLayanan(ongkir);
  }

  /// Hitung total dari danaBelanja + ongkir + biayaLayanan.
  double hitungTotal({
    required double danaBelanja,
    required double ongkir,
    required double biayaLayanan,
  }) {
    return danaBelanja + ongkir + biayaLayanan;
  }

  /// Round up ke kelipatan tertentu.
  /// Contoh: 9250 → 9500 (kelipatan 500)
  double _roundUp(double amount, int nearest) {
    final factor = 1.0 / nearest;
    return (amount * factor).ceil() / factor;
  }
}

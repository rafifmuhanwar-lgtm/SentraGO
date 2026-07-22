/// Semua tarif dan aturan pembayaran SentraGO
///
/// Semua nilai bisa diubah tanpa mengubah logika utama.
class PricingConfig {
  // ── Ongkir ──
  static const double ongkirPerKm = 2000;       // Rp 2.000 / KM
  static const double ongkirMinimum = 5000;      // Minimal Rp 5.000
  static const int ongkirRounding = 500;         // Pembulatan ke Rp 500 terdekat ke atas

  // ── Biaya Layanan ──
  static const double biayaLayananFlat = 2000;   // Flat Rp 2.000
  static const double biayaLayananPersen = 0.0;  // 0% (kalau mau persentase, isi misal 0.05)

  // ── Method Helpers ──
  static double hitungBiayaLayanan(double totalOngkir) {
    if (biayaLayananPersen > 0) {
      final persen = totalOngkir * biayaLayananPersen;
      return persen > biayaLayananFlat ? persen : biayaLayananFlat;
    }
    return biayaLayananFlat;
  }
}

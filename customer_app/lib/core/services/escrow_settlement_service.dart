/// Hasil settlement escrow setelah pesanan selesai.
class EscrowSettlementResult {
  final double refundCustomer;       // Dikembalikan ke wallet customer
  final double paymentToKurir;       // Reimbursement + ongkir yang dibayar ke kurir
  final double platformFee;          // Biaya layanan (pendapatan platform)
  final double reimbursementBelanja; // Penggantian uang belanja kurir
  final double ongkirPaid;           // Ongkir yang dibayarkan ke kurir
  final bool isOverBudget;           // Apakah total belanja melebihi dana

  const EscrowSettlementResult({
    required this.refundCustomer,
    required this.paymentToKurir,
    required this.platformFee,
    required this.reimbursementBelanja,
    required this.ongkirPaid,
    required this.isOverBudget,
  });
}

/// Service untuk menghitung pembagian escrow setelah pesanan selesai.
class EscrowSettlementService {
  /// Hitung settlement escrow.
  ///
  /// [danaBelanja] — budget customer untuk belanja
  /// [totalBelanjaStruk] — nominal struk dari kurir
  /// [ongkir] — ongkir yang dihitung
  /// [biayaLayanan] — biaya platform
  /// [kebijakanLebih] — 'jangan_lebih' atau 'boleh_lebih'
  ///
  /// Returns [EscrowSettlementResult] atau null jika invalid (over budget & jangan_lebih).
  EscrowSettlementResult? hitungSettlement({
    required double danaBelanja,
    required double totalBelanjaStruk,
    required double ongkir,
    required double biayaLayanan,
    String kebijakanLebih = 'jangan_lebih',
  }) {
    final selisih = danaBelanja - totalBelanjaStruk;

    // Kalau melebihi dana dan kebijakan jangan lebih → return null (invalid)
    if (selisih < 0 && kebijakanLebih == 'jangan_lebih') {
      return null;
    }

    double refundCustomer;
    double reimbursementBelanja;

    if (selisih >= 0) {
      // Belanja kurang dari atau sama dengan dana
      refundCustomer = selisih;
      reimbursementBelanja = totalBelanjaStruk;
    } else {
      // Belanja melebihi dana (boleh_lebih)
      refundCustomer = 0;
      // Customer bayar reimbursement = danaBelanja (full), sisanya ditagih manual
      reimbursementBelanja = danaBelanja;
    }

    final paymentToKurir = reimbursementBelanja + ongkir;

    return EscrowSettlementResult(
      refundCustomer: refundCustomer,
      paymentToKurir: paymentToKurir,
      platformFee: biayaLayanan,
      reimbursementBelanja: reimbursementBelanja,
      ongkirPaid: ongkir,
      isOverBudget: selisih < 0,
    );
  }
}

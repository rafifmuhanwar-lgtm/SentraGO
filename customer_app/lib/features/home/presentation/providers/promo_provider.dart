import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/models/promo_model.dart';

final promosProvider = FutureProvider<List<PromoModel>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final docs = await db.getPromos();
  if (docs.isEmpty) {
    // Return mock if empty
    return [
      const PromoModel(
        id: 'promo_1',
        title: 'Gratis Ongkir',
        description: 'Hingga 10rb\\nuntuk pengguna baru',
        code: 'TITIPDB',
      ),
    ];
  }
  return docs.map((doc) => PromoModel.fromJson(doc)).toList();
});

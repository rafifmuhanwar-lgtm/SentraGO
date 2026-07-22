import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoPickerTile extends StatelessWidget {
  final String? imageUrl;
  final String hintText;
  final ValueChanged<String?> onImagePicked;

  const PhotoPickerTile({
    super.key,
    this.imageUrl,
    this.hintText = 'Tambah Foto Barang',
    required this.onImagePicked,
  });

  Future<void> _pickImage(BuildContext context) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF7F1D3A)),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF7F1D3A)),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile;

      if (source == 'camera') {
        pickedFile = await picker.pickImage(source: ImageSource.camera);
      } else {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      }

      if (pickedFile != null) {
        onImagePicked(pickedFile.path);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengakses kamera/gallery: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickImage(context),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7F1D3A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imageUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.add_a_photo_outlined, size: 18, color: Color(0xFF7F1D3A)),
            ),
            const SizedBox(width: 12),
            Text(
              imageUrl != null ? 'Ganti Foto' : hintText,
              style: const TextStyle(
                color: Color(0xFF7F1D3A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (imageUrl != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => onImagePicked(null),
                child: const Icon(Icons.close, size: 18, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

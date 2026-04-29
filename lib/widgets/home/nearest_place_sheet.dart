import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../sheet_handle.dart';

void showNearestPlaceSheet({
  required BuildContext context,
  required String label,
  required String emoji,
  required VoidCallback onBack,
  required VoidCallback onNavigate,
  Map<String, String>? placeData,
}) {
  final Map<String, String> place = placeData ??
      {
        'name': 'Nearest $label',
        'distance': '—',
        'address': '',
      };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return Container(
        margin: const EdgeInsets.only(top: 24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onBack();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.grey),
                  ),
                  Expanded(
                    child: Text(
                      'Nearest $label',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4E9),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place['name']!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${place['distance']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.greenDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place['address']!,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Text(
                    'Route preview on map',
                    style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onNavigate();
                  },
                  icon: const Icon(Icons.navigation_outlined),
                  label: Text('Navigate to ${place['name']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
import 'package:geo_connect/models/checkin_model.dart';
import 'package:intl/intl.dart';

class CheckInCard extends StatelessWidget {
  final CheckInModel checkIn;
  final VoidCallback? onTap;

  const CheckInCard({
    super.key,
    required this.checkIn,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = checkIn.createdAt != null
        ? DateFormat('MMM d, y • HH:mm').format(checkIn.createdAt!)
        : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardColor.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                      child: Text(
                        (checkIn.user?.name.isNotEmpty ?? false)
                            ? checkIn.user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            checkIn.user?.name ?? 'Anonymous',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.secondaryColor,
                      size: 20,
                    ),
                  ],
                ),
                if (checkIn.description != null && checkIn.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    checkIn.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textColor,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 14,
                        color: AppTheme.subtextColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Lat: ${checkIn.lat.toStringAsFixed(4)}, Lng: ${checkIn.lng.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.subtextColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

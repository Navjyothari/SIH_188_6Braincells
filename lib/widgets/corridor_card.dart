import 'package:flutter/material.dart';
import '../models.dart';

class CorridorCard extends StatelessWidget {
  final CorridorRiskProfile profile;
  final VoidCallback onTap;

  const CorridorCard({
    Key? key,
    required this.profile,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final danger = profile.dangerRating;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: const Color(0xFF162032),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: danger == DangerRating.critical || danger == DangerRating.high
              ? danger.color.withOpacity(0.5)
              : const Color(0xFF334155),
          width: danger == DangerRating.critical ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Route + Danger Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flight_takeoff, size: 16, color: Color(0xFF38BDF8)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                profile.sourcePort,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.flight_land, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                profile.destinationPort,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: danger.bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: danger.color, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          danger == DangerRating.critical
                              ? Icons.warning_rounded
                              : danger == DangerRating.high
                                  ? Icons.report_problem_rounded
                                  : Icons.shield_outlined,
                          size: 14,
                          color: danger.color,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          danger.label,
                          style: TextStyle(
                            color: danger.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tamper Stats Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: profile.totalScreened > 0 ? profile.tamperRate : 0.0,
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: AlwaysStoppedAnimation<Color>(danger.color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),

              // Metrics Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Screened: ${profile.totalScreened} travelers",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                  Text(
                    "Tampered: ${profile.tamperedCount} (${(profile.tamperRate * 100).toStringAsFixed(1)}%)",
                    style: TextStyle(
                      color: danger.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Officer Advisory Notice
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      danger == DangerRating.critical || danger == DangerRating.high
                          ? Icons.priority_high
                          : Icons.info_outline,
                      size: 16,
                      color: danger.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        profile.officerAdvisory,
                        style: TextStyle(
                          color: danger == DangerRating.critical
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFCBD5E1),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (profile.activeSyndicates.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "Active Forgery Rings: ",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Wrap(
                      spacing: 4,
                      children: profile.activeSyndicates.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF475569)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

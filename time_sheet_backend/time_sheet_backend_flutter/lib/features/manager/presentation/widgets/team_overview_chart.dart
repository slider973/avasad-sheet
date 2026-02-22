import 'package:flutter/material.dart';

class TeamOverviewChart extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int totalCount;

  const TeamOverviewChart({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final notPointedCount = totalCount - presentCount - absentCount;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vue d'ensemble",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (totalCount == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aucun employé dans votre équipe',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      if (presentCount > 0)
                        Expanded(
                          flex: presentCount,
                          child: Container(
                            color: Colors.green.shade400,
                            alignment: Alignment.center,
                            child: presentCount > 1
                                ? Text(
                                    '$presentCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      if (absentCount > 0)
                        Expanded(
                          flex: absentCount,
                          child: Container(
                            color: Colors.orange.shade400,
                            alignment: Alignment.center,
                            child: absentCount > 1
                                ? Text(
                                    '$absentCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      if (notPointedCount > 0)
                        Expanded(
                          flex: notPointedCount,
                          child: Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: notPointedCount > 1
                                ? Text(
                                    '$notPointedCount',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LegendItem(
                    color: Colors.green.shade400,
                    label: 'Présents',
                    count: presentCount,
                  ),
                  _LegendItem(
                    color: Colors.orange.shade400,
                    label: 'Absents',
                    count: absentCount,
                  ),
                  _LegendItem(
                    color: Colors.grey.shade300,
                    label: 'Non pointé',
                    count: notPointedCount,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/presentation/widgets/home_ui_extensions.dart';
import 'package:nagah/features/home/presentation/widgets/section_card.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({
    super.key,
    required this.reports,
    required this.roads,
  });

  final List<RoadIssueReport> reports;
  final List<RoadSegment> roads;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text('My reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatCard(
                title: 'Pending',
                value:
                    '${reports.where((r) => r.status == ReportStatus.pending).length}',
                color: ReportStatus.pending.color,
              ),
              StatCard(
                title: 'Approved',
                value:
                    '${reports.where((r) => r.status == ReportStatus.approved).length}',
                color: ReportStatus.approved.color,
              ),
              StatCard(
                title: 'Rejected',
                value:
                    '${reports.where((r) => r.status == ReportStatus.rejected).length}',
                color: ReportStatus.rejected.color,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...reports.map((report) {
            final roadName = _resolveRoadName(report.roadId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ReportCard(report: report, roadName: roadName),
            );
          }),
        ],
      ),
    );
  }

  String _resolveRoadName(String roadId) {
    for (final road in roads) {
      if (road.id == roadId) {
        return road.name;
      }
    }

    return 'Unknown road';
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.roadName});

  final RoadIssueReport report;
  final String roadName;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: report.issueType.color.withValues(alpha: 0.12),
                child: Icon(
                  report.issueType.icon,
                  color: report.issueType.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.issueType.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      roadName,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: report.status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.status.label,
                  style: TextStyle(
                    color: report.status.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(report.description),
          const SizedBox(height: 10),
          Text(
            DateFormat('MMM d, h:mm a').format(report.createdAt),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (report.adminNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(report.adminNote!),
            ),
          ],
        ],
      ),
    );
  }
}

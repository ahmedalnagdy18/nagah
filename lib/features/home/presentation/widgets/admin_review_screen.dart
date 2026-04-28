import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/presentation/widgets/home_ui_extensions.dart';
import 'package:nagah/features/home/presentation/widgets/section_card.dart';

class AdminReviewScreen extends StatelessWidget {
  const AdminReviewScreen({
    super.key,
    required this.reports,
    required this.roads,
    required this.onLogout,
    required this.onExportPdf,
    required this.onDecision,
  });

  final List<RoadIssueReport> reports;
  final List<RoadSegment> roads;
  final VoidCallback onLogout;
  final Future<void> Function() onExportPdf;
  final void Function({
    required String reportId,
    required ReportStatus status,
    String? adminNote,
  })
  onDecision;

  @override
  Widget build(BuildContext context) {
    final pendingReports = reports
        .where((report) => report.status == ReportStatus.pending)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        title: const Text('Admin review'),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                await onExportPdf();
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: MiniMetric(
                    label: 'Pending queue',
                    value: '${pendingReports.length}',
                  ),
                ),
                Expanded(
                  child: MiniMetric(
                    label: 'Approved today',
                    value:
                        '${reports.where((r) => r.status == ReportStatus.approved).length}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (pendingReports.isEmpty)
            const SectionCard(
              child: Text(
                'No pending reports. The admin panel is ready for API data.',
              ),
            )
          else
            ...pendingReports.map((report) {
              final roadName = _resolveRoadName(report.roadId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: report.issueType.color.withValues(
                              alpha: 0.12,
                            ),
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
                                  '$roadName - ${DateFormat('MMM d, h:mm a').format(report.createdAt)}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(report.description),
                      const SizedBox(height: 10),
                      Text(
                        'Location: ${report.location.latitude.toStringAsFixed(5)}, ${report.location.longitude.toStringAsFixed(5)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleReject(context, report.id),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => onDecision(
                                reportId: report.id,
                                status: ReportStatus.approved,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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

  Future<void> _handleReject(BuildContext context, String reportId) async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject report'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write the admin note for the rejection',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(note);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (note == null || note.trim().isEmpty) {
      return;
    }

    onDecision(
      reportId: reportId,
      status: ReportStatus.rejected,
      adminNote: note,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:nagah/features/home/domain/model/home_models.dart';
import 'package:nagah/features/home/presentation/widgets/home_ui_extensions.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.roads,
    required this.approvedReports,
    required this.currentLocation,
    required this.selectedLocation,
    required this.onLocationSelected,
    required this.onCreateReportTap,
    required this.onRecenterTap,
    required this.onLogoutTap,
  });

  final List<RoadSegment> roads;
  final List<RoadIssueReport> approvedReports;
  final LocationPoint currentLocation;
  final LocationPoint? selectedLocation;
  final ValueChanged<LocationPoint> onLocationSelected;
  final VoidCallback onCreateReportTap;
  final VoidCallback onRecenterTap;
  final VoidCallback onLogoutTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  _ReportTimeFilter _timeFilter = _ReportTimeFilter.all;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentChanged =
        oldWidget.currentLocation.latitude != widget.currentLocation.latitude ||
        oldWidget.currentLocation.longitude != widget.currentLocation.longitude;

    if (currentChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _mapController.move(widget.currentLocation.toLatLng(), 14);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _filterReportsByTime(
      widget.approvedReports,
      _timeFilter,
    );
    final accidentZones = _buildAccidentZones(filteredReports);
    final clusteredAccidentIds = accidentZones
        .expand((zone) => zone.reports.map((report) => report.id))
        .toSet();
    final visibleReports = filteredReports
        .where((report) => !clusteredAccidentIds.contains(report.id))
        .toList();
    final incidentSummaries = _buildIncidentSummaries(visibleReports);

    final accidentZoneMarkers = accidentZones
        .map(
          (zone) => Marker(
            point: zone.location.toLatLng(),
            width: zone.markerSize,
            height: zone.markerSize,
            child: GestureDetector(
              onTap: () {
                widget.onLocationSelected(zone.location);
                _showAccidentZoneDetails(zone);
              },
              child: _AccidentZoneMarker(zone: zone),
            ),
          ),
        )
        .toList();

    final reportMarkers = incidentSummaries
        .map(
          (summary) => Marker(
            point: summary.location.toLatLng(),
            width: 86,
            height: 96,
            child: GestureDetector(
              onTap: () => _showIncidentDetails(summary),
              child: _IncidentMarker(summary: summary),
            ),
          ),
        )
        .toList();

    final roadPolylines = widget.roads
        .map(
          (road) => Polyline(
            points: road.points.map((point) => point.toLatLng()).toList(),
            strokeWidth: 8,
            color: road.riskLevel.color,
          ),
        )
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.currentLocation.toLatLng(),
              initialZoom: 14,
              onTap: (_, point) => widget.onLocationSelected(
                LocationPoint(
                  latitude: point.latitude,
                  longitude: point.longitude,
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nagah',
              ),
              PolylineLayer(polylines: roadPolylines),
              MarkerLayer(
                markers: [
                  ...accidentZoneMarkers,
                  ...reportMarkers,
                  Marker(
                    point: widget.currentLocation.toLatLng(),
                    width: 70,
                    height: 78,
                    child: const _SimpleMarker(
                      icon: Icons.my_location_rounded,
                      color: Color(0xFF2563EB),
                      label: 'You',
                    ),
                  ),
                  if (widget.selectedLocation != null)
                    Marker(
                      point: widget.selectedLocation!.toLatLng(),
                      width: 78,
                      height: 84,
                      child: const _SimpleMarker(
                        icon: Icons.place_rounded,
                        color: Color(0xFF111827),
                        label: 'Pick',
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 248),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Road risk map',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onLogoutTap,
                              icon: const Icon(Icons.logout_rounded),
                              tooltip: 'Logout',
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _ReportTimeFilter.values
                              .map(
                                (filter) => _TimeFilterChip(
                                  label: filter.label,
                                  selected: _timeFilter == filter,
                                  onTap: () {
                                    setState(() {
                                      _timeFilter = filter;
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: RoadRiskLevel.values
                                .map(
                                  (level) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _LegendChip(
                                      label: level.label,
                                      color: level.color,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        if (accidentZones.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: const [
                                _LegendChip(
                                  label: '3+ accidents',
                                  color: Color(0xFFEAB308),
                                ),
                                SizedBox(width: 8),
                                _LegendChip(
                                  label: '6+ accidents',
                                  color: Color(0xFFF97316),
                                ),
                                SizedBox(width: 8),
                                _LegendChip(
                                  label: '8+ accidents',
                                  color: Color(0xFFDC2626),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.selectedLocation == null
                              ? 'Tap any road to pick a report location.'
                              : 'Selected point: ${widget.selectedLocation!.latitude.toStringAsFixed(5)}, ${widget.selectedLocation!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onRecenterTap,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.my_location_rounded),
                                label: const Text('My point'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: widget.onCreateReportTap,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.add_road_rounded),
                                label: const Text('Create report'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIncidentDetails(_IncidentSummary summary) {
    final stats = _buildDayNightStats(summary.reports);
    final total = summary.reports.length;

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF16161A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: summary.color.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: summary.color.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: summary.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(summary.icon, color: summary.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${summary.label} zone',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$total approved reports in this area',
                            style: const TextStyle(
                              color: Color(0xFFA1A1AA),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        summary.color.withValues(alpha: 0.18),
                        const Color(0xFF232329),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Day vs night distribution',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TimeRatioBar(
                        label: 'Day',
                        count: stats.dayCount,
                        total: total,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 14),
                      _TimeRatioBar(
                        label: 'Night',
                        count: stats.nightCount,
                        total: total,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Day share',
                        value: '${stats.dayPercent}%',
                        accent: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Night share',
                        value: '${stats.nightPercent}%',
                        accent: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Based on report submission time in this selected area.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccidentZoneDetails(_AccidentZoneSummary zone) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF16161A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: zone.color.withValues(alpha: 0.45)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: zone.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Accident cluster',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${zone.count} accidents were reported in this nearby area.',
                  style: const TextStyle(
                    color: Color(0xFFD4D4D8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: zone.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Severity level: ${zone.severityLabel}',
                    style: TextStyle(
                      color: zone.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onLocationSelected(zone.location);
                      widget.onCreateReportTap();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: zone.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add_road_rounded),
                    label: const Text('Report here'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _ReportTimeFilter { all, day, night }

extension _ReportTimeFilterX on _ReportTimeFilter {
  String get label => switch (this) {
    _ReportTimeFilter.all => 'All',
    _ReportTimeFilter.day => 'Day',
    _ReportTimeFilter.night => 'Night',
  };
}

class _TimeFilterChip extends StatelessWidget {
  const _TimeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF4B5563),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 10,
            width: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentSummary {
  const _IncidentSummary({
    required this.location,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.reports,
  });

  final LocationPoint location;
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final List<RoadIssueReport> reports;
}

class _AccidentZoneSummary {
  const _AccidentZoneSummary({
    required this.location,
    required this.count,
    required this.color,
    required this.markerSize,
    required this.reports,
  });

  final LocationPoint location;
  final int count;
  final Color color;
  final double markerSize;
  final List<RoadIssueReport> reports;

  String get severityLabel => switch (count) {
    >= 8 => 'High',
    >= 6 => 'Medium high',
    _ => 'Warning',
  };
}

class _IncidentMarker extends StatelessWidget {
  const _IncidentMarker({required this.summary});

  final _IncidentSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SimpleMarker(
      icon: summary.icon,
      color: summary.color,
      label: '${summary.label} (${summary.count})',
    );
  }
}

List<_IncidentSummary> _buildIncidentSummaries(List<RoadIssueReport> reports) {
  final grouped = <String, List<RoadIssueReport>>{};

  for (final report in reports) {
    final hasValidLocation =
        report.location.latitude != 0 || report.location.longitude != 0;
    if (!hasValidLocation) {
      continue;
    }

    final key = report.roadId.isEmpty
        ? '${report.location.latitude},${report.location.longitude}'
        : report.roadId;
    grouped.putIfAbsent(key, () => []).add(report);
  }

  return grouped.values.map((items) {
    final first = items.first;
    final accidents = items
        .where((report) => report.issueType == IssueType.accident)
        .length;
    final traffic = items
        .where((report) => report.issueType == IssueType.traffic)
        .length;
    final potholes = items
        .where((report) => report.issueType == IssueType.pothole)
        .length;

    final dominantType = () {
      if (accidents >= traffic && accidents >= potholes) {
        return IssueType.accident;
      }
      if (traffic >= potholes) {
        return IssueType.traffic;
      }
      return IssueType.pothole;
    }();

    return _IncidentSummary(
      location: first.location,
      label: dominantType.label,
      count: items.length,
      color: dominantType.color,
      icon: dominantType.icon,
      reports: items,
    );
  }).toList();
}

List<RoadIssueReport> _filterReportsByTime(
  List<RoadIssueReport> reports,
  _ReportTimeFilter filter,
) {
  if (filter == _ReportTimeFilter.all) {
    return reports;
  }

  return reports.where((report) {
    final hour = report.createdAt.toLocal().hour;
    final isDay = hour >= 6 && hour < 18;

    return switch (filter) {
      _ReportTimeFilter.all => true,
      _ReportTimeFilter.day => isDay,
      _ReportTimeFilter.night => !isDay,
    };
  }).toList();
}

List<_AccidentZoneSummary> _buildAccidentZones(List<RoadIssueReport> reports) {
  const areaThreshold = 0.008;
  final accidentReports = reports.where((report) {
    final hasValidLocation =
        report.location.latitude != 0 || report.location.longitude != 0;
    return hasValidLocation && report.issueType == IssueType.accident;
  }).toList();

  final zones = <List<RoadIssueReport>>[];

  for (final report in accidentReports) {
    List<RoadIssueReport>? targetZone;

    for (final zone in zones) {
      final anchor = zone.first.location;
      final distance =
          (anchor.latitude - report.location.latitude).abs() +
          (anchor.longitude - report.location.longitude).abs();
      if (distance <= areaThreshold) {
        targetZone = zone;
        break;
      }
    }

    if (targetZone == null) {
      zones.add([report]);
    } else {
      targetZone.add(report);
    }
  }

  return zones.where((zone) => zone.length >= 3).map((zone) {
    final latitude =
        zone.map((item) => item.location.latitude).reduce((a, b) => a + b) /
        zone.length;
    final longitude =
        zone.map((item) => item.location.longitude).reduce((a, b) => a + b) /
        zone.length;
    final count = zone.length;

    return _AccidentZoneSummary(
      location: LocationPoint(latitude: latitude, longitude: longitude),
      count: count,
      color: count >= 8
          ? const Color(0xFFDC2626)
          : count >= 6
          ? const Color(0xFFF97316)
          : const Color(0xFFEAB308),
      markerSize: count >= 8
          ? 118
          : count >= 6
          ? 102
          : 88,
      reports: zone,
    );
  }).toList();
}

class _DayNightStats {
  const _DayNightStats({
    required this.dayCount,
    required this.nightCount,
  });

  final int dayCount;
  final int nightCount;

  int get total => dayCount + nightCount;

  int get dayPercent => total == 0 ? 0 : ((dayCount / total) * 100).round();

  int get nightPercent => total == 0 ? 0 : ((nightCount / total) * 100).round();
}

_DayNightStats _buildDayNightStats(List<RoadIssueReport> reports) {
  var dayCount = 0;
  var nightCount = 0;

  for (final report in reports) {
    final hour = report.createdAt.toLocal().hour;
    if (hour >= 6 && hour < 18) {
      dayCount++;
    } else {
      nightCount++;
    }
  }

  return _DayNightStats(dayCount: dayCount, nightCount: nightCount);
}

class _TimeRatioBar extends StatelessWidget {
  const _TimeRatioBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    final percent = (ratio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$count reports',
              style: const TextStyle(
                color: Color(0xFFA1A1AA),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$percent%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 12,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFA1A1AA),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleMarker extends StatelessWidget {
  const _SimpleMarker({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compactCount = RegExp(r'\((\d+)\)').firstMatch(label)?.group(1);
    final shortLabel = label.split('(').first.trim();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        if (compactCount != null)
          Positioned(
            top: -6,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                compactCount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (compactCount == null)
          Positioned(
            top: -24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AccidentZoneMarker extends StatelessWidget {
  const _AccidentZoneMarker({required this.zone});

  final _AccidentZoneSummary zone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: zone.markerSize,
        height: zone.markerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: zone.color.withValues(alpha: 0.18),
          border: Border.all(
            color: zone.color.withValues(alpha: 0.78),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: zone.color.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      ),
    );
  }
}

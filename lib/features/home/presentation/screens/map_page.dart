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
        oldWidget.currentLocation.longitude !=
            widget.currentLocation.longitude;

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
    final incidentSummaries = _buildIncidentSummaries(widget.approvedReports);

    final reportCircles = incidentSummaries
        .map(
          (summary) => CircleMarker(
            point: summary.location.toLatLng(),
            radius: 40 + (summary.count * 8),
            useRadiusInMeter: true,
            color: summary.color.withValues(alpha: 0.18),
            borderColor: summary.color,
            borderStrokeWidth: 2,
          ),
        )
        .toList();

    final reportMarkers = incidentSummaries
        .map(
          (summary) => Marker(
            point: summary.location.toLatLng(),
            width: 86,
            height: 96,
            child: _IncidentMarker(summary: summary),
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
              CircleLayer(circles: reportCircles),
              MarkerLayer(
                markers: [
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
                        const SizedBox(height: 8),
                        const Text(
                          'Approved reports are grouped into road incidents on the map. More approved reports make the hotspot stronger.',
                          style: TextStyle(
                            height: 1.4,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: RoadRiskLevel.values
                              .map(
                                (level) => _LegendChip(
                                  label: level.label,
                                  color: level.color,
                                ),
                              )
                              .toList(),
                        ),
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
                        SizedBox(
                          height: 72,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.roads.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final road = widget.roads[index];
                              return Container(
                                width: 170,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: road.riskLevel.color.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      road.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${road.riskLevel.label} risk',
                                      style: TextStyle(
                                        color: road.riskLevel.color,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
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
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
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
          Text(label),
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
  });

  final LocationPoint location;
  final String label;
  final int count;
  final Color color;
  final IconData icon;
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
    );
  }).toList();
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

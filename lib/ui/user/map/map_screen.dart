import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/status_helper.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../report_detail/report_detail_screen.dart';
import 'map_viewmodel.dart';

/// Tab Peta — Google Maps dengan marker semua laporan.
///
/// Tap marker → preview card di bawah layar.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapViewModel _vm;
  GoogleMapController? _mapController;
  Report? _selectedReport;

  @override
  void initState() {
    super.initState();
    _vm = MapViewModel(context.read<ReportRepository>());
    _vm.loadReports();
  }

  @override
  void dispose() {
    _vm.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(List<Report> reports) {
    return reports.map((report) {
      final color = StatusHelper.colorOf(report.status);
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.latitude, report.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _hueFromColor(color),
        ),
        onTap: () => setState(() => _selectedReport = report),
      );
    }).toSet();
  }

  /// Map warna status ke hue marker Google Maps.
  double _hueFromColor(Color color) {
    if (color == AppColors.statusCompleted) return BitmapDescriptor.hueGreen;
    if (color == AppColors.statusVerified) return BitmapDescriptor.hueAzure;
    if (color == AppColors.statusInProgress) return BitmapDescriptor.hueOrange;
    if (color == AppColors.statusRejected) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueYellow; // pending
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        appBar: AppBar(title: const Text('Peta Laporan')),
        body: Consumer<MapViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingIndicator(message: 'Memuat peta...');
            }
            if (vm.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.error!, style: AppTextStyles.body),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => vm.loadReports(),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              );
            }

            // Default center: Jakarta.
            final initialLat = vm.currentLat ?? -6.2088;
            final initialLng = vm.currentLng ?? 106.8456;

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(initialLat, initialLng),
                    zoom: 12,
                  ),
                  markers: _buildMarkers(vm.reports),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  onTap: (_) => setState(() => _selectedReport = null),
                ),
                // ── Preview Card ──
                if (_selectedReport != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: _MapPreviewCard(
                      report: _selectedReport!,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(
                              reportId: _selectedReport!.id,
                            ),
                          ),
                        );
                        _vm.loadReports();
                        setState(() => _selectedReport = null);
                      },
                      onClose: () =>
                          setState(() => _selectedReport = null),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Kartu preview saat marker di-tap.
class _MapPreviewCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _MapPreviewCard({
    required this.report,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: AppTextStyles.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusPill(status: report.status),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(Icons.close, size: 18,
                        color: AppColors.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(report.category.label, style: AppTextStyles.caption),
              if (report.address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        report.address,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Ketuk untuk melihat detail →',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

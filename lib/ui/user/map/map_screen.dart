import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/category_helper.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../domain/model/enums.dart';
import '../../../domain/model/report.dart';
import '../../../domain/repository/report_repository.dart';
import '../report_detail/report_detail_screen.dart';
import 'map_viewmodel.dart';

/// Tab Peta — Google Maps dengan marker semua laporan, filter, dan carousel.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapViewModel _vm;
  GoogleMapController? _mapController;
  String _query = '';

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

  double _hueFromStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.completed:
        return BitmapDescriptor.hueGreen;
      case ReportStatus.verified:
        return BitmapDescriptor.hueAzure;
      case ReportStatus.inProgress:
        return BitmapDescriptor.hueOrange;
      case ReportStatus.rejected:
        return BitmapDescriptor.hueRed;
      case ReportStatus.pending:
        return BitmapDescriptor.hueYellow;
    }
  }

  Set<Marker> _buildMarkers(List<Report> reports) {
    return reports.map((report) {
      return Marker(
        markerId: MarkerId(report.id),
        position: LatLng(report.latitude, report.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(_hueFromStatus(report.status)),
        onTap: () => _focusReport(report),
      );
    }).toSet();
  }

  void _focusReport(Report report) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(report.latitude, report.longitude),
        16,
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final lat = _vm.currentLat;
    final lng = _vm.currentLng;
    if (lat != null && lng != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
      );
    }
  }

  /// Daftar laporan tampil: filter kategori + query + urut terdekat.
  List<Report> _visible(MapViewModel vm) {
    var list = vm.filteredReports;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.address.toLowerCase().contains(q))
          .toList();
    }
    final lat = vm.currentLat, lng = vm.currentLng;
    if (lat != null && lng != null) {
      list = [...list]..sort((a, b) => _distanceMeters(lat, lng, a.latitude, a.longitude)
          .compareTo(_distanceMeters(lat, lng, b.latitude, b.longitude)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        body: Consumer<MapViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const LoadingIndicator(message: 'Memuat peta...');
            }
            if (vm.error != null) {
              return ErrorState(message: vm.error!, onRetry: vm.loadReports);
            }

            final initialLat = vm.currentLat ?? -6.2088;
            final initialLng = vm.currentLng ?? 106.8456;
            final visible = _visible(vm);

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(initialLat, initialLng),
                    zoom: 12,
                  ),
                  markers: _buildMarkers(visible),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  padding: const EdgeInsets.only(top: 132, bottom: 150),
                  onMapCreated: (controller) => _mapController = controller,
                ),

                // ── Search + filter chips (atas) ──
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        _MapSearchField(
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: 10),
                        _MapFilterChips(
                          selected: vm.categoryFilter,
                          onSelected: vm.setCategoryFilter,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tombol bulat refresh + my location ──
                Positioned(
                  right: 16,
                  bottom: visible.isEmpty ? 32 : 168,
                  child: Column(
                    children: [
                      _RoundButton(
                        icon: Icons.refresh,
                        onTap: vm.loadReports,
                      ),
                      const SizedBox(height: 12),
                      _RoundButton(
                        icon: Icons.my_location,
                        filled: true,
                        onTap: _goToMyLocation,
                      ),
                    ],
                  ),
                ),

                // ── Carousel preview di bawah ──
                if (visible.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        height: 132,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final report = visible[index];
                            final distance = (vm.currentLat != null &&
                                    vm.currentLng != null)
                                ? _distanceMeters(vm.currentLat!,
                                    vm.currentLng!, report.latitude, report.longitude)
                                : null;
                            return _MapPreviewCard(
                              report: report,
                              distanceMeters: distance,
                              onPeek: () => _focusReport(report),
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReportDetailScreen(
                                      reportId: report.id,
                                    ),
                                  ),
                                );
                                _vm.loadReports();
                              },
                            );
                          },
                        ),
                      ),
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

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180.0;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

class _MapSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _MapSearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      shadowColor: Colors.black26,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Cari laporan...',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _MapFilterChips extends StatelessWidget {
  final ReportCategory? selected;
  final ValueChanged<ReportCategory?> onSelected;

  const _MapFilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'Terdekat',
            icon: Icons.near_me,
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          ...ReportCategory.values.map(
            (c) => _FilterChip(
              label: c.label,
              icon: CategoryHelper.iconOf(c),
              active: selected == c,
              onTap: () => onSelected(c),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        elevation: 1.5,
        borderRadius: BorderRadius.circular(20),
        shadowColor: Colors.black12,
        color: active ? AppColors.primary : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: active ? AppColors.onPrimary : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        active ? AppColors.onPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      shape: const CircleBorder(),
      color: filled ? AppColors.primary : AppColors.surface,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: filled ? AppColors.onPrimary : AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Kartu preview di carousel bawah peta.
class _MapPreviewCard extends StatelessWidget {
  final Report report;
  final double? distanceMeters;
  final VoidCallback onTap;
  final VoidCallback onPeek;

  const _MapPreviewCard({
    required this.report,
    required this.distanceMeters,
    required this.onTap,
    required this.onPeek,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.78;

    return SizedBox(
      width: width,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black26,
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: (v) {
            if (v) onPeek();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: report.imageUrls.isNotEmpty
                        ? Image.network(
                            report.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _MiniPlaceholder(),
                          )
                        : const _MiniPlaceholder(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: AppTextStyles.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (distanceMeters != null) ...[
                            const Icon(Icons.near_me,
                                size: 13, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(
                              _formatDistance(distanceMeters!),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              DateFormatter.relative(report.createdAt),
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      StatusPill(status: report.status),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlaceholder extends StatelessWidget {
  const _MiniPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryTint,
      child: const Icon(Icons.photo_outlined, color: AppColors.textHint),
    );
  }
}

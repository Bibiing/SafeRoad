import 'package:saferoad/core/theme/app_colors_extension.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

/// Tab Peta 遯ｶ繝ｻOpenStreetMap dengan marker semua laporan, filter, dan carousel.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapViewModel _vm;
  final MapController _mapController = MapController();
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
    _mapController.dispose();
    super.dispose();
  }

  Color _colorFromStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.completed:
        return Colors.green;
      case ReportStatus.verified:
        return Colors.lightBlue;
      case ReportStatus.inProgress:
        return Colors.orange;
      case ReportStatus.rejected:
        return Colors.red;
      case ReportStatus.pending:
        return Colors.amber.shade700;
    }
  }

  List<Marker> _buildMarkers(List<Report> reports) {
    return reports.map((report) {
      return Marker(
        point: LatLng(report.latitude, report.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _focusReport(report),
          child: Icon(
            Icons.location_pin,
            color: _colorFromStatus(report.status),
            size: 36,
          ),
        ),
      );
    }).toList();
  }

  void _focusReport(Report report) {
    _mapController.move(LatLng(report.latitude, report.longitude), 16);
  }

  void _goToMyLocation() {
    final lat = _vm.currentLat;
    final lng = _vm.currentLng;
    if (lat != null && lng != null) {
      _mapController.move(LatLng(lat, lng), 15);
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
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(initialLat, initialLng),
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.saferoad',
                    ),
                    MarkerLayer(markers: _buildMarkers(visible)),
                    if (vm.currentLat != null && vm.currentLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(vm.currentLat!, vm.currentLng!),
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SimpleAttributionWidget(
                      source: Text('・ゑｽｩ OpenStreetMap contributors'),
                    ),
                  ],
                ),

                // 隨渉隨渉 Search + filter chips (atas) 隨渉隨渉
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

                // 隨渉隨渉 Tombol bulat refresh + my location 隨渉隨渉
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

                // 隨渉隨渉 Carousel preview di bawah 隨渉隨渉
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
          fillColor: context.appColors.surface,
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
        color: active ? AppColors.primary : context.appColors.surface,
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
                  color: active ? AppColors.onPrimary : context.appColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color:
                        active ? AppColors.onPrimary : context.appColors.textSecondary,
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
      color: filled ? AppColors.primary : context.appColors.surface,
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
        color: context.appColors.surface,
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
                                  .copyWith(color: context.appColors.textHint),
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
                Icon(Icons.chevron_right, color: context.appColors.textHint),
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
      color: context.appColors.primaryTint,
      child: Icon(Icons.photo_outlined, color: context.appColors.textHint),
    );
  }
}

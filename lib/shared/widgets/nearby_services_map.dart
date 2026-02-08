import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/services_provider.dart';

class NearbyServicesMap extends ConsumerStatefulWidget {
  final double? userLat;
  final double? userLng;

  const NearbyServicesMap({
    super.key,
    this.userLat,
    this.userLng,
  });

  @override
  ConsumerState<NearbyServicesMap> createState() => _NearbyServicesMapState();
}

class _NearbyServicesMapState extends ConsumerState<NearbyServicesMap> {
  final MapController _mapController = MapController();
  ContractorService? _selectedService;
  bool _isExpanded = false;

  // Default to Kuala Lumpur if no location provided
  LatLng get _center => LatLng(
    widget.userLat ?? 3.1390,
    widget.userLng ?? 101.6869,
  );

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(
      nearbyServicesProvider((widget.userLat ?? 3.1390, widget.userLng ?? 101.6869)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Services Near You',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                icon: Icon(
                  _isExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                  size: 20,
                ),
                label: Text(_isExpanded ? 'Collapse' : 'Expand'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Map container
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _isExpanded ? 400 : 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13,
                    onTap: (_, __) => setState(() => _selectedService = null),
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.servisku.user',
                    ),

                    // User location marker
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          width: 50,
                          height: 50,
                          child: _buildUserMarker(),
                        ),
                      ],
                    ),

                    // Service markers
                    servicesAsync.when(
                      data: (services) => MarkerLayer(
                        markers: services.map((service) => Marker(
                          point: LatLng(
                            service.contractorLat ?? _center.latitude + (services.indexOf(service) * 0.005),
                            service.contractorLng ?? _center.longitude + (services.indexOf(service) * 0.003),
                          ),
                          width: 50,
                          height: 50,
                          child: _buildServiceMarker(service),
                        )).toList(),
                      ),
                      loading: () => const MarkerLayer(markers: []),
                      error: (_, __) => const MarkerLayer(markers: []),
                    ),
                  ],
                ),

                // Service count badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: servicesAsync.when(
                      data: (services) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${services.length} nearby',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => Text(
                        'Error',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),

                // Recenter button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      _mapController.move(_center, 13);
                    },
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),

                // Selected service card
                if (_selectedService != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 60,
                    child: _buildSelectedServiceCard(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildServiceMarker(ContractorService service) {
    final isSelected = _selectedService?.id == service.id;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedService = service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppTheme.primaryColor : Colors.black).withOpacity(0.2),
              blurRadius: isSelected ? 12 : 6,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            _getCategoryIcon(service.categorySlug),
            color: isSelected ? Colors.white : AppTheme.primaryColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServiceCard() {
    final service = _selectedService!;
    
    return GestureDetector(
      onTap: () => context.push('/service/${service.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(service.categorySlug),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        (service.avgRating ?? 0).toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RM ${service.basePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? slug) {
    switch (slug) {
      case 'home':
        return Icons.home_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'personal-care':
        return Icons.spa_rounded;
      case 'events':
        return Icons.celebration_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'tech':
        return Icons.computer_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'learning':
        return Icons.school_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}

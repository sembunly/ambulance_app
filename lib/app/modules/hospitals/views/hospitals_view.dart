import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/hospitals_controller.dart';
import '../../../theme/app_theme.dart';
import '../widgets/hospital_card.dart';

class HospitalsView extends StatefulWidget {
  const HospitalsView({super.key, this.controller});

  final HospitalsController? controller;

  @override
  State<HospitalsView> createState() => _HospitalsViewState();
}

class _HospitalsViewState extends State<HospitalsView> {
  late final HospitalsController _controller;
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? Get.find<HospitalsController>();
    _searchController = TextEditingController(
      text: _controller.searchText.value,
    );
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 320) {
      _controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('nearbyHospitalsScreen'),
      backgroundColor: context.appColors.background,
      appBar: AppBar(title: const Text('Nearby Hospitals')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Obx(() => _buildBody(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final status = _controller.status.value;
    return RefreshIndicator(
      onRefresh: _controller.refreshHospitals,
      child: CustomScrollView(
        key: const Key('nearbyHospitalsScrollView'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _searchHeader(context, status)),
          ..._contentSlivers(context, status),
        ],
      ),
    );
  }

  Widget _searchHeader(BuildContext context, NearbyHospitalsStatus status) {
    final count = _controller.hospitals.length;
    final total = _controller.total.value;
    final showCount = status == NearbyHospitalsStatus.success;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('hospitalSearchField'),
            controller: _searchController,
            onChanged: _controller.updateSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search hospitals',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.searchText.value.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        _controller.updateSearch('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          if (showCount) ...[
            const SizedBox(height: 12),
            Text(
              total > count
                  ? 'Showing $count of $total hospitals, nearest first'
                  : '$count hospital${count == 1 ? '' : 's'} near you, nearest first',
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _contentSlivers(
    BuildContext context,
    NearbyHospitalsStatus status,
  ) {
    switch (status) {
      case NearbyHospitalsStatus.initial:
      case NearbyHospitalsStatus.locating:
        return <Widget>[
          _loadingSliver(
            context,
            message: 'Finding your current location…',
            icon: Icons.my_location_rounded,
          ),
        ];
      case NearbyHospitalsStatus.loading:
        return <Widget>[
          _loadingSliver(
            context,
            message: 'Loading nearby hospitals…',
            icon: Icons.local_hospital_outlined,
          ),
        ];
      case NearbyHospitalsStatus.success:
        return <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            sliver: SliverList.separated(
              itemCount: _controller.hospitals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final hospital = _controller.hospitals[index];
                return HospitalCard(
                  hospital: hospital,
                  onCall: () =>
                      _performAction(() => _controller.callHospital(hospital)),
                  onOpenMaps: () => _performAction(
                    () => _controller.openGoogleMaps(hospital),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _paginationFooter(context)),
        ];
      case NearbyHospitalsStatus.empty:
        return <Widget>[
          _stateSliver(
            context,
            icon: Icons.local_hospital_outlined,
            title: _controller.searchText.value.isEmpty
                ? 'No hospitals found'
                : 'No matching hospitals',
            message: _controller.searchText.value.isEmpty
                ? 'There are no active hospitals available right now.'
                : 'Try a different hospital name or clear your search.',
            actionLabel: _controller.searchText.value.isEmpty
                ? 'Refresh'
                : 'Clear Search',
            onAction: _controller.searchText.value.isEmpty
                ? _controller.refreshHospitals
                : () {
                    _searchController.clear();
                    _controller.updateSearch('');
                  },
          ),
        ];
      case NearbyHospitalsStatus.gpsDisabled:
        return <Widget>[
          _stateSliver(
            context,
            icon: Icons.location_off_outlined,
            title: 'Location Services are off',
            message:
                _controller.errorMessage.value ??
                'Turn on GPS to sort hospitals by distance.',
            actionLabel: 'Enable Location',
            onAction: _controller.handleLocationAction,
          ),
        ];
      case NearbyHospitalsStatus.permissionDenied:
        return <Widget>[
          _stateSliver(
            context,
            icon: Icons.location_disabled_outlined,
            title: 'Location permission denied',
            message:
                _controller.errorMessage.value ??
                'Allow location access to find hospitals near you.',
            actionLabel: 'Try Again',
            onAction: _controller.handleLocationAction,
          ),
        ];
      case NearbyHospitalsStatus.permissionDeniedForever:
        return <Widget>[
          _stateSliver(
            context,
            icon: Icons.app_settings_alt_outlined,
            title: 'Location permission blocked',
            message:
                _controller.errorMessage.value ??
                'Allow location access from your device settings.',
            actionLabel: 'Open App Settings',
            onAction: _controller.handleLocationAction,
          ),
        ];
      case NearbyHospitalsStatus.locationError:
        return <Widget>[
          _stateSliver(
            context,
            icon: Icons.wrong_location_outlined,
            title: 'Location unavailable',
            message:
                _controller.errorMessage.value ??
                'Unable to read your current location.',
            actionLabel: 'Try Again',
            onAction: _controller.retry,
          ),
        ];
      case NearbyHospitalsStatus.apiError:
        return <Widget>[
          _stateSliver(
            context,
            icon: Icons.cloud_off_outlined,
            title: 'Unable to load hospitals',
            message:
                _controller.errorMessage.value ??
                'Check your connection and try again.',
            actionLabel: 'Retry',
            onAction: _controller.retry,
          ),
        ];
    }
  }

  Widget _loadingSliver(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: context.appColors.primary,
                      backgroundColor: context.appColors.primarySoft,
                    ),
                  ),
                  Icon(icon, color: context.appColors.primary, size: 27),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stateSliver(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(34, 24, 34, 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: context.appColors.surface2,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: context.appColors.textMuted, size: 36),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paginationFooter(BuildContext context) {
    if (_controller.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(18, 2, 18, 28),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    final error = _controller.paginationError.value;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        child: Column(
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.error),
            ),
            TextButton(
              onPressed: _controller.loadMore,
              child: const Text('Retry loading more'),
            ),
          ],
        ),
      );
    }
    if (!_controller.hasMore.value) return const SliverGapFallback();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: OutlinedButton(
        onPressed: _controller.loadMore,
        child: const Text('Load more hospitals'),
      ),
    );
  }

  Future<void> _performAction(Future<bool> Function() action) async {
    final opened = await action();
    if (!mounted || opened) return;
    final message = _controller.actionError.value;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class SliverGapFallback extends StatelessWidget {
  const SliverGapFallback({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 22);
}

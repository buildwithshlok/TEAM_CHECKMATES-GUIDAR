import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/navigation_controller.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/voice_feedback_widget.dart';
import '../widgets/speech_text_display.dart';
import '../widgets/language_selector_widget.dart';
import '../widgets/enhanced_map_widget.dart';
import '../services/multilingual_service.dart';
import 'saved_places_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showInstructions = true;

  @override
  void initState() {
    super.initState();
    // Hide instructions after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showInstructions = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(MultilingualService.t('app_name')),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            actions: [
              const LanguageSelectorWidget(compact: true),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings if needed
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Enhanced Google Map
              EnhancedMapWidget(
                currentPosition: controller.currentPosition,
                markers: controller.markers,
                polylines: controller.polylines,
                onMapCreated: controller.setMapController,
              ),

              // Status overlays
              SafeArea(
                child: Column(
                  children: [
                    // Connection status
                    const ConnectionStatusWidget(),

                    const Spacer(),

                    // Speech text display
                    const SpeechTextDisplay(),

                    const SizedBox(height: 8),

                    // Voice feedback indicator
                    const VoiceFeedbackWidget(),

                    const SizedBox(height: 8),

                    // Navigation info panel
                    if (controller.isNavigating)
                      _buildNavigationInfoPanel(controller),

                    // Search results panel
                    if (controller.currentState == AppState.browsingResults)
                      _buildSearchResultsPanel(controller),

                    // Saved places browsing panel
                    if (controller.currentState == AppState.browsingSavedPlaces)
                      _buildSavedPlacesBrowsingPanel(controller),

                    // Instructions panel
                    if (_showInstructions &&
                        controller.currentState == AppState.idle)
                      _buildInstructionsPanel(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Loading overlay
              if (controller.currentState == AppState.processing)
                _buildLoadingOverlay(),
            ],
          ),
          floatingActionButton: _buildFloatingButtons(controller),
        );
      },
    );
  }

  Widget _buildNavigationInfoPanel(NavigationController controller) {
    final routeInfo = controller.routeInfo;
    final destination = controller.selectedDestination;

    if (routeInfo == null || destination == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Use the multilingual navigation announcement
        final announcement = MultilingualService.formatNavigationStart(
          destination.mainText,
          routeInfo.distance,
          routeInfo.duration,
        );
        controller.speechService.speak(announcement);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.mainText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (destination.secondaryText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          destination.secondaryText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Save button
                IconButton(
                  icon: Icon(
                    Icons.bookmark_border,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  onPressed: () async {
                    await controller.saveCurrentDestination();
                  },
                  tooltip: MultilingualService.t('save'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: routeInfo.distance,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: routeInfo.duration,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MultilingualService.t(
                        'select_stop_next_status_prev_instruction',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsPanel(NavigationController controller) {
    final results = controller.searchResults;
    final currentIndex = controller.currentResultIndex;

    if (results.isEmpty) return const SizedBox.shrink();

    final current = results[currentIndex];

    return GestureDetector(
      onTap: () async {
        // Use multilingual result announcement
        final announcement = MultilingualService.formatResultAnnouncement(
          currentIndex,
          results.length,
          current.mainText,
          current.secondaryText,
          current.formattedDistance,
        );
        await controller.speechService.speak(announcement);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search,
                    color: Colors.purple.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        MultilingualService.t(
                          'result_count_announcement',
                          args: [
                            (currentIndex + 1).toString(),
                            results.length.toString(),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current.mainText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (current.secondaryText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                current.secondaryText,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
            if (current.formattedDistance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    current.formattedDistance!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    MultilingualService.t('next_prev_browse_select_navigate'),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlacesBrowsingPanel(NavigationController controller) {
    final places = controller.savedPlaces;
    final currentIndex = controller.currentSavedPlaceIndex;

    if (places.isEmpty) return const SizedBox.shrink();

    final current = places[currentIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bookmark,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MultilingualService.t(
                        'saved_place_count_announcement',
                        args: [
                          (currentIndex + 1).toString(),
                          places.length.toString(),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (current.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              current.address,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text(
                  MultilingualService.t('next_prev_browse_select_navigate'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsPanel() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showInstructions = false;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  MultilingualService.t('how_to_use'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _showInstructions = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionRow(
              Icons.touch_app,
              MultilingualService.t('press_select_to_search'),
            ),
            _buildInstructionRow(
              Icons.bookmark,
              MultilingualService.t('press_next_for_saved'),
            ),
            _buildInstructionRow(
              Icons.navigation,
              MultilingualService.t('navigate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                "${MultilingualService.t('processing')}...",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(NavigationController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Saved Places button
        if (controller.savedPlaces.isNotEmpty)
          FloatingActionButton(
            heroTag: 'saved',
            mini: true,
            backgroundColor: Colors.orange.shade700,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EnhancedSavedPlacesScreen(),
                ),
              );
            },
            child: const Icon(Icons.bookmark, color: Colors.white),
          ),
        const SizedBox(height: 8),
        // My location button
        FloatingActionButton(
          heroTag: 'location',
          mini: true,
          backgroundColor: Colors.white,
          onPressed: () {
            if (controller.currentPosition != null) {
              // Announce current location in current language
              final announcement =
                  "${MultilingualService.t('your_current_location')}: "
                  "${controller.currentAddress ?? MultilingualService.t('unknown_location')}";
              controller.speechService.speak(announcement);
            }
          },
          child: const Icon(Icons.my_location, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        // Main action button
        if (controller.currentState == AppState.idle)
          FloatingActionButton.extended(
            heroTag: 'search',
            onPressed: () async {
              await controller.speechService.speak(
                MultilingualService.t('press_button_to_start'),
              );
            },
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.mic),
            label: Text(MultilingualService.t('voice_search')),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../controllers/navigation_controller.dart';
import '../models/saved_place.dart';
import '../services/multilingual_service.dart';

class EnhancedSavedPlacesScreen extends StatefulWidget {
  const EnhancedSavedPlacesScreen({super.key});

  @override
  State<EnhancedSavedPlacesScreen> createState() =>
      _EnhancedSavedPlacesScreenState();
}

class _EnhancedSavedPlacesScreenState extends State<EnhancedSavedPlacesScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _sortBy = 'recent'; // recent, name, distance
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _announcePage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _announcePage() async {
    final controller = Provider.of<NavigationController>(
      context,
      listen: false,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    final count = controller.savedPlaces.length;
    final message = count == 0
        ? MultilingualService.t('no_saved_places')
        : '${MultilingualService.t('saved_places')}. $count ${MultilingualService.t('places')}';

    controller.speechService.speak(message);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        List<SavedPlace> filteredPlaces = _filterAndSortPlaces(
          controller.savedPlaces,
        );

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: _buildAppBar(controller),
          body: Column(
            children: [
              _buildSearchBar(),
              _buildTabBar(),
              _buildSortOptions(),
              Expanded(
                child: filteredPlaces.isEmpty
                    ? _buildEmptyState()
                    : _buildPlacesList(controller, filteredPlaces),
              ),
            ],
          ),
          floatingActionButton: _buildFAB(context, controller),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(NavigationController controller) {
    return AppBar(
      title: Text(
        MultilingualService.t('saved_places'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (controller.savedPlaces.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(),
            tooltip: 'Sort',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'clear_all') {
                _showClearAllDialog(context, controller);
              } else if (value == 'export') {
                _exportPlaces(controller);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text('Export Places'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search saved places...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.blue.shade700,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue.shade700,
        indicatorWeight: 3,
        onTap: (index) {
          setState(() {
            _selectedCategory = ['all', 'home', 'work', 'favorite'][index];
          });
        },
        tabs: [
          Tab(icon: Icon(Icons.grid_view), text: MultilingualService.t('all')),
          Tab(icon: Icon(Icons.home), text: MultilingualService.t('home')),
          Tab(icon: Icon(Icons.work), text: MultilingualService.t('work')),
          Tab(
            icon: Icon(Icons.favorite),
            text: MultilingualService.t('favorite'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(width: 12),
          _buildSortChip('Recent', 'recent'),
          const SizedBox(width: 8),
          _buildSortChip('Name', 'name'),
          const SizedBox(width: 8),
          _buildSortChip('Distance', 'distance'),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  List<SavedPlace> _filterAndSortPlaces(List<SavedPlace> places) {
    // Filter by search
    var filtered = places.where((place) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return place.name.toLowerCase().contains(query) ||
          place.address.toLowerCase().contains(query) ||
          (place.notes?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'distance':
        final controller = Provider.of<NavigationController>(
          context,
          listen: false,
        );
        if (controller.currentPosition != null) {
          for (var place in filtered) {
            place.distance = Geolocator.distanceBetween(
              controller.currentPosition!.latitude,
              controller.currentPosition!.longitude,
              place.latitude,
              place.longitude,
            );
          }
          filtered.sort(
            (a, b) => (a.distance ?? double.infinity).compareTo(
              b.distance ?? double.infinity,
            ),
          );
        }
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  Widget _buildPlacesList(
    NavigationController controller,
    List<SavedPlace> places,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      itemBuilder: (context, index) {
        return _buildEnhancedPlaceCard(controller, places[index], index);
      },
    );
  }

  Widget _buildEnhancedPlaceCard(
    NavigationController controller,
    SavedPlace place,
    int index,
  ) {
    final distance = place.distance != null
        ? MultilingualService.formatDistance(place.distance!)
        : null;

    return GestureDetector(
      onTap: () => _announcePlace(controller, place, index),
      onDoubleTap: () => _navigateToPlace(controller, place),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _getCategoryColor(place.category).withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryIcon(place.category),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  distance,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildQuickActions(controller, place),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  place.address,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (place.notes != null && place.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            place.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCategoryChip(place.category),
                    const Spacer(),
                    Text(
                      _formatDate(place.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String? category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getCategoryIconData(category),
        color: _getCategoryColor(category),
        size: 28,
      ),
    );
  }

  Widget _buildCategoryChip(String? category) {
    final categoryName = MultilingualService.t(category ?? 'other');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCategoryColor(category).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIconData(category),
            size: 14,
            color: _getCategoryColor(category),
          ),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 12,
              color: _getCategoryColor(category),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(NavigationController controller, SavedPlace place) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.navigation, color: Colors.blue.shade700),
          onPressed: () => _navigateToPlace(controller, place),
          tooltip: MultilingualService.t('navigate'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditDialog(context, controller, place);
            } else if (value == 'delete') {
              _showDeleteDialog(context, controller, place);
            } else if (value == 'share') {
              _sharePlace(place);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(MultilingualService.t('edit')),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.bookmark_border,
              size: 64,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No places found'
                : MultilingualService.t('no_saved_places'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Navigate to a place and save it for quick access',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context, NavigationController controller) {
    return FloatingActionButton.extended(
      onPressed: () {
        _showAddPlaceOptions(context, controller);
      },
      backgroundColor: Colors.blue.shade700,
      icon: const Icon(Icons.add_location),
      label: Text(MultilingualService.t('add_place')),
    );
  }

  // Helper methods
  void _announcePlace(
    NavigationController controller,
    SavedPlace place,
    int index,
  ) {
    final distance = place.distance != null
        ? MultilingualService.formatDistance(place.distance!)
        : '';

    String message = '${place.name}';
    if (distance.isNotEmpty) {
      message += ', $distance ${MultilingualService.t("away")}';
    }
    message += '. ${place.address}';
    if (place.notes != null && place.notes!.isNotEmpty) {
      message += '. Note: ${place.notes}';
    }
    message += '. Double tap to navigate';

    controller.speechService.speak(message);
  }

  void _navigateToPlace(
    NavigationController controller,
    SavedPlace place,
  ) async {
    controller.speechService.speak(
      '${MultilingualService.t("starting_navigation")} ${place.name}',
    );

    // Implementation would be in navigation controller
    // controller.navigateToSavedPlace(place);
    Navigator.pop(context);
  }

  // ... Additional helper methods (showEditDialog, sharePlace, etc.)
  // Continue with rest of implementation...

  IconData _getCategoryIconData(String? category) {
    switch (category) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'home':
        return Colors.blue;
      case 'work':
        return Colors.orange;
      case 'favorite':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showSortOptions() {
    // Implementation
  }

  void _showClearAllDialog(
    BuildContext context,
    NavigationController controller,
  ) {
    // Implementation
  }

  void _exportPlaces(NavigationController controller) {
    // Implementation
  }

  void _showEditDialog(
    BuildContext context,
    NavigationController controller,
    SavedPlace place,
  ) {
    // Implementation
  }

  void _showDeleteDialog(
    BuildContext context,
    NavigationController controller,
    SavedPlace place,
  ) {
    // Implementation
  }

  void _sharePlace(SavedPlace place) {
    // Implementation
  }

  void _showAddPlaceOptions(
    BuildContext context,
    NavigationController controller,
  ) {
    // Implementation
  }
}

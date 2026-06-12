import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/navigation_controller.dart';
import '../services/wifi_service.dart';
import '../services/multilingual_service.dart';

class ObstacleDisplayWidget extends StatelessWidget {
  const ObstacleDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        final obstacles = controller.currentObstacles;

        // Only show if there are active obstacles
        if (obstacles.isEmpty || !obstacles.any((o) => o.hasObstacle)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade300, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    MultilingualService.currentLanguage == AppLanguage.hindi
                        ? "बाधा का पता चला"
                        : "Obstacles Detected",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...obstacles
                  .where((o) => o.hasObstacle)
                  .map((obstacle) => _buildObstacleRow(obstacle)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildObstacleRow(ObstacleData obstacle) {
    Color severityColor;
    IconData icon;
    String levelText;

    // Determine color and icon based on severity
    if (obstacle.isCritical) {
      severityColor = Colors.red.shade700;
      icon = Icons.dangerous;
    } else if (obstacle.isHigh) {
      severityColor = Colors.orange.shade700;
      icon = Icons.warning;
    } else {
      severityColor = Colors.yellow.shade800;
      icon = Icons.info;
    }

    // Get level text in current language
    switch (obstacle.sensor) {
      case "HEAD":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "सिर स्तर"
            : "Head Level";
        break;
      case "MID":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "कमर स्तर"
            : "Ground Level";
        break;
      case "GROUND":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "जमीन स्तर"
            : "Ground Level";
        break;
      default:
        levelText = obstacle.sensor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: severityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  levelText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${obstacle.distance} ${MultilingualService.currentLanguage == AppLanguage.hindi ? 'सेंटीमीटर' : 'cm'}",
                  style: TextStyle(
                    fontSize: 13,
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildDistanceIndicator(obstacle.distance),
        ],
      ),
    );
  }

  Widget _buildDistanceIndicator(int distance) {
    int bars;
    Color color;

    if (distance < 30) {
      bars = 3;
      color = Colors.red.shade700;
    } else if (distance < 60) {
      bars = 2;
      color = Colors.orange.shade700;
    } else {
      bars = 1;
      color = Colors.yellow.shade800;
    }

    return Row(
      children: List.generate(
        3,
        (index) => Container(
          width: 8,
          height: 20 - (index * 5.0),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: index < bars ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// Compact version for navigation screen
class CompactObstacleWidget extends StatelessWidget {
  const CompactObstacleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        final obstacles = controller.currentObstacles;

        // Find the most critical obstacle
        ObstacleData? mostCritical;
        for (var obs in obstacles) {
          if (obs.hasObstacle) {
            if (mostCritical == null ||
                _getSeverityLevel(obs.severity) >
                    _getSeverityLevel(mostCritical.severity)) {
              mostCritical = obs;
            }
          }
        }

        if (mostCritical == null) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: () {
            _showObstacleDetails(context, obstacles);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    MultilingualService.currentLanguage == AppLanguage.hindi
                        ? "बाधा: ${mostCritical.distance} सेमी"
                        : "Obstacle: ${mostCritical.distance} cm",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
                Icon(Icons.info_outline, color: Colors.red.shade700, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getSeverityLevel(String severity) {
    switch (severity) {
      case 'critical':
        return 3;
      case 'high':
        return 2;
      case 'medium':
        return 1;
      default:
        return 0;
    }
  }

  void _showObstacleDetails(
    BuildContext context,
    List<ObstacleData> obstacles,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  MultilingualService.currentLanguage == AppLanguage.hindi
                      ? "बाधा विवरण"
                      : "Obstacle Details",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...obstacles
                .where((o) => o.hasObstacle)
                .map((obs) => _buildDetailRow(obs)),
            if (obstacles.where((o) => o.hasObstacle).isEmpty)
              Text(
                MultilingualService.currentLanguage == AppLanguage.hindi
                    ? "कोई बाधा नहीं मिली"
                    : "No obstacles detected",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ObstacleData obstacle) {
    String levelText;
    switch (obstacle.sensor) {
      case "HEAD":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "सिर स्तर"
            : "Head Level";
        break;
      case "MID":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "कमर स्तर"
            : "Ground Level";
        break;
      case "GROUND":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "जमीन स्तर"
            : "Ground Level";
        break;
      default:
        levelText = obstacle.sensor;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                obstacle.severity.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: _getSeverityColor(obstacle.severity),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            "${obstacle.distance} ${MultilingualService.currentLanguage == AppLanguage.hindi ? 'सेमी' : 'cm'}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getSeverityColor(obstacle.severity),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade800;
      default:
        return Colors.grey.shade600;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/navigation_controller.dart';
import '../services/multilingual_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        final isConnected = controller.isWiFiConnected;

        return GestureDetector(
          onTap: () => _announceStatus(controller, isConnected),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.orange,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? Colors.green : Colors.orange)
                      .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isConnected)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Icon(
                      Icons.wifi_off,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  )
                else
                  Icon(Icons.wifi, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isConnected
                          ? MultilingualService.t('wifi_connected')
                          : MultilingualService.t('not_connected'),
                      style: TextStyle(
                        color: isConnected
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (!isConnected)
                      Text(
                        MultilingualService.currentLanguage == AppLanguage.hindi
                            ? 'कनेक्ट करने की कोशिश...'
                            : 'Searching for stick...',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _announceStatus(NavigationController controller, bool isConnected) {
    final message = isConnected
        ? MultilingualService.t('connected')
        : MultilingualService.t('not_connected');
    controller.speechService.speak(message);
  }
}

// Enhanced connection status with more details
class DetailedConnectionStatusWidget extends StatelessWidget {
  const DetailedConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        final isConnected = controller.isWiFiConnected;

        return GestureDetector(
          onTap: () => _showConnectionDetails(context, controller),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        color: isConnected
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? MultilingualService.t('wifi_connected')
                                : MultilingualService.t('not_connected'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isConnected
                                ? 'Smart Blind Stick'
                                : MultilingualService.currentLanguage ==
                                      AppLanguage.hindi
                                ? 'स्टिक की खोज हो रही है'
                                : 'Searching for stick',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                if (isConnected) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.signal_cellular_alt,
                        label: 'Strong',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.battery_full,
                        label: '85%',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showConnectionDetails(
    BuildContext context,
    NavigationController controller,
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
            Text(
              'Connection Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              'Status',
              controller.isWiFiConnected ? 'Connected' : 'Disconnected',
            ),
            _buildDetailRow('Device', 'Smart Blind Stick'),
            _buildDetailRow('Connection', 'WiFi'),
            _buildDetailRow('Signal', 'Strong (-45 dBm)'),
            const SizedBox(height: 24),
            if (!controller.isWiFiConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Trigger reconnection
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reconnect'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

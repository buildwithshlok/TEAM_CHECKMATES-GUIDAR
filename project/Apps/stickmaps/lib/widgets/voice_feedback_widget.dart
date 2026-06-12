import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/navigation_controller.dart';

class VoiceFeedbackWidget extends StatelessWidget {
  const VoiceFeedbackWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        final isSpeaking = controller.speechService.isSpeaking;
        final isListening = controller.speechService.isListening;

        if (!isSpeaking && !isListening) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isListening ? Icons.mic : Icons.volume_up,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                isListening ? 'Listening...' : 'Speaking...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

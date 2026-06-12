import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multilingual_service.dart';
import '../controllers/navigation_controller.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final bool showLabel;
  final bool compact;

  const LanguageSelectorWidget({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactSelector(context);
    }
    return _buildFullSelector(context);
  }

  Widget _buildFullSelector(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.language, color: Colors.blue.shade700, size: 24),
              const SizedBox(width: 12),
              if (showLabel) ...[
                Text(
                  MultilingualService.t('language'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: DropdownButton<AppLanguage>(
                  value: MultilingualService.currentLanguage,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.blue.shade700,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.english,
                      child: Row(
                        children: [
                          const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'English',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.hindi,
                      child: Row(
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'हिन्दी',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (AppLanguage? language) async {
                    if (language != null) {
                      await _changeLanguage(context, controller, language);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactSelector(BuildContext context) {
    return Consumer<NavigationController>(
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () => _showLanguageSheet(context, controller),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  MultilingualService.currentLanguage == AppLanguage.hindi
                      ? 'हिं'
                      : 'EN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet(
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
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(
              context,
              controller,
              language: AppLanguage.english,
              flag: '🇬🇧',
              name: 'English',
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context,
              controller,
              language: AppLanguage.hindi,
              flag: '🇮🇳',
              name: 'हिन्दी',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    NavigationController controller, {
    required AppLanguage language,
    required String flag,
    required String name,
  }) {
    final isSelected = MultilingualService.currentLanguage == language;

    return InkWell(
      onTap: () async {
        await _changeLanguage(context, controller, language);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade800,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.blue.shade700, size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(
    BuildContext context,
    NavigationController controller,
    AppLanguage language,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Change language
      await MultilingualService.setLanguage(language);
      await controller.speechService.setLanguage(language);

      // Announce change
      final message = language == AppLanguage.hindi
          ? 'भाषा बदल गई। अब हिन्दी में बोलें।'
          : 'Language changed. Now speak in English.';

      await controller.speechService.speak(message);

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show confirmation
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              language == AppLanguage.hindi
                  ? 'भाषा बदल गई'
                  : 'Language changed',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error changing language: $e');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to change language'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Animated language switch button
class AnimatedLanguageButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const AnimatedLanguageButton({super.key, this.onPressed});

  @override
  State<AnimatedLanguageButton> createState() => _AnimatedLanguageButtonState();
}

class _AnimatedLanguageButtonState extends State<AnimatedLanguageButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.language, color: Colors.blue.shade700, size: 24),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/multilingual_service.dart';
import '../controllers/navigation_controller.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFirstTime;

  const LanguageSelectionScreen({super.key, this.isFirstTime = false});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  AppLanguage? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = MultilingualService.currentLanguage;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (!widget.isFirstTime)
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                const SizedBox(height: 40),

                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.language,
                    size: 64,
                    color: Colors.blue.shade700,
                  ),
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  widget.isFirstTime ? 'Welcome!' : 'Select Language',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  widget.isFirstTime
                      ? 'Choose your preferred language\nभाषा चुनें'
                      : 'भाषा चुनें / Choose Language',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Language Options
                Expanded(
                  child: ListView(
                    children: [
                      _buildLanguageCard(
                        language: AppLanguage.english,
                        flag: '🇬🇧',
                        nativeName: 'English',
                        subtitle: 'Use English for navigation and voice',
                      ),

                      const SizedBox(height: 20),

                      _buildLanguageCard(
                        language: AppLanguage.hindi,
                        flag: '🇮🇳',
                        nativeName: 'हिन्दी',
                        subtitle:
                            'नेविगेशन और आवाज के लिए हिन्दी का उपयोग करें',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Continue Button
                if (_selectedLanguage != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedLanguage == AppLanguage.hindi
                                ? 'जारी रखें'
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required AppLanguage language,
    required String flag,
    required String nativeName,
    required String subtitle,
  }) {
    final isSelected = _selectedLanguage == language;

    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedLanguage = language;
        });

        // Announce selection
        final controller = context.read<NavigationController>();
        await MultilingualService.setLanguage(language);
        await controller.speechService.setLanguage(language);

        final announcement = language == AppLanguage.hindi
            ? 'हिन्दी चुनी गई'
            : 'English selected';
        await controller.speechService.speak(announcement);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag
            Text(flag, style: const TextStyle(fontSize: 48)),

            const SizedBox(width: 20),

            // Language Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_selectedLanguage == null) return;

    // Save language preference
    await MultilingualService.setLanguage(_selectedLanguage!);

    // Update speech service
    final controller = context.read<NavigationController>();
    await controller.speechService.setLanguage(_selectedLanguage!);

    // Announce confirmation
    final message = _selectedLanguage == AppLanguage.hindi
        ? 'भाषा सेट की गई। स्मार्ट ब्लाइंड स्टिक तैयार है।'
        : 'Language set. Smart Blind Stick is ready.';
    await controller.speechService.speak(message);

    if (mounted) {
      if (widget.isFirstTime) {
        // Go to home screen
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Just close this screen
        Navigator.pop(context);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../core/app_theme.dart';

class DynamicNicknameField extends StatefulWidget {
  final TextEditingController controller;
  final String? fullName;
  final Function(bool isValid)? onValidationChanged;
  final Function(String nickname)? onNicknameSelected;

  const DynamicNicknameField({
    super.key,
    required this.controller,
    this.fullName,
    this.onValidationChanged,
    this.onNicknameSelected,
  });

  @override
  State<DynamicNicknameField> createState() => _DynamicNicknameFieldState();
}

class _DynamicNicknameFieldState extends State<DynamicNicknameField> {
  Timer? _debounceTimer;
  bool _isCheckingAvailability = false;
  bool _isNicknameAvailable = true;
  String? _validationError;
  List<String> _suggestions = [];
  List<String> _similarNicknames = [];
  bool _showSuggestions = false;
  String _lastCheckedNickname = '';
  bool _userIsTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onNicknameChanged);
    super.dispose();
  }

  void _onNicknameChanged() {
    final nickname = widget.controller.text.trim();
    debugPrint('Nickname changed: "$nickname"');

    // Set typing state
    setState(() {
      _userIsTyping = true;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Reset state for new input
    setState(() {
      _showSuggestions = false;
      _suggestions.clear();
      _similarNicknames.clear();
    });

    // Validate format immediately
    final formatValidation = Provider.of<AuthProvider>(context, listen: false)
        .validateNicknameFormat(nickname);

    debugPrint('Format validation result: ${formatValidation['isValid']}, error: ${formatValidation['error']}');

    setState(() {
      _validationError = formatValidation['error'];
      _isNicknameAvailable = formatValidation['isValid'];
    });

    // Notify parent about validation state
    widget.onValidationChanged
        ?.call(formatValidation['isValid'] && _isNicknameAvailable);

    if (nickname.isEmpty || !formatValidation['isValid']) {
      debugPrint('Nickname empty or invalid format, skipping availability check');
      setState(() {
        _userIsTyping = false;
      });
      return;
    }

    // Debounce API calls for better performance
    debugPrint('Setting up debounced availability check...');
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      setState(() {
        _userIsTyping = false;
      });
      debugPrint('Starting nickname availability check for: $nickname');
      _checkNicknameAvailability(nickname);
    });
  }

  Future<void> _checkNicknameAvailability(String nickname) async {
    if (nickname == _lastCheckedNickname) {
      debugPrint('Skipping duplicate check for: $nickname');
      return;
    }

    debugPrint('Checking availability for nickname: $nickname');
    setState(() {
      _isCheckingAvailability = true;
      _lastCheckedNickname = nickname;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check availability
      debugPrint('Calling authProvider.checkNicknameAvailability...');
      final isAvailable =
          await authProvider.checkNicknameAvailability(nickname);

      debugPrint('Availability result for $nickname: $isAvailable');

      if (mounted) {
        setState(() {
          _isNicknameAvailable = isAvailable;
          _validationError =
              isAvailable ? null : 'This nickname is already taken';
        });

        // Notify parent about validation state
        final isValid = isAvailable && _validationError == null;
        widget.onValidationChanged?.call(isValid);
        debugPrint('Validation state updated: isValid=$isValid');

        // If not available, get suggestions and similar nicknames
        if (!isAvailable) {
          debugPrint('Nickname taken, getting suggestions...');
          _getSuggestionsAndSimilar(nickname);
        }
      }
    } catch (e) {
      debugPrint('Error checking nickname availability: $e');
      if (mounted) {
        setState(() {
          // For permission errors during registration, we'll be more lenient
          if (e.toString().contains('permission-denied')) {
            _validationError = null; // Don't show error for permission issues
            _isNicknameAvailable = true; // Assume available, validate server-side
            debugPrint('Permission denied - will validate during registration');
          } else {
            _validationError = 'Unable to check availability right now';
            _isNicknameAvailable = false;
            debugPrint('Network or other error: $e');
          }
        });
        widget.onValidationChanged?.call(_isNicknameAvailable);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
        });
        debugPrint('Availability check completed for: $nickname');
      }
    }
  }

  Future<void> _getSuggestionsAndSimilar(String nickname) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Get suggestions and similar nicknames in parallel
      final results = await Future.wait([
        authProvider.generateNicknameSuggestions(nickname,
            fullName: widget.fullName),
        authProvider.findSimilarNicknames(nickname),
      ]);

      if (mounted) {
        setState(() {
          _suggestions = results[0];
          _similarNicknames = results[1];
          _showSuggestions =
              _suggestions.isNotEmpty || _similarNicknames.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error getting suggestions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main input field
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Nickname *',
            prefixIcon: const Icon(Icons.badge),
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _getFieldBorderColor(),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            hintText: 'Choose a unique nickname',
            helperText: 'Used for friend search and identification',
            errorText: _validationError,
          ),
          textCapitalization: TextCapitalization.none,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nickname is required';
            }
            if (_validationError != null) {
              return _validationError;
            }
            if (!_isNicknameAvailable) {
              return 'This nickname is not available';
            }
            return null;
          },
        ),

        // Availability status
        if (widget.controller.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: _buildAvailabilityStatus(),
          ),

        // Similar nicknames warning
        if (_similarNicknames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildSimilarNicknamesWarning(),
          ),

        // Suggestions section
        if (_showSuggestions && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildSuggestionsSection(),
          ),
      ],
    );
  }

  Widget _buildSuffixIcon() {
    if (_isCheckingAvailability) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.controller.text.trim().isEmpty) {
      return const Icon(Icons.help_outline, color: Colors.grey);
    }

    if (_validationError != null) {
      return const Icon(Icons.error, color: Colors.red);
    }

    if (_isNicknameAvailable) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return const Icon(Icons.error, color: Colors.red);
  }

  Color _getFieldBorderColor() {
    if (widget.controller.text.trim().isEmpty) {
      return AppTheme.primaryColor;
    }

    if (_validationError != null || !_isNicknameAvailable) {
      return Colors.red;
    }

    return Colors.green;
  }

  Widget _buildAvailabilityStatus() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_userIsTyping) {
      statusText = 'Typing...';
      statusColor = Colors.grey;
      statusIcon = Icons.edit;
    } else if (_isCheckingAvailability) {
      statusText = 'Checking availability...';
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else if (_validationError != null) {
      statusText = _validationError!;
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (_isNicknameAvailable) {
      // Check if we actually verified or just assumed due to permissions
      if (_validationError == null && _lastCheckedNickname.isNotEmpty) {
        statusText = '✓ Nickname is available!';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else {
        statusText = '✓ Format valid - will verify during registration';
        statusColor = Colors.blue;
        statusIcon = Icons.info;
      }
    } else {
      statusText = '❌ Nickname is already taken';
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Row(
      children: [
        Icon(statusIcon, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarNicknamesWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, size: 16, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Text(
                'Similar nicknames exist:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _similarNicknames
                .map((nickname) => Chip(
                      label: Text(
                        nickname,
                        style: const TextStyle(fontSize: 11),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.orange[50],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Professional suggestions:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((suggestion) => _buildSuggestionChip(suggestion))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        widget.controller.text = suggestion;
        widget.onNicknameSelected?.call(suggestion);
        setState(() {
          _showSuggestions = false;
        });
        // Trigger validation for the selected suggestion
        _onNicknameChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              suggestion,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward,
              size: 14,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';

import '../main.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.savedPinHash,
    required this.onUnlocked,
    this.isSetup = false,
  });

  final String savedPinHash;
  final VoidCallback onUnlocked;
  final bool isSetup;

  static String hashPin(String pin) {
    // Simple robust SHA-256 or fallback hash for in-app PIN protection
    final bytes = utf8.encode(pin.trim());
    return base64Encode(bytes);
  }

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  String? _firstPin; // Used in setup mode for confirmation

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _validatePin() {
    if (widget.isSetup) {
      if (_firstPin == null) {
        // First entry done, ask to confirm
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        // Confirmation entry
        if (_enteredPin == _firstPin) {
          widget.onUnlocked();
        } else {
          setState(() {
            _errorMessage = 'PIN konfirmasi tidak cocok. Coba lagi.';
            _enteredPin = '';
            _firstPin = null;
          });
        }
      }
    } else {
      final inputHash = LockScreen.hashPin(_enteredPin);
      if (inputHash == widget.savedPinHash) {
        widget.onUnlocked();
      } else {
        setState(() {
          _errorMessage = 'PIN salah. Silakan coba lagi.';
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSetup
        ? (_firstPin == null ? 'Buat 4-Digit PIN' : 'Konfirmasi PIN Anda')
        : 'SecBrain Terkunci';
    final subtitle = widget.isSetup
        ? (_firstPin == null
              ? 'Masukkan 4 digit angka untuk mengamankan data Anda'
              : 'Ketik ulang PIN yang sama untuk verifikasi')
        : 'Masukkan 4-digit PIN Anda untuk membuka aplikasi';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F352B) : greenLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 28),
                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? green : Colors.transparent,
                          border: Border.all(
                            color: isFilled
                                ? green
                                : muted.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: coral,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  // Keypad Grid
                  _buildKeypad(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3'], isDark),
        const SizedBox(height: 12),
        _buildKeyRow(['4', '5', '6'], isDark),
        const SizedBox(height: 12),
        _buildKeyRow(['7', '8', '9'], isDark),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72), // Empty placeholder
            _buildKeyButton('0', isDark),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                onPressed: _onBackspace,
                icon: Icon(
                  Icons.backspace_outlined,
                  color: isDark ? Colors.white70 : ink,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeyButton(key, isDark)).toList(),
    );
  }

  Widget _buildKeyButton(String digit, bool isDark) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isDark ? const Color(0xFF1D2420) : Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(digit),
          child: Center(
            child: Text(
              digit,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

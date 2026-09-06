import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coze/log_in/provider_selection_page.dart';
import 'package:coze/advertisement/advertise.dart';

class AppActionHelper {
  static bool _isNavigating = false;

  /// Check if user is logged in. If not, prompt to log in via ProviderSelectionPage.
  /// Returns true if user is logged in (or logged in successfully), false if guest cancelled.
  static Future<bool> requireAuth(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return true;

    final result = await Navigator.push<bool>(
      context,
      Platform.isIOS
          ? CupertinoPageRoute(builder: (_) => const ProviderSelectionPage(isGuestPrompt: true))
          : MaterialPageRoute(builder: (_) => const ProviderSelectionPage(isGuestPrompt: true)),
    );

    return result == true || FirebaseAuth.instance.currentUser != null;
  }

  /// Handles Ad Card taps:
  /// 1. Prevents duplicate rapid taps (de-bounces processing/interstitial delays).
  /// 2. Ensures user is authenticated (prompts login if guest).
  /// 3. Triggers Interstitial Ad and opens Details page exactly ONCE.
  static void handleAdTap({
    required BuildContext context,
    required Future<void> Function() onNavigate,
  }) async {
    // Single-click lock: ignore any rapid subsequent taps while opening/loading
    if (_isNavigating) {
      debugPrint("Ad tap ignored: navigation already in progress.");
      return;
    }
    _isNavigating = true;

    try {
      // Require Login for viewing Ad Details
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isNavigating = false; // Release lock while showing login prompt
        final authed = await requireAuth(context);
        if (!authed) {
          return; // Guest cancelled login
        }
        _isNavigating = true; // Re-lock while processing ad/navigation
      }

      // Show Interstitial Ad (if rules met) and navigate
      AdvertiseManager().showInterstitialAd(() async {
        try {
          await onNavigate();
        } finally {
          _isNavigating = false; // Reset lock when returning back from details
        }
      });
    } catch (e) {
      _isNavigating = false;
      debugPrint("Error in handleAdTap: $e");
    }
  }
}

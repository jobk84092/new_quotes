import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportDeveloperButton extends StatelessWidget {
  const SupportDeveloperButton({super.key});

  // TODO: Replace with your Stripe Payment Link (Dashboard -> Payment Links -> Copy link)
  // Example: https://buy.stripe.com/abc123xyz
  static const String _stripePaymentLink = 'REPLACE_WITH_YOUR_STRIPE_PAYMENT_LINK';

  Future<void> _openStripeLink(BuildContext context) async {
    final uri = Uri.parse(_stripePaymentLink);

    // Force external browser to avoid in-app webview confusion.
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open payment link. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openStripeLink(context),
      icon: const Icon(Icons.local_cafe_outlined),
      label: const Text('Buy me coffee'),
    );
  }
}


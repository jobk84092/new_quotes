import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportDeveloperButton extends StatelessWidget {
  const SupportDeveloperButton({super.key});

  // Replace with your Stripe Payment Link when ready: https://buy.stripe.com/xxx
  static const String _stripePaymentLink = 'REPLACE_WITH_YOUR_STRIPE_PAYMENT_LINK';

  @override
  Widget build(BuildContext context) {
    // Hide button until real payment link is configured
    if (_stripePaymentLink.contains('REPLACE')) {
      return const SizedBox.shrink();
    }
    return ElevatedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(_stripePaymentLink);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: const Icon(Icons.local_cafe_outlined),
      label: const Text('Buy me coffee'),
    );
  }
}


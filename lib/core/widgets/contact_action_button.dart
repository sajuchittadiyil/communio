import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/colors.dart';

enum ContactActionType { call, whatsApp, email }

class ContactActionButton extends StatelessWidget {
  const ContactActionButton({
    required this.type,
    required this.value,
    required this.personName,
    this.size = 36,
    super.key,
  });

  final ContactActionType type;
  final String value;
  final String personName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      ContactActionType.call => AppColors.info,
      ContactActionType.whatsApp => AppColors.success,
      ContactActionType.email => AppColors.purple,
    };
    final label = switch (type) {
      ContactActionType.call => 'Call',
      ContactActionType.whatsApp => 'WhatsApp',
      ContactActionType.email => 'Email',
    };
    final uri = switch (type) {
      ContactActionType.call => Uri(scheme: 'tel', path: value),
      ContactActionType.whatsApp => Uri.https(
        'wa.me',
        '/${normalizeInternationalPhone(value)}',
      ),
      ContactActionType.email => Uri(scheme: 'mailto', path: value),
    };
    return IconButton(
      tooltip: '$label $personName',
      visualDensity: size >= 44
          ? VisualDensity.standard
          : VisualDensity.compact,
      constraints: BoxConstraints.tightFor(width: size, height: size),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: .08),
        side: BorderSide(color: color.withValues(alpha: .14)),
      ),
      icon: switch (type) {
        ContactActionType.call => Icon(
          Icons.call_outlined,
          size: 18,
          color: color,
        ),
        ContactActionType.whatsApp => FaIcon(
          FontAwesomeIcons.whatsapp,
          size: 17,
          color: color,
        ),
        ContactActionType.email => Icon(
          Icons.email_outlined,
          size: 18,
          color: color,
        ),
      },
      onPressed: () => _launch(context, uri),
    );
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) _showFailure(context);
    } catch (_) {
      if (context.mounted) _showFailure(context);
    }
  }

  void _showFailure(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Unable to open this contact action.')),
    );
  }
}

class ContactActionButtons extends StatelessWidget {
  const ContactActionButtons({
    required this.personName,
    this.phone,
    this.whatsApp,
    this.email,
    this.compact = true,
    super.key,
  });

  final String personName;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final callValue = isValidPhone(phone) ? phone!.trim() : null;
    final whatsAppCandidate = isValidPhone(whatsApp) ? whatsApp : callValue;
    final whatsAppValue = isValidPhone(whatsAppCandidate)
        ? whatsAppCandidate!.trim()
        : null;
    final emailValue = isValidEmail(email) ? email!.trim() : null;

    return Wrap(
      spacing: compact ? 4 : 8,
      runSpacing: 4,
      children: [
        if (callValue != null)
          ContactActionButton(
            type: ContactActionType.call,
            value: callValue,
            personName: personName,
            size: compact ? 36 : 48,
          ),
        if (whatsAppValue != null)
          ContactActionButton(
            type: ContactActionType.whatsApp,
            value: whatsAppValue,
            personName: personName,
            size: compact ? 36 : 48,
          ),
        if (emailValue != null)
          ContactActionButton(
            type: ContactActionType.email,
            value: emailValue,
            personName: personName,
            size: compact ? 36 : 48,
          ),
      ],
    );
  }
}

bool isValidPhone(String? value) =>
    value != null && normalizeInternationalPhone(value).length >= 7;

bool isValidEmail(String? value) {
  if (value == null) return false;
  final email = value.trim();
  final at = email.indexOf('@');
  return at > 0 &&
      at < email.length - 1 &&
      email.substring(at + 1).contains('.');
}

String normalizeInternationalPhone(String value) =>
    value.replaceAll(RegExp(r'[^0-9]'), '');

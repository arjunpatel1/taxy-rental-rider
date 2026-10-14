import '../manage_imports.dart';

/// Support contacts come from the same administrator settings as the dashboard.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = appStore.settingModel;
    final phone = (settings.contactNumber ?? '').trim();
    final email = (settings.contactEmail ?? settings.siteEmail ?? '').trim();
    final address = (settings.officeAddress ?? '').trim();
    Future<void> open(Uri uri) async {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          toast('Unable to open this contact option');
        }
      } catch (_) { toast('Unable to open this contact option'); }
    }
    Widget contact(String title, String value, IconData icon, Color color, VoidCallback action) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color)),
          title: Text(title, style: boldTextStyle(size: 18)),
          subtitle: Text(value.isEmpty ? 'Not configured yet' : value, style: secondaryTextStyle(size: 16)),
          onTap: value.isEmpty ? null : action,
        ),
      );
    }
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsapp = digits.length == 10 ? '91$digits' : digits;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        contact('WhatsApp Us', phone, Icons.chat_outlined, Colors.green,
            () => open(Uri.parse('https://wa.me/$whatsapp'))),
        contact('Call Us', phone, Icons.phone_outlined, Colors.blue,
            () => open(Uri(scheme: 'tel', path: phone))),
        contact('Mail Us', email, Icons.mail_outline, Colors.red,
            () => open(Uri(scheme: 'mailto', path: email))),
        const SizedBox(height: 16),
        Text('Company Address', style: boldTextStyle(size: 20)),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(24),
            child: Text(address.isEmpty ? 'Not configured yet' : address, style: primaryTextStyle(size: 17)))),
      ]),
    );
  }
}

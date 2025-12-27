import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/smart_action_service.dart';

class SmartActionsWidget extends StatelessWidget {
  final List<SmartAction> actions;

  const SmartActionsWidget({super.key, required this.actions});

  Future<void> _handleAction(BuildContext context, SmartAction action) async {
    Uri? uri;
    switch (action.type) {
      case ActionType.phone:
        uri = Uri.parse("tel:${action.value.replaceAll(RegExp(r'\s'), '')}");
        break;
      case ActionType.email:
        uri = Uri.parse("mailto:${action.value}");
        break;
      case ActionType.url:
        String url = action.value;
        if (!url.startsWith('http')) {
          url = 'https://$url';
        }
        uri = Uri.parse(url);
        break;
      case ActionType.address:
        // Open Google Maps search
        uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(action.value)}");
        break;
    }

    if (uri != null) {
      try {
        if (!await launchUrl(uri, mode: (action.type == ActionType.url || action.type == ActionType.address) ? LaunchMode.externalApplication : LaunchMode.platformDefault)) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not launch ${action.label}')));
           }
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Smart Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          separatorBuilder: (ctx, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final action = actions[index];
            return Card(
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Icon(action.icon, color: Colors.deepPurple),
                ),
                title: Text(action.label, overflow: TextOverflow.ellipsis),
                subtitle: Text(action.type.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _handleAction(context, action),
              ),
            );
          },
        ),
      ],
    );
  }
}

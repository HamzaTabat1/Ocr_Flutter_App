import 'dart:convert';

import 'package:flutter/material.dart';

enum ActionType { phone, email, url, address }

class SmartAction {
  final ActionType type;
  final String value;
  final String label;
  final IconData icon;

  SmartAction({
    required this.type,
    required this.value,
    required this.label,
    required this.icon,
  });
}

class SmartActionService {
  // Regex patterns
  static final RegExp _phoneRegex = RegExp(r'\+?\d[\d -]{8,}\d');
  static final RegExp _emailRegex = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
  static final RegExp _urlRegex = RegExp(r'(?:https?:\/\/|www\.)[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&//=]*)', caseSensitive: false);
  
  // Keywords for address detection (simple heuristic)
  static final List<String> _addressKeywords = [
    'St', 'Street', 'Ave', 'Avenue', 'Rd', 'Road', 'Blvd', 'Boulevard',
    'Ln', 'Lane', 'Dr', 'Drive', 'Court', 'Ct', 'Plaza', 'Square', 'Hwy', 'Highway',
    'Parkway', 'Pkwy', 'Way', 'Cir', 'Circle', 'Walk', 'Loop', 'Place', 'Pl', 'Terrace', 'Dr', 'Drive'
  ];

  List<SmartAction> parseText(String text) {
    List<SmartAction> actions = [];
    
    // Detect Phone Numbers
    final phoneMatches = _phoneRegex.allMatches(text);
    for (var match in phoneMatches) {
      String phone = match.group(0)!;
      // Filter out some false positives like dates 2023-12-12 if needed, but keeping simple for now
      if (phone.replaceAll(RegExp(r'\D'), '').length >= 9) { // Ensure enough digits
         actions.add(SmartAction(
          type: ActionType.phone,
          value: phone,
          label: 'Call $phone',
          icon: Icons.phone,
        ));
      }
    }

    // Detect Emails
    final emailMatches = _emailRegex.allMatches(text);
    for (var match in emailMatches) {
        String email = match.group(0)!;
        actions.add(SmartAction(
          type: ActionType.email,
          value: email,
          label: 'Email $email',
          icon: Icons.email,
        ));
    }

    // Detect URLs
    final urlMatches = _urlRegex.allMatches(text);
    for (var match in urlMatches) {
        String url = match.group(0)!;
        actions.add(SmartAction(
          type: ActionType.url,
          value: url,
          label: 'Open $url',
          icon: Icons.language,
        ));
    }

    // Detect Addresses (Simple Line-based Heuristic)
    // We check lines that contain numbers AND address keywords
    LineSplitter ls = const LineSplitter();
    List<String> lines = ls.convert(text);
    for (var line in lines) {
      bool hasNumber = line.contains(RegExp(r'\d'));
      bool hasKeyword = _addressKeywords.any((kw) => line.contains(RegExp(r'\b' + kw + r'\b', caseSensitive: false)));
      
      // Avoid re-adding things that look like other matches if possible, 
      // but for now let's just add if it matches heuristic and isn't a URL
      // Heuristic:
      // 1. Contains a number AND an address keyword (Street, Parkway, etc.)
      // OR
      // 2. Looks like a State + Zip (e.g., CA 94043)
      bool isZipLine = line.contains(RegExp(r'\b[A-Z]{2}\s+\d{5}\b'));
      
      if ((hasNumber && hasKeyword) || isZipLine) {
        // filter out urls/emails just in case
        if (!_urlRegex.hasMatch(line) && !_emailRegex.hasMatch(line)) {
           actions.add(SmartAction(
            type: ActionType.address,
            value: line.trim(),
            label: 'Map: ${line.trim()}',
            icon: Icons.map,
          ));
        }
      }
    }

    return actions;
  }
}

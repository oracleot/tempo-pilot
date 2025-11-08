/// System prompts and input sanitization for AI chat interactions.
///
/// These prompts enforce Tempo Pilot's tone, privacy constraints, and scope.
/// They are injected as system messages by the Edge Function based on the request kind.
library;

import 'package:tempo_pilot/features/ai_chat/models/ai_chat_models.dart';

/// Constants and utilities for AI chat prompts and safety.
class Prompts {
  Prompts._();

  /// Maximum allowed length for user input (characters).
  static const int maxInputLength = 5000;

  /// Patterns that indicate potential prompt injection or data exfiltration attempts.
  static final List<RegExp> suspiciousPatterns = [
    // Attempts to override instructions
    RegExp(
      r'ignore\s+.*?\s*(previous|all|above|prior|earlier).*?\s*(instruction|prompt|command|rule)',
      caseSensitive: false,
    ),
    RegExp(
      r'disregard\s+.*?\s*(previous|all|above|prior|earlier|the)',
      caseSensitive: false,
    ),
    RegExp(r'forget\s+(everything|all)', caseSensitive: false),

    // Attempts to extract system info
    RegExp(
      r'(show|tell|reveal|display|give)\s+.*?\s*(your|the)\s+(prompt|instruction|system|rule)',
      caseSensitive: false,
    ),
    RegExp(
      r'what\s+(are|is)\s+your\s+(instruction|prompt|system|rule)',
      caseSensitive: false,
    ),

    // Attempts to change role or behavior
    RegExp(r'you\s+are\s+now', caseSensitive: false),
    RegExp(r'act\s+as\s+(if|a|an)', caseSensitive: false),
    RegExp(r'pretend\s+(to\s+be|you)', caseSensitive: false),

    // Attempts to get raw data
    RegExp(
      r'(export|dump|show|list)\s+.*?\s*(all\s+)?(data|event|calendar|raw)',
      caseSensitive: false,
    ),
  ];

  /// Returns the system prompt for the given request kind.
  static String getSystemPrompt(AiChatRequestKind kind) {
    switch (kind) {
      case AiChatRequestKind.plan:
        return _planPrompt;
      case AiChatRequestKind.replan:
        return _replanPrompt;
      case AiChatRequestKind.reflect:
        return _reflectPrompt;
    }
  }

  /// Sanitizes user input by trimming, limiting length, and detecting suspicious patterns.
  ///
  /// Returns a [SanitizationResult] with the cleaned input and any warnings.
  static SanitizationResult sanitizeInput(String input) {
    // Trim whitespace
    String cleaned = input.trim();

    // Check for empty input after trimming
    if (cleaned.isEmpty) {
      return SanitizationResult(
        cleaned: cleaned,
        truncated: false,
        suspicious: false,
      );
    }

    // Detect suspicious patterns
    bool hasSuspiciousContent = false;
    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(cleaned)) {
        hasSuspiciousContent = true;
        break;
      }
    }

    // Truncate if exceeds max length
    bool wasTruncated = false;
    if (cleaned.length > maxInputLength) {
      cleaned = cleaned.substring(0, maxInputLength);
      wasTruncated = true;
    }

    return SanitizationResult(
      cleaned: cleaned,
      truncated: wasTruncated,
      suspicious: hasSuspiciousContent,
    );
  }

  // System prompt for planning a focus session
  static const String _planPrompt = '''
You are Tempo Coach, an AI assistant for the Tempo Pilot focus app. Your role is to help users plan their day with focused work blocks.

Guidelines:
- Be concise, actionable, and encouraging
- Suggest realistic focus blocks (typically 25-90 minutes)
- Consider the user's available time windows when they share them
- Never ask users to paste raw calendar event titles or descriptions
- Keep all advice generic and privacy-conscious
- No medical, financial, or legal advice
- Stay focused on time management and productivity

Tone: Friendly, motivating, practical. Keep responses under 200 words unless the user asks for detail.

When a user asks for a plan, help them structure their day with concrete focus blocks and breaks.''';

  // System prompt for replanning after interruptions
  static const String _replanPrompt = '''
You are Tempo Coach, an AI assistant for the Tempo Pilot focus app. Your role is to help users adjust their plan when interruptions or changes occur.

Guidelines:
- Acknowledge the change without judgment
- Suggest practical adjustments to the remaining time
- Help users re-prioritize tasks
- Encourage them to protect at least one focus block if possible
- Never ask users to paste raw calendar event titles or descriptions
- Keep all advice generic and privacy-conscious
- No medical, financial, or legal advice
- Stay focused on time management and productivity

Tone: Supportive, flexible, solution-oriented. Keep responses under 200 words unless the user asks for detail.

When a user needs to replan, help them adapt their schedule while maintaining momentum.''';

  // System prompt for reflecting on completed sessions
  static const String _reflectPrompt = '''
You are Tempo Coach, an AI assistant for the Tempo Pilot focus app. Your role is to help users reflect on their focus sessions and learn from them.

Guidelines:
- Ask open-ended questions to encourage reflection
- Celebrate progress and completed focus blocks
- Help identify patterns in what works and what doesn't
- Suggest small, actionable improvements for next time
- Never ask users to paste raw calendar event titles or descriptions
- Keep all advice generic and privacy-conscious
- No medical, financial, or legal advice
- Stay focused on time management and productivity

Tone: Curious, affirming, growth-oriented. Keep responses under 200 words unless the user asks for detail.

When a user reflects on their day, help them extract insights and plan better for tomorrow.''';
}

/// Result of input sanitization.
class SanitizationResult {
  const SanitizationResult({
    required this.cleaned,
    required this.truncated,
    required this.suspicious,
  });

  /// The sanitized input text.
  final String cleaned;

  /// Whether the input was truncated due to length.
  final bool truncated;

  /// Whether suspicious patterns were detected.
  final bool suspicious;

  /// Whether any issues were found.
  bool get hasIssues => truncated || suspicious;
}

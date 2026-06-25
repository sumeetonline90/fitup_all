import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/chat_message.dart';

/// User (right, cyan) or assistant (left, glass) chat row.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool user = message.role == ChatRole.user;
    final String ts = DateFormat.jm().format(message.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!user) ...<Widget>[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceContainerHigh,
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: user
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.22),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Text(message.content, style: AppTextStyles.bodyLarge),
                        const SizedBox(height: 4),
                        Text(ts, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : GlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(message.content, style: AppTextStyles.bodyLarge),
                        const SizedBox(height: 4),
                        Text(ts, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

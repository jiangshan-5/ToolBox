import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/provider/auth_provider.dart';
import 'profile_dialogs.dart';

class ProfileHeader extends ConsumerWidget {
  final String userEmail;
  final String userNickname;

  const ProfileHeader({
    super.key,
    required this.userEmail,
    required this.userNickname,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderDividerColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final auth = ref.watch(authProvider);
    final currentAvatarUrl = auth.avatarUrl;
    final signature = auth.bio ?? '这个人很懒，什么都没有留下...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '个人主页',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1E2C), const Color(0xFF2D2A4A)]
                    : [
                        primaryColor.withOpacity(0.12),
                        secondaryColor.withOpacity(0.08)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? primaryColor.withOpacity(0.3)
                    : primaryColor.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(isDark ? 0.15 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ProfileDialogs.showAvatarSelectionDialog(context, ref),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                        ),
                      ),
                      child: ProfileDialogs.buildAvatarWidget(currentAvatarUrl, 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => ProfileDialogs.showEditProfileDialog(context, ref, userNickname),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Row(
                            children: [
                              Text(
                                userNickname,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit_rounded,
                                color: isDark ? Colors.white54 : Colors.black54,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail.isEmpty ? '游客模式体验中' : userEmail,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Inline Bio Signature Box
                      GestureDetector(
                        onTap: () => ProfileDialogs.showEditBioDialog(context, ref, signature),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderDividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.psychology_outlined, color: Colors.cyanAccent, size: 12),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    signature,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                                      fontSize: 10.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.mode_edit_outline_rounded, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black38, size: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.2),
                              Colors.orange.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Premium 尊享会员',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

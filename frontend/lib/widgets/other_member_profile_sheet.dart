import 'package:flutter/material.dart';
import 'package:frontend/core/kst_calendar.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/meeting.dart';

/// 다른 구성원 프로필(모임·잔류 화면에서 표시 가능한 정보만)
void showOtherMemberProfile(
  BuildContext context, {
  required String displayName,
  required String initial,
  MeetingRole? meetingRole,
  String? roleLabel,
  required bool isPresent,
  String? checkIn,
  String? lastExit,
}) {
  final todayYmd = KstCalendar.ymdFromInstant(DateTime.now());
  final statusLine = isPresent
      ? '체크인 ${KstCalendar.formatCheckTimeForDisplay(checkIn, assumeUtcWallOnDate: todayYmd)}'
      : '마지막 퇴실 ${KstCalendar.formatDateTimeKstDisplay(lastExit)}';

  String? roleText = roleLabel;
  if (roleText == null || roleText.isEmpty) {
    if (meetingRole == MeetingRole.leader) {
      roleText = '모임장';
    } else if (meetingRole == MeetingRole.member) {
      roleText = '구성원';
    }
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(ctx).bottom + 16,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                        child: Text(
                          initial.isNotEmpty ? initial : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isNotEmpty ? displayName : '닉네임 없음',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            if (roleText != null && roleText.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  roleText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPresent
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isPresent
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPresent ? '랩실 잔류 중' : '랩실 밖',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statusLine,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '연락처 등은 보이지 않습니다. 이 모임에서 공개된 정보만 표시됩니다.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

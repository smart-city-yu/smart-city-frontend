import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/map_issue.dart';
import '../sheet_handle.dart';

void showIssueDetailsSheet({
  required BuildContext context,
  required MapIssue issue,
  required bool alreadyVoted,
  required VoidCallback onVoteStillThere,
  required VoidCallback onVoteFixed,
}) {
  bool submitted = false;
  String selectedVote = '';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            margin: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.topRight,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.grey, size: 28),
                    ),
                  ),
                  if (!submitted) ...[
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(child: Text(issue.emoji, style: const TextStyle(fontSize: 38))),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        issue.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        issue.sub,
                        style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        issue.desc,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Is this issue still there?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (alreadyVoted)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE6C95A), width: 2),
                        ),
                        child: const Text(
                          '⚠️ You already voted on this report.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                onVoteStillThere();
                                selectedVote = 'still_there';
                                setSheetState(() => submitted = true);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.green, width: 2.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                '✓ Still there',
                                style: TextStyle(
                                  color: AppColors.greenDark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                onVoteFixed();
                                selectedVote = 'fixed';
                                setSheetState(() => submitted = true);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFC43C34), width: 2.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                '✗ Fixed',
                                style: TextStyle(
                                  color: Color(0xFFC43C34),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ] else ...[
                    const SizedBox(height: 24),
                    Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('✅', style: TextStyle(fontSize: 40))),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Successfully Submitted',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedVote == 'still_there'
                          ? 'Your vote was submitted successfully as: Still there.'
                          : 'Your vote was submitted successfully as: Fixed.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

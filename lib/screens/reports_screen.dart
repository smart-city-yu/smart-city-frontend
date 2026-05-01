import 'package:flutter/material.dart';
import '../models/map_issue.dart';
import '../parsers/map_issue_parser.dart';
import '../services/fake_report_service.dart';
import '../core/app_colors.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  FakeReportService myService = FakeReportService();
  List<MapIssue> myReports = [];
  bool loading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  void fetchReports() async {
    setState(() {
      loading = true;
      errorMsg = '';
    });

    try {
      List<Map<String, dynamic>> data = await myService.getMyReports();
      List<MapIssue> parsed = [];

      for (int i = 0; i < data.length; i++) {
        parsed.add(MapIssueParser.fromJson(data[i]));
      }

      setState(() {
        myReports = parsed;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Something went wrong!';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Padding(
          padding: EdgeInsets.only(left: 25),
          child: Text(
            "My Reports",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.green,
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.only(left: 25, bottom: 20),
          child: Text(
            "Tap to see AI analysis & live votes",
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
        ),
        Expanded(child: buildContent()),
      ],
    );
  }

  Widget buildContent() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (errorMsg != '') {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMsg, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: fetchReports,
              child: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    if (myReports.isEmpty) {
      return const Center(child: Text("You have no reports yet."));
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        fetchReports();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: myReports.length,
        itemBuilder: (context, index) {
          MapIssue item = myReports[index];

          Color badgeColor = Colors.orange;
          String badgeText = 'Under Processing';

          if (item.sub.toLowerCase().contains('accepted')) {
            badgeColor = Colors.green;
            badgeText = 'Accepted';
          } else if (item.sub.toLowerCase().contains('declined')) {
            badgeColor = Colors.red;
            badgeText = 'Declined';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => showDetails(index),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void showDetails(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            MapIssue issue = myReports[index];

            Color badgeColor = Colors.orange;
            String badgeText = 'Under Processing';

            if (issue.sub.toLowerCase().contains('accepted')) {
              badgeColor = Colors.green;
              badgeText = 'Accepted';
            } else if (issue.sub.toLowerCase().contains('declined')) {
              badgeColor = Colors.red;
              badgeText = 'Declined';
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${issue.emoji} ${issue.title}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.textGrey, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        "${issue.position.latitude.toStringAsFixed(4)}, ${issue.position.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: issue.isVoted
                              ? null
                              : () async {
                            bool ok = await myService.voteOnReport(
                              reportId: issue.id,
                              voteType: 'stillThere',
                            );
                            if (ok) {
                              setSheetState(() {
                                myReports[index] = issue.copyWith(
                                  stillThereCount:
                                  issue.stillThereCount + 1,
                                  isVoted: true,
                                );
                              });
                              setState(() {});
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(
                                  alpha: issue.isVoted ? 0.05 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                  Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: issue.isVoted
                                        ? Colors.grey
                                        : Colors.orange,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  "${issue.stillThereCount}",
                                  style: TextStyle(
                                    color: issue.isVoted
                                        ? Colors.grey
                                        : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Still There",
                                  style: TextStyle(
                                    color: issue.isVoted
                                        ? Colors.grey
                                        : Colors.orange,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: issue.isVoted
                              ? null
                              : () async {
                            bool ok = await myService.voteOnReport(
                              reportId: issue.id,
                              voteType: 'fixed',
                            );
                            if (ok) {
                              setSheetState(() {
                                myReports[index] = issue.copyWith(
                                  fixedCount: issue.fixedCount + 1,
                                  isVoted: true,
                                );
                              });
                              setState(() {});
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(
                                  alpha: issue.isVoted ? 0.05 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                  Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: issue.isVoted
                                        ? Colors.grey
                                        : Colors.green,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  "${issue.fixedCount}",
                                  style: TextStyle(
                                    color: issue.isVoted
                                        ? Colors.grey
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Fixed",
                                  style: TextStyle(
                                    color: issue.isVoted
                                        ? Colors.grey
                                        : Colors.green,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (issue.isVoted)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "✅ You already voted on this report",
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                    ),
                  const Divider(height: 35),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.info, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "AI Smart Analysis",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      issue.desc.isEmpty
                          ? "AI analysis not available yet."
                          : issue.desc,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
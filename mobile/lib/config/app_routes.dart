import 'package:flutter/material.dart';
import '../screens/citizen/report_issue_screen.dart';
import '../screens/citizen/my_reports_screen.dart';
import '../screens/admin/admin_map_screen.dart';
import '../screens/admin/issue_detail_screen.dart';

class AppRoutes {
  static const String reportIssue = '/';
  static const String myReports = '/my-reports';
  static const String adminMap = '/admin-map';
  static const String issueDetail = '/issue-detail';

  static Map<String, WidgetBuilder> get routes => {
        reportIssue: (context) => const ReportIssueScreen(),
        myReports: (context) => const MyReportsScreen(),
        adminMap: (context) => const AdminMapScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == issueDetail) {
      final complaintId = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => IssueDetailScreen(complaintId: complaintId ?? ''),
      );
    }
    return null;
  }
}

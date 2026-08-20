import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/app_routes.dart';
import '../../models/complaint_model.dart';
import '../../services/api_client.dart';
import '../../widgets/severity_badge.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({Key? key}) : super(key: key);

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ApiClient _apiClient = ApiClient();
  late Future<List<ComplaintModel>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _apiClient.fetchMyComplaints();
  }

  Future<void> _refresh() async {
    setState(() {
      _complaintsFuture = _apiClient.fetchMyComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ComplaintModel>>(
          future: _complaintsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                  ],
                ),
              );
            }

            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return const Center(
                child: Text('No complaints submitted yet.', style: TextStyle(color: AppTheme.textMuted)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final complaint = list[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: complaint.imageUrl.isNotEmpty
                            ? Image.network(complaint.imageUrl, fit: BoxFit.cover)
                            : const Icon(Icons.image),
                      ),
                    ),
                    title: Text(
                      complaint.address.isNotEmpty
                          ? complaint.address
                          : 'Report #${complaint.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          complaint.userDescription.isNotEmpty
                              ? complaint.userDescription
                              : 'No description provided',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SeverityBadge(severity: complaint.severityScore),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                complaint.status,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.issueDetail,
                        arguments: complaint.id,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

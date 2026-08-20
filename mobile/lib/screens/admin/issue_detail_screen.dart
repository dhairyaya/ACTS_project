import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/complaint_model.dart';
import '../../services/api_client.dart';
import '../../widgets/severity_badge.dart';

class IssueDetailScreen extends StatefulWidget {
  final String complaintId;

  const IssueDetailScreen({Key? key, required this.complaintId}) : super(key: key);

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  late Future<ComplaintModel> _detailFuture;
  final TextEditingController _notesController = TextEditingController();
  String? _selectedStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _detailFuture = _apiClient.fetchComplaintDetail(widget.complaintId);
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;
    setState(() => _isUpdating = true);
    try {
      await _apiClient.updateComplaintStatus(
        id: widget.complaintId,
        status: _selectedStatus!,
        adminNotes: _notesController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );
      _loadDetail();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Triage Details'),
      ),
      body: FutureBuilder<ComplaintModel>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading details: ${snapshot.error}'));
          }

          final complaint = snapshot.data!;
          if (_selectedStatus == null) {
            _selectedStatus = complaint.status;
            _notesController.text = complaint.adminNotes;
          }

          final gemini = complaint.geminiAnalysis;
          final yolo = complaint.yoloDetections;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Display
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 240,
                    color: Colors.grey[200],
                    child: complaint.imageUrl.isNotEmpty
                        ? Image.network(complaint.imageUrl, fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 64),
                  ),
                ),

                const SizedBox(height: 16),

                // Severity & Validation Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SeverityBadge(severity: complaint.severityScore, fontSize: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: complaint.isValidImage ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: complaint.isValidImage ? Colors.green : Colors.orange,
                        ),
                      ),
                      child: Text(
                        complaint.isValidImage ? 'CV Check: Clear' : 'CV Check: Blurry',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: complaint.isValidImage ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Gemini AI Synthesis Card
                Card(
                  elevation: 0,
                  color: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Gemini AI Triage Analysis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text('Category: ${gemini['category'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Assigned Dept: ${gemini['department'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Urgency: ${gemini['urgency'] ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('AI Summary: ${gemini['summary'] ?? complaint.userDescription}'),
                        if (gemini['recommended_action'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Action Plan: ${gemini['recommended_action']}',
                            style: const TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textDark),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Location Details
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        Text('Address: ${complaint.address.isNotEmpty ? complaint.address : "No address specified"}'),
                        const SizedBox(height: 4),
                        Text('Coordinates: ${complaint.latitude}, ${complaint.longitude}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Status Update & Action Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Update Status & Dispatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
                            DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                            DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                            DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Admin Notes / Crew Remarks',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : _updateStatus,
                            child: _isUpdating
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('SAVE STATUS'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

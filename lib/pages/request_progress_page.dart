import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestProgressPage extends StatelessWidget {
  final String requestId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RequestProgressPage({required this.requestId});

  final List<String> stages = [
    'Created',
    'Pending with Purchase Officer',
    'Approved',
    'Completed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Request Progress")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('requests').doc(requestId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text("Request not found"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var progress = data['progress'] as List<dynamic>?;
          var currentStatus = data['status'] as String? ?? 'Created';
          var currentStageIndex = stages.indexOf(currentStatus);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressBar(currentStageIndex),
                SizedBox(height: 32),
                Text(
                  "Progress Timeline",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: progress?.length ?? 0,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      var entry = progress![index];
                      var role = entry['role'];
                      var action = entry['action'];
                      var timestamp = entry['timestamp'];
                      var formattedTime = _formatTimestamp(timestamp);

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconForRole(role),
                          SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      action,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "$role - $formattedTime",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(int currentStageIndex) {
    return Row(
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          // Circle and Label
          Column(
            children: [
              // Progress Circle
              CircleAvatar(
                radius: 22, // Slightly larger for better visibility
                backgroundColor:
                    i <= currentStageIndex ? Colors.blue : Colors.grey[300],
                child: Icon(
                  _getStageIcon(i),
                  color: Colors.white,
                  size: 24, // Larger icon for better visibility
                ),
              ),
              const SizedBox(height: 8),
              // Stage Label
              Text(
                stages[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      i <= currentStageIndex ? Colors.blue[900] : Colors.grey,
                ),
              ),
            ],
          ),
          // Connecting Line
          if (i < stages.length - 1)
            Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < currentStageIndex ? Colors.blue : Colors.grey[300],
              ),
            ),
        ],
      ],
    );
  }

// Helper Function to Get Icon for Each Stage
  IconData _getStageIcon(int index) {
    switch (index) {
      case 0:
        return Icons.create; // Created
      case 1:
        return Icons.pending; // Pending
      case 2:
        return Icons.approval; // Approved
      case 3:
        return Icons.done; // Completed
      default:
        return Icons.help_outline; // Default icon
    }
  }

  Widget _buildIconForRole(String role) {
    IconData icon;
    Color color;

    switch (role) {
      case 'Site':
        icon = Icons.home_work;
        color = Colors.blue;
        break;
      case 'PurchaseOfficer':
        icon = Icons.shopping_cart;
        color = Colors.green;
        break;
      default:
        icon = Icons.person;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color,
      radius: 24,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      var dateTime = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd – hh:mm a').format(dateTime);
    } catch (e) {
      return "Invalid date";
    }
  }
}

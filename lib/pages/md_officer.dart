import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MDPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MD Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('requests')
            .where('assignedTo', isEqualTo: 'MD')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No requests pending approval."));
          }

          var requests = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Pending with MD';
          }).toList();

          var approvedRequests = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Approved';
          }).toList();

          var rejectedRequests = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'Rejected';
          }).toList();

          return ListView(
            children: [
              _buildSection('Requests', requests, context),
              _buildSection('Approved', approvedRequests, context),
              _buildSection('Rejected', rejectedRequests, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<QueryDocumentSnapshot> docs, BuildContext context) {
    if (docs.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? '';
            Color cardColor;

            
            if (status == 'Approved') {
              cardColor = Colors.green[100]!;
            } else if (status == 'Rejected') {
              cardColor = Colors.red[100]!;
            } else {
              cardColor = Colors.white;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              elevation: 2.0,
              color: cardColor,
              child: ListTile(
                title: Text(
                  data['description'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Status: ${data['status']}"),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetailsPage(requestId: doc.id),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class RequestDetailsPage extends StatelessWidget {
  final String requestId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RequestDetailsPage({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Request Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('requests').doc(requestId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Request not found."));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          var progress = data['progress'] as List<dynamic>?;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Description: ${data['description']}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Quantity: ${data['quantity']} ${data['unit']}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  "Status: ${data['status']}",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),
                Text(
                  "Progress Timeline",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: progress != null && progress.isNotEmpty
                      ? ListView.separated(
                          itemCount: progress.length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            var entry = progress[index];
                            var role = entry['role'];
                            var action = entry['action'];
                            var timestamp = entry['timestamp'];
                            return ListTile(
                              title: Text(action),
                              subtitle: Text("$role - $timestamp"),
                            );
                          },
                        )
                      : Center(child: Text("No progress available.")),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updateRequestStatus(context, 'Approved');
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showRejectDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                      child: Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  
  void _showRejectDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Provide Feedback for Rejection"),
          content: TextField(
            controller: feedbackController,
            decoration: InputDecoration(hintText: "Enter rejection reason"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  _updateRequestStatus(context, 'Rejected', feedback);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide a rejection reason.')),
                  );
                }
              },
              child: Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  void _updateRequestStatus(BuildContext context, String newStatus, [String? feedback]) {
    Map<String, dynamic> updateData = {
      'status': newStatus,
      'progress': FieldValue.arrayUnion([
        {
          'timestamp': DateTime.now().toIso8601String(),
          'role': 'MD',
          'action': newStatus == 'Approved'
              ? 'Final Approval Granted'
              : 'Request Rejected',
        },
      ]),
    };

    if (feedback != null && feedback.isNotEmpty) {
      updateData['rejectionFeedback'] = feedback;
    }

    _firestore.collection('requests').doc(requestId).update(updateData).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $newStatus successfully.')),
      );
      Navigator.pop(context);
    });
  }
}


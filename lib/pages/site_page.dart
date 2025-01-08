import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'request_progress_page.dart';

class SitePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Site Dashboard'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('requests')
                  .where('createdBy', isEqualTo: 'Site')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No requests found."));
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['description']),
                      subtitle: Text("Status: ${data['status']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RequestProgressPage(requestId: doc.id),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _showCreateRequestDialog(context);
            },
            child: Text('Create New Request'),
          ),
        ],
      ),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Request'),
        content: TextField(
          controller: descriptionController,
          decoration: InputDecoration(hintText: 'Enter request description'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final description = descriptionController.text;
              if (description.isNotEmpty) {
                _firestore.collection('requests').add({
                  'description': description,
                  'status': 'Pending with Purchase Officer',
                  'createdBy': 'Site',
                  'assignedTo': 'PurchaseOfficer',
                  'progress': [
                    {
                      'timestamp': DateTime.now().toIso8601String(),
                      'role': 'Site',
                      'action': 'Created Request',
                    },
                  ],
                  'createdAt': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}

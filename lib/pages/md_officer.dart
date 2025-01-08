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
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['description']),
                subtitle: Text("Status: ${data['status']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _updateRequestStatus(doc.id, 'Approved');
                      },
                      child: Text('Approve'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        _updateRequestStatus(doc.id, 'Rejected');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text('Reject'),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _updateRequestStatus(String requestId, String newStatus) {
    _firestore.collection('requests').doc(requestId).update({
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
    });
  }
}

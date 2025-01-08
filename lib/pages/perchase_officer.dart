import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOfficerPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Officer Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('requests')
            .where('assignedTo', isEqualTo: 'PurchaseOfficer')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No requests assigned."));
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['description']),
                subtitle: Text("Status: ${data['status']}"),
                trailing: ElevatedButton(
                  onPressed: () {
                    _updateRequestStatus(doc.id, 'Pending with Accounts Officer');
                  },
                  child: Text('Approve'),
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
      'assignedTo': 'AccountsOfficer',
      'progress': FieldValue.arrayUnion([
        {
          'timestamp': DateTime.now().toIso8601String(),
          'role': 'PurchaseOfficer',
          'action': 'Approved Request',
        },
      ]),
    });
  }
}

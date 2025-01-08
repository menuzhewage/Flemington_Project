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
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                elevation: 2.0,
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
          );
        },
      ),
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
                ElevatedButton(
                  onPressed: () {
                    _updateRequestStatus(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Approve Request'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateRequestStatus(BuildContext context) {
    _firestore.collection('requests').doc(requestId).update({
      'status': 'Pending with Accounts Officer',
      'assignedTo': 'AccountsOfficer',
      'progress': FieldValue.arrayUnion([
        {
          'timestamp': DateTime.now().toIso8601String(),
          'role': 'PurchaseOfficer',
          'action': 'Approved Request',
        },
      ]),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request approved successfully.')),
      );
      Navigator.pop(context);
    });
  }
}

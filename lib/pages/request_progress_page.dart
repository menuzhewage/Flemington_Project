import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestProgressPage extends StatelessWidget {
  final String requestId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RequestProgressPage({required this.requestId});

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
          var progress = data['progress'] as List<dynamic>;
          return ListView(
            children: progress.map((entry) {
              return ListTile(
                title: Text(entry['action']),
                subtitle: Text("${entry['role']} - ${entry['timestamp']}"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

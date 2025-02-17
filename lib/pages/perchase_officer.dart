import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOfficerPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PurchaseOfficerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.blueGrey[900],
        title: const Text(
          'Purchase Officer Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        color: Colors.blueGrey[800],
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Row(
            children: [
              Container(
                width: MediaQuery.sizeOf(context).width * 0.17,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('requests')
                            .where('assignedTo', isEqualTo: 'PurchaseOfficer')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text("No requests assigned."));
                          }
                          return ListView(
                            padding: const EdgeInsets.all(8.0),
                            children: snapshot.data!.docs.map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              return RequestCard(
                                description: data['description'],
                                status: data['status'],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RequestDetailsPage(requestId: doc.id),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final String description;
  final String status;
  final VoidCallback onTap;

  const RequestCard({
    required this.description,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey[700],
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: ListTile(
        title: Text(
          description,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          "Status: $status",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
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
    return Container(
      color: Colors.blueGrey[900],
      child: Scaffold(
        backgroundColor: Colors.blueGrey[900],
        appBar: AppBar(
          title: const Text(
            'Request Details',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blueGrey[800],
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('requests').doc(requestId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Request not found."));
            }
      
            var data = snapshot.data!.data() as Map<String, dynamic>;
            var progress = data['progress'] as List<dynamic>?;
      
            return Container(
              color: Colors.blueGrey[700],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Description: ${data['description']}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Quantity: ${data['quantity']} ${data['unit']}",
                      style: const TextStyle(fontSize: 16, color: Colors.white,),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Status: ${data['status']}",
                      style: const TextStyle(fontSize: 16, color: Colors.white,),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Progress Timeline",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: progress != null && progress.isNotEmpty
                          ? ListView.separated(
                              itemCount: progress.length,
                              separatorBuilder: (context, index) => const Divider(),
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
                          : const Center(child: Text("No progress available.")),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateRequestStatus(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Approve Request'),
                        ),
                        ElevatedButton(
                          onPressed: () => _showRejectDialog(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Reject Request'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(
            labelText: 'Enter rejection feedback',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _rejectRequest(context, feedbackController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(BuildContext context, String feedback) {
    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback cannot be empty.')),
      );
      return;
    }

    _firestore.collection('requests').doc(requestId).update({
      'status': 'Rejected',
      'assignedTo': 'None',
      'feedback': feedback,
      'progress': FieldValue.arrayUnion([
        {
          'timestamp': DateTime.now().toIso8601String(),
          'role': 'PurchaseOfficer',
          'action': 'Rejected Request',
          'feedback': feedback,
        },
      ]),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected successfully.')),
      );
      Navigator.pop(context);
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: $error')),
      );
    });
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
        const SnackBar(content: Text('Request approved successfully.')),
      );
      Navigator.pop(context);
    });
  }
}

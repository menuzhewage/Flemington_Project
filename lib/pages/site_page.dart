import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'request_progress_page.dart';

class SitePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Site Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        elevation: 4,
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
                        stream: _firestore.collection('requests').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading data'));
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                                child: Text('No requests available'));
                          }

                          final requests = snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            data['id'] = doc.id;
                            return data;
                          }).toList();

                          final approvedRequests = requests
                              .where((r) => r['status'] == 'Approved')
                              .toList();
                          final pendingRequests = requests
                              .where((r) =>
                                  r['status'].toString().contains('Pending'))
                              .toList();
                          final rejectedRequests = requests
                              .where((r) => r['status'] == 'Rejected')
                              .toList();

                          return ListView(
                            children: [
                              _buildSection(context, 'Approved Requests',
                                  approvedRequests),
                              _buildSection(
                                  context, 'Pending Requests', pendingRequests),
                              _buildSection(context, 'Rejected Requests',
                                  rejectedRequests),
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () => _showCreateRequestDialog(context),
                        child: const Text(
                          'Create New Request',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
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

  Widget _buildSection(
      BuildContext context, String title, List<Map<String, dynamic>> requests) {
    return Card(
      color: Colors.blueGrey[700],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ExpansionTile(
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        children: requests.map((request) {
          return ListTile(
            title: Text(request['description'],
                style: const TextStyle(color: Colors.white)),
            subtitle: Text('Status: ${request['status']}',
                style: const TextStyle(color: Colors.white70)),
            trailing:
                const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      RequestProgressPage(requestId: request['id'])),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Request'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter quantity' : null,
              ),
              TextFormField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (value) => value!.isEmpty ? 'Enter unit' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _firestore.collection('requests').add({
                  'description': descriptionController.text,
                  'quantity': int.parse(quantityController.text),
                  'unit': unitController.text,
                  'status': 'Pending with Purchase Officer',
                  'createdAt': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

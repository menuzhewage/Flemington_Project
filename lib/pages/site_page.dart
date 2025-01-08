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
        title: Text('Site Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("An error occurred. Please try again."));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No requests found."));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                                builder: (context) =>
                                    RequestProgressPage(requestId: doc.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showCreateRequestDialog(context);
              },
              child: Text('Create New Request'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCreateRequestDialog(BuildContext context) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController unitController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Request'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Enter request description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter quantity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: unitController,
                decoration: InputDecoration(
                  hintText: 'Enter unit (e.g., bags, pieces)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a unit';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final description = descriptionController.text.trim();
                final quantity = int.parse(quantityController.text.trim());
                final unit = unitController.text.trim();

                _firestore.collection('requests').add({
                  'description': description,
                  'quantity': quantity,
                  'unit': unit,
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

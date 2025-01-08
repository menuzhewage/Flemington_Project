import 'package:cloud_firestore/cloud_firestore.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createRequest(String description, String siteId) async {
    await _firestore.collection('requests').add({
      'description': description,
      'status': 'Pending with Purchase Officer',
      'assignedTo': 'PurchaseOfficer',
      'createdBy': siteId,
      'createdAt': DateTime.now(),
    });
  }

  Future<void> updateRequest(String requestId, String status, String assignedTo) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': status,
      'assignedTo': assignedTo,
    });
  }

  Stream<List<Map<String, dynamic>>> getRequestsForRole(String role) {
    return _firestore
        .collection('requests')
        .where('assignedTo', isEqualTo: role)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

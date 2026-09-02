import 'package:cloud_firestore/cloud_firestore.dart';

class IdManager {
  static final IdManager instance = IdManager._internal();
  IdManager._internal();

  /// ✅ Get and Increment a global counter for a specific type (e.g., 'users' or 'ads')
  Future<int> getNextId(String type) async {
    final counterRef = FirebaseFirestore.instance.collection('metadata').doc('counters');
    
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      if (!snapshot.exists) {
        // Initial setup
        transaction.set(counterRef, {type: 1});
        return 1;
      }

      final data = snapshot.data()!;
      final currentId = data[type] ?? 0;
      final nextId = currentId + 1;

      transaction.update(counterRef, {type: nextId});
      return nextId;
    });
  }
}

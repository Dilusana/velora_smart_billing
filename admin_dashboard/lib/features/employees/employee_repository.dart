import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class EmployeeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _employees => _db.collection('employees');
  CollectionReference get _users => _db.collection('users');

  /// Real-time stream of all employees from Firestore
  Stream<List<EmployeeModel>> getEmployees() {
    return _employees.snapshots().asyncMap((snap) async {
      var docs = snap.docs;
      if (docs.isEmpty) {
        try {
          final usersSnap = await _users.get();
          if (usersSnap.docs.isNotEmpty) {
            docs = usersSnap.docs;
          }
        } catch (_) {}
      }
      return docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmployeeModel.fromMap(data);
      }).toList();
    });
  }

  /// Add a new employee to Firestore
  Future<void> addEmployee(EmployeeModel employee) async {
    final ref = _employees.doc(employee.id.isNotEmpty ? employee.id : null);
    final data = employee.copyWith(id: ref.id).toMap();
    await ref.set(data);

    try {
      await _users.doc(ref.id).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Update an existing employee in Firestore
  Future<void> updateEmployee(EmployeeModel employee) async {
    await _employees.doc(employee.id).set(employee.toMap(), SetOptions(merge: true));
    try {
      await _users.doc(employee.id).set(employee.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  /// Delete an employee from Firestore
  Future<void> deleteEmployee(String id) async {
    await _employees.doc(id).delete();
    try {
      await _users.doc(id).delete();
    } catch (_) {}
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/data/models.dart';

class EmployeeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _employee => _db.collection('employee');
  CollectionReference get _employees => _db.collection('employees');
  CollectionReference get _users => _db.collection('users');

  /// Real-time stream of all employees from Firestore (checks 'employee', 'employees', and 'users')
  Stream<List<EmployeeModel>> getEmployees() {
    return _employee.snapshots().asyncMap((empSnap) async {
      List<DocumentSnapshot> allDocs = List.from(empSnap.docs);

      try {
        final employeesSnap = await _employees.get();
        allDocs.addAll(employeesSnap.docs);
      } catch (_) {}

      if (allDocs.isEmpty) {
        try {
          final usersSnap = await _users.get();
          allDocs.addAll(usersSnap.docs);
        } catch (_) {}
      }

      final Map<String, EmployeeModel> employeeMap = {};
      for (final doc in allDocs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final model = EmployeeModel.fromMap(data, docId: doc.id);
          final key = model.id.isNotEmpty ? model.id : (model.email.isNotEmpty ? model.email : doc.id);
          if (!employeeMap.containsKey(key)) {
            employeeMap[key] = model;
          }
        }
      }
      return employeeMap.values.toList();
    });
  }

  /// Add a new employee to Firestore (syncs to both 'employee' and 'employees')
  Future<void> addEmployee(EmployeeModel employee) async {
    final docId = employee.id.isNotEmpty ? employee.id : _employee.doc().id;
    final empWithId = employee.copyWith(id: docId);
    final data = empWithId.toMap();

    await _employee.doc(docId).set(data, SetOptions(merge: true));
    try {
      await _employees.doc(docId).set(data, SetOptions(merge: true));
    } catch (_) {}
    try {
      await _users.doc(docId).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Update an existing employee in Firestore
  Future<void> updateEmployee(EmployeeModel employee) async {
    final data = employee.toMap();
    await _employee.doc(employee.id).set(data, SetOptions(merge: true));
    try {
      await _employees.doc(employee.id).set(data, SetOptions(merge: true));
    } catch (_) {}
    try {
      await _users.doc(employee.id).set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Delete an employee from Firestore
  Future<void> deleteEmployee(String id) async {
    await _employee.doc(id).delete();
    try {
      await _employees.doc(id).delete();
    } catch (_) {}
    try {
      await _users.doc(id).delete();
    } catch (_) {}
  }
}

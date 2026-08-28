import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import 'employee_repository.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

class FirestoreEmployeesNotifier extends AsyncNotifier<List<EmployeeModel>> {
  EmployeeRepository get _repo => ref.read(employeeRepositoryProvider);

  @override
  Future<List<EmployeeModel>> build() async {
    final stream = _repo.getEmployees();
    final employees = await stream.first;

    stream.listen((updated) {
      if (!state.isLoading) {
        state = AsyncData(updated);
      }
    });

    return employees;
  }

  Future<void> add(EmployeeModel employee) async {
    final current = state.value ?? [];
    state = AsyncData([...current, employee]);
    try {
      await _repo.addEmployee(employee);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    final current = state.value ?? [];
    state = AsyncData([
      for (final e in current) if (e.id == employee.id) employee else e,
    ]);
    try {
      await _repo.updateEmployee(employee);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final current = state.value ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());
    try {
      await _repo.deleteEmployee(id);
    } catch (e) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final firestoreEmployeesProvider =
    AsyncNotifierProvider<FirestoreEmployeesNotifier, List<EmployeeModel>>(
  FirestoreEmployeesNotifier.new,
);

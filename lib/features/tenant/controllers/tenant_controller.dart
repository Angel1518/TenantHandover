import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tenant_repository.dart';
import '../models/tenant_models.dart';

final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) => TenantRepository(),
);

class TenantState {
  const TenantState({this.cases = const [], this.points = const []});
  final List<Expediente> cases;
  final List<PuntoInspeccion> points;
}

class TenantController extends AsyncNotifier<TenantState> {
  @override
  Future<TenantState> build() async => _loadAll();

  TenantRepository get _repo => ref.read(tenantRepositoryProvider);

  Future<TenantState> _loadAll() async => TenantState(
        cases: await _repo.listCases(),
        points: await _repo.listPoints(),
      );

  Future<Expediente> createCase({
    required String propertyName,
    String tenantName = '',
    String landlordName = '',
  }) async {
    final now = DateTime.now();
    final id = 'case_${now.microsecondsSinceEpoch}';
    final exp = Expediente(
      id: id,
      propertyName: propertyName.trim(),
      tenantName: tenantName.trim(),
      landlordName: landlordName.trim(),
      createdAt: now,
    );

    final starter = [
      PuntoInspeccion(
          id: '${id}_1',
          caseId: id,
          roomName: 'Salón',
          elementName: 'Paredes y suelo'),
      PuntoInspeccion(
          id: '${id}_2',
          caseId: id,
          roomName: 'Cocina',
          elementName: 'Electrodomésticos y grifería'),
      PuntoInspeccion(
          id: '${id}_3',
          caseId: id,
          roomName: 'Baño',
          elementName: 'Sanitarios y mampara'),
      PuntoInspeccion(
          id: '${id}_4',
          caseId: id,
          roomName: 'Entrada',
          elementName: 'Llaves y contadores'),
    ];

    await _repo.saveCaseWithPoints(expediente: exp, points: starter);
    state = AsyncData(await _loadAll());
    return exp;
  }

  Future<void> updatePoint(PuntoInspeccion pt) async {
    await _repo.upsertPoint(pt);
    state = AsyncData(await _loadAll());
  }
}

final tenantControllerProvider =
    AsyncNotifierProvider<TenantController, TenantState>(TenantController.new);


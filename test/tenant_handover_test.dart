import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tenant_handover/core/theme/app_theme.dart';
import 'package:tenant_handover/features/tenant/controllers/tenant_controller.dart';
import 'package:tenant_handover/features/tenant/data/tenant_repository.dart';
import 'package:tenant_handover/features/tenant/models/tenant_models.dart';
import 'package:tenant_handover/features/tenant/services/tenant_exporter.dart';
import 'package:tenant_handover/features/tenant/ui/cases_screen.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  test('TenantExporter detects changes and builds PDF + ZIP with manifest', () async {
    final exp = Expediente(
      id: 'c1',
      propertyName: 'Piso Sol 4B',
      tenantName: 'Ana',
      landlordName: 'Luis',
      createdAt: DateTime(2026, 11, 17),
    );
    const pts = [
      PuntoInspeccion(
        id: 'p1',
        caseId: 'c1',
        roomName: 'Salón',
        elementName: 'Pared',
        entryState: ConditionRating.bueno,
        exitState: ConditionRating.incidencia,
        exitNote: 'Marca de cuadro',
      ),
    ];

    expect(pts.first.hasChanged, isTrue);
    final zip = TenantExporter.buildZipBundle(expediente: exp, points: pts);
    final decoded = ZipDecoder().decodeBytes(zip);
    expect(
      decoded.files.map((f) => f.name),
      containsAll(['report.json', 'manifest.sha256']),
    );
    final pdf = await TenantExporter.buildPdf(expediente: exp, points: pts);
    expect(pdf.length, greaterThan(400));
  });

  testWidgets('CasesScreen renders without overflow at 320px and 200% TextScaler', (tester) async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: TenantRepository.createSchema,
    );
    final repo = TenantRepository(testDb: db);
    await repo.saveCaseWithPoints(
      expediente: Expediente(
        id: 'c_long',
        propertyName: 'Vivienda_${'T' * 100}',
        createdAt: DateTime(2026, 11, 17),
      ),
      points: const [],
    );

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tenantRepositoryProvider.overrideWithValue(repo)],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: AppTheme.light(accent: const Color(0xFF0F766E)),
            home: const CasesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
    await db.close();
  });
}


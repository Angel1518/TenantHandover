import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/tenant_controller.dart';
import '../models/tenant_models.dart';
import '../services/tenant_exporter.dart';

class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({super.key, required this.caseId});
  final String caseId;

  Future<void> _export({
    required BuildContext context,
    required Expediente exp,
    required List<PuntoInspeccion> points,
    required bool asPdf,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(
        dir.path,
        asPdf ? 'acta_${exp.id}.pdf' : 'acta_${exp.id}.zip',
      ));
      final bytes = asPdf
          ? await TenantExporter.buildPdf(expediente: exp, points: points)
          : TenantExporter.buildZipBundle(expediente: exp, points: points);
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Acta ${exp.propertyName}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tenantControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inspección entrada / salida')),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final exp = data.cases.where((c) => c.id == caseId).firstOrNull;
          if (exp == null) {
            return const Center(child: Text('Expediente no encontrado.'));
          }
          final points =
              data.points.where((p) => p.caseId == exp.id).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(exp.propertyName, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _export(
                        context: context,
                        exp: exp,
                        points: points,
                        asPdf: true),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _export(
                        context: context,
                        exp: exp,
                        points: points,
                        asPdf: false),
                    icon: const Icon(Icons.folder_zip_outlined),
                    label: const Text('ZIP + SHA-256'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...points.map((pt) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${pt.roomName} · ${pt.elementName}',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                if (pt.hasChanged)
                                  Chip(
                                    label: const Text('Cambió'),
                                    backgroundColor: theme
                                        .colorScheme.errorContainer
                                        .withValues(alpha: 0.6),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                DropdownButton<ConditionRating>(
                                  value: pt.entryState,
                                  items: ConditionRating.values
                                      .map((r) => DropdownMenuItem(
                                            value: r,
                                            child: Text('Entrada: ${r.label}'),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      ref
                                          .read(tenantControllerProvider
                                              .notifier)
                                          .updatePoint(
                                              pt.copyWith(entryState: v));
                                    }
                                  },
                                ),
                                DropdownButton<ConditionRating?>(
                                  value: pt.exitState,
                                  hint: const Text('Salida: sin registrar'),
                                  items: [
                                    const DropdownMenuItem<ConditionRating?>(
                                      value: null,
                                      child: Text('Salida: sin registrar'),
                                    ),
                                    ...ConditionRating.values.map(
                                      (r) => DropdownMenuItem<ConditionRating?>(
                                        value: r,
                                        child: Text('Salida: ${r.label}'),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) {
                                      ref
                                          .read(tenantControllerProvider
                                              .notifier)
                                          .updatePoint(
                                              pt.copyWith(exitState: v));
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}


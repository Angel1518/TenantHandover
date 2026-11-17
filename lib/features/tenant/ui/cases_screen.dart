import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/tenant_controller.dart';

class CasesScreen extends ConsumerWidget {
  const CasesScreen({super.key});

  Future<void> _newCaseDialog(BuildContext context, WidgetRef ref) async {
    final propCtrl = TextEditingController();
    final tenantCtrl = TextEditingController();
    final landlordCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo expediente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: propCtrl,
                  decoration: const InputDecoration(labelText: 'Vivienda')),
              const SizedBox(height: 10),
              TextField(
                  controller: tenantCtrl,
                  decoration: const InputDecoration(labelText: 'Inquilino')),
              const SizedBox(height: 10),
              TextField(
                  controller: landlordCtrl,
                  decoration: const InputDecoration(labelText: 'Arrendador')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Crear acta')),
        ],
      ),
    );
    if (ok == true && propCtrl.text.trim().isNotEmpty) {
      final exp = await ref.read(tenantControllerProvider.notifier).createCase(
            propertyName: propCtrl.text,
            tenantName: tenantCtrl.text,
            landlordName: landlordCtrl.text,
          );
      if (context.mounted) context.push('/cases/${exp.id}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(tenantControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('TenantHandover')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newCaseDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Expediente'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  'Lo que había, cómo estaba y qué cambió',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (data.cases.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fact_check_outlined,
                            size: 52, color: theme.colorScheme.primary),
                        const SizedBox(height: 12),
                        Text('Sin actas de entrega todavía',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text(
                          'Documenta el estado de entrada y salida por estancias y exporta PDF + ZIP verificable con SHA-256.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 92),
                sliver: SliverList.separated(
                  itemCount: data.cases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final c = data.cases[i];
                    final pts =
                        data.points.where((p) => p.caseId == c.id).toList();
                    final changed = pts.where((p) => p.hasChanged).length;
                    return TweenAnimationBuilder<double>(
                      duration: AppMotion.duration(
                          context, Duration(milliseconds: 180 + (i.clamp(0, 6) * 35))),
                      curve: AppMotion.curve(context),
                      tween: Tween(begin: 0, end: 1),
                      builder: (ctx, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - t)),
                          child: child,
                        ),
                      ),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            child: Icon(Icons.assignment_turned_in_outlined,
                                color: theme.colorScheme.primary),
                          ),
                          title: Text(c.propertyName,
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle:
                              Text('${pts.length} puntos · $changed cambios'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/cases/${c.id}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


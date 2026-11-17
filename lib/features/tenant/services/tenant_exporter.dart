import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/tenant_models.dart';

class TenantExporter {
  static Uint8List buildZipBundle({
    required Expediente expediente,
    required List<PuntoInspeccion> points,
  }) {
    final reportJson = utf8.encode(const JsonEncoder.withIndent('  ').convert({
      'schema': 'tenanthandover.v1',
      'expediente': expediente.toMap(),
      'points': points.map((p) => p.toMap()).toList(),
      'changed_count': points.where((p) => p.hasChanged).length,
    }));
    final manifest = utf8.encode(
      'report.json  sha256:${sha256.convert(reportJson)}\n',
    );
    final archive = Archive()
      ..addFile(ArchiveFile('report.json', reportJson.length, reportJson))
      ..addFile(ArchiveFile('manifest.sha256', manifest.length, manifest));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<Uint8List> buildPdf({
    required Expediente expediente,
    required List<PuntoInspeccion> points,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Acta de estado: ${expediente.propertyName}',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text:
                'Inquilino: ${expediente.tenantName} | Arrendador: ${expediente.landlordName}',
          ),
          ...points.map(
            (pt) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${pt.roomName} · ${pt.elementName}${pt.hasChanged ? " [CAMBIÓ]" : ""}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                      'Entrada: ${pt.entryState.label} ${pt.entryNote}'),
                  if (pt.exitState != null)
                    pw.Text(
                        'Salida: ${pt.exitState!.label} ${pt.exitNote}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }
}


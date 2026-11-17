enum ConditionRating { bueno, desgasteNormal, incidencia }

extension ConditionRatingX on ConditionRating {
  String get label {
    switch (this) {
      case ConditionRating.bueno:
        return 'Correcto';
      case ConditionRating.desgasteNormal:
        return 'Desgaste normal';
      case ConditionRating.incidencia:
        return 'Incidencia';
    }
  }
}

class Expediente {
  const Expediente({
    required this.id,
    required this.propertyName,
    this.tenantName = '',
    this.landlordName = '',
    required this.createdAt,
  });

  final String id;
  final String propertyName;
  final String tenantName;
  final String landlordName;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'property_name': propertyName,
        'tenant_name': tenantName,
        'landlord_name': landlordName,
        'created_at': createdAt.toIso8601String(),
      };

  factory Expediente.fromMap(Map<String, dynamic> map) => Expediente(
        id: map['id'] as String,
        propertyName: map['property_name'] as String,
        tenantName: map['tenant_name'] as String? ?? '',
        landlordName: map['landlord_name'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class PuntoInspeccion {
  const PuntoInspeccion({
    required this.id,
    required this.caseId,
    required this.roomName,
    required this.elementName,
    this.entryState = ConditionRating.bueno,
    this.entryNote = '',
    this.exitState,
    this.exitNote = '',
  });

  final String id;
  final String caseId;
  final String roomName;
  final String elementName;
  final ConditionRating entryState;
  final String entryNote;
  final ConditionRating? exitState;
  final String exitNote;

  bool get hasChanged => exitState != null && exitState != entryState;

  PuntoInspeccion copyWith({
    ConditionRating? entryState,
    String? entryNote,
    ConditionRating? exitState,
    String? exitNote,
  }) =>
      PuntoInspeccion(
        id: id,
        caseId: caseId,
        roomName: roomName,
        elementName: elementName,
        entryState: entryState ?? this.entryState,
        entryNote: entryNote ?? this.entryNote,
        exitState: exitState ?? this.exitState,
        exitNote: exitNote ?? this.exitNote,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'case_id': caseId,
        'room_name': roomName,
        'element_name': elementName,
        'entry_state': entryState.name,
        'entry_note': entryNote,
        'exit_state': exitState?.name,
        'exit_note': exitNote,
      };

  factory PuntoInspeccion.fromMap(Map<String, dynamic> map) => PuntoInspeccion(
        id: map['id'] as String,
        caseId: map['case_id'] as String,
        roomName: map['room_name'] as String,
        elementName: map['element_name'] as String,
        entryState: ConditionRating.values.firstWhere(
          (e) => e.name == (map['entry_state'] as String? ?? 'bueno'),
          orElse: () => ConditionRating.bueno,
        ),
        entryNote: map['entry_note'] as String? ?? '',
        exitState: map['exit_state'] != null
            ? ConditionRating.values.firstWhere(
                (e) => e.name == map['exit_state'],
                orElse: () => ConditionRating.bueno,
              )
            : null,
        exitNote: map['exit_note'] as String? ?? '',
      );
}


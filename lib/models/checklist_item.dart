class ChecklistItem {
  final int id;
  final String text;
  final String status; // 'compliant', 'non-compliant'

  ChecklistItem({
    required this.id,
    required this.text,
    required this.status,
  });

  bool get isCompliant => status == 'compliant';

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      text: json['text'],
      status: json['status'],
    );
  }

  static List<ChecklistItem> getSampleData() {
    return [
      ChecklistItem(
        id: 1,
        text: "El empleador proporciona recursos necesarios",
        status: "compliant",
      ),
      ChecklistItem(
        id: 2,
        text: "Se realizan reuniones del comité de SST",
        status: "compliant",
      ),
      ChecklistItem(
        id: 3,
        text: "Existe liderazgo visible en seguridad",
        status: "non-compliant",
      ),
      ChecklistItem(
        id: 4,
        text: "Se consulta a trabajadores sobre SST",
        status: "compliant",
      ),
      ChecklistItem(
        id: 5,
        text: "Hay participación activa de trabajadores",
        status: "non-compliant",
      ),
      ChecklistItem(
        id: 6,
        text: "Se investigan accidentes e incidentes",
        status: "non-compliant",
      ),
      ChecklistItem(
        id: 7,
        text: "Existe programa anual de capacitación",
        status: "non-compliant",
      ),
      ChecklistItem(
        id: 8,
        text: "Se realizan auditorías internas",
        status: "non-compliant",
      ),
    ];
  }
}

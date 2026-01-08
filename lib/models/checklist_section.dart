class ChecklistSection {
  final int id;
  final String title;
  final int itemsCompleted;
  final int itemsTotal;
  final int percentage;
  final String status; // deficiente | aprobado | pendiente
  final int? moduleId;

  const ChecklistSection({
    required this.id,
    required this.title,
    required this.itemsCompleted,
    required this.itemsTotal,
    required this.percentage,
    required this.status,
    this.moduleId,
  });

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    return ChecklistSection(
      id: json['id'],
      title: json['title'],
      itemsCompleted: json['items_completed'],
      itemsTotal: json['items_total'],
      percentage: json['percentage'],
      status: json['status'],
      moduleId: json['checklist_module_id'],
    );
  }

  static List<ChecklistSection> getSampleData() {
    return [
      ChecklistSection(
        id: 1,
        title: 'Liderazgo y compromiso',
        itemsCompleted: 2,
        itemsTotal: 6,
        percentage: 33,
        status: 'deficiente',
      ),
      ChecklistSection(
        id: 2,
        title: 'Participacion de trabajadores',
        itemsCompleted: 3,
        itemsTotal: 6,
        percentage: 50,
        status: 'deficiente',
      ),
      ChecklistSection(
        id: 3,
        title: 'Investigacion de incidentes',
        itemsCompleted: 1,
        itemsTotal: 4,
        percentage: 25,
        status: 'deficiente',
      ),
      ChecklistSection(
        id: 4,
        title: 'Capacitacion y formacion',
        itemsCompleted: 5,
        itemsTotal: 6,
        percentage: 83,
        status: 'aprobado',
      ),
      ChecklistSection(
        id: 5,
        title: 'Auditorias y mejora',
        itemsCompleted: 3,
        itemsTotal: 5,
        percentage: 60,
        status: 'pendiente',
      ),
      ChecklistSection(
        id: 6,
        title: 'Gestion documental',
        itemsCompleted: 2,
        itemsTotal: 4,
        percentage: 50,
        status: 'pendiente',
      ),
    ];
  }
}

class Lesson {
  final int id;
  final String title;
  final String duration;
  final String type;
  final String? description;
  final String? image;
  final String? thumbnailUrl;
  final String contentMode;
  final String? contentUrl;
  final String? contentMimeType;
  final int? contentSizeBytes;
  final String? externalUrl;
  final int displayOrder;
  final bool completed;

  const Lesson({
    required this.id,
    required this.title,
    required this.duration,
    required this.type,
    required this.description,
    required this.image,
    required this.thumbnailUrl,
    required this.contentMode,
    required this.contentUrl,
    required this.contentMimeType,
    required this.contentSizeBytes,
    required this.externalUrl,
    required this.displayOrder,
    required this.completed,
  });

  String? get coverUrl => thumbnailUrl ?? image;
  String? get primaryLink =>
      contentMode == 'external_url' ? externalUrl : contentUrl;
  bool get hasContent => (primaryLink ?? '').trim().isNotEmpty;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      duration: json['duration'],
      type: json['type'],
      description: json['description'],
      image: json['image'],
      thumbnailUrl: json['thumbnail_url'],
      contentMode: json['content_mode'] ?? 'upload',
      contentUrl: json['content_url'],
      contentMimeType: json['content_mime_type'],
      contentSizeBytes: json['content_size_bytes'],
      externalUrl: json['external_url'],
      displayOrder: json['display_order'] ?? 1,
      completed: json['completed'] ?? false,
    );
  }

  static List<Lesson> getSampleData() {
    return [
      Lesson(
        id: 1,
        title: 'Introduccion al liderazgo en SST',
        duration: '8 min',
        type: 'video',
        description:
            'Contenido base de liderazgo visible y cultura preventiva.',
        image: 'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a',
        contentMode: 'external_url',
        contentUrl: null,
        contentMimeType: null,
        contentSizeBytes: null,
        externalUrl: 'https://example.com/video',
        displayOrder: 1,
        completed: true,
      ),
      Lesson(
        id: 2,
        title: 'Comunicacion efectiva y roles',
        duration: '12 min',
        type: 'document',
        description: 'Documento de lectura sobre roles y responsabilidades.',
        image: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1498050108023-c5249f4df085',
        contentMode: 'external_url',
        contentUrl: null,
        contentMimeType: 'application/pdf',
        contentSizeBytes: null,
        externalUrl: 'https://example.com/manual.pdf',
        displayOrder: 2,
        completed: false,
      ),
      Lesson(
        id: 3,
        title: 'Participacion de trabajadores',
        duration: '10 min',
        type: 'interactive',
        description: 'Leccion de participacion y consulta interna.',
        image: 'https://images.unsplash.com/photo-1556761175-4b46a572b786',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1556761175-4b46a572b786',
        contentMode: 'external_url',
        contentUrl: null,
        contentMimeType: null,
        contentSizeBytes: null,
        externalUrl: 'https://example.com/interactive',
        displayOrder: 3,
        completed: false,
      ),
      Lesson(
        id: 4,
        title: 'Plan de accion y seguimiento',
        duration: '9 min',
        type: 'video',
        description: 'Seguimiento operativo y evidencias de cierre.',
        image: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1497366754035-f200968a6e72',
        contentMode: 'external_url',
        contentUrl: null,
        contentMimeType: null,
        contentSizeBytes: null,
        externalUrl: 'https://example.com/video-2',
        displayOrder: 4,
        completed: false,
      ),
    ];
  }
}

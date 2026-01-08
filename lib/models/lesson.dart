class Lesson {
  final int id;
  final String title;
  final String duration;
  final String type; // video | document | interactive
  final String? image;
  final bool completed;

  const Lesson({
    required this.id,
    required this.title,
    required this.duration,
    required this.type,
    required this.image,
    required this.completed,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'],
      title: json['title'],
      duration: json['duration'],
      type: json['type'],
      image: json['image'],
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
        image: 'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a',
        completed: true,
      ),
      Lesson(
        id: 2,
        title: 'Comunicacion efectiva y roles',
        duration: '12 min',
        type: 'document',
        image: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085',
        completed: false,
      ),
      Lesson(
        id: 3,
        title: 'Participacion de trabajadores',
        duration: '10 min',
        type: 'interactive',
        image: 'https://images.unsplash.com/photo-1556761175-4b46a572b786',
        completed: false,
      ),
      Lesson(
        id: 4,
        title: 'Plan de accion y seguimiento',
        duration: '9 min',
        type: 'video',
        image: 'https://images.unsplash.com/photo-1497366754035-f200968a6e72',
        completed: false,
      ),
    ];
  }
}

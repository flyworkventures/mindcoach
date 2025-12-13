class SpecialistItem {
  final String name;
  final String title;
  final String description;
  final String avatarPath;

  SpecialistItem({
    required this.name,
    required this.title,
    required this.description,
    required this.avatarPath,
  });




  factory SpecialistItem.fromJson(Map<String, dynamic> json) {
    return SpecialistItem(
      name: json['name'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      avatarPath: json['avatarPath'] as String,
    );
  }
}
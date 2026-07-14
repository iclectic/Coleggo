class Worksite {
  const Worksite({required this.id, required this.name, required this.area});

  final String id;
  final String name;
  final String area;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'area': area};

  factory Worksite.fromJson(Map<String, dynamic> json) => Worksite(
    id: json['id'] as String,
    name: json['name'] as String,
    area: json['area'] as String,
  );
}

class Workplace {
  const Workplace({
    required this.id,
    required this.name,
    required this.industry,
    required this.worksites,
  });

  final String id;
  final String name;
  final String industry;
  final List<Worksite> worksites;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'industry': industry,
    'worksites': worksites.map((site) => site.toJson()).toList(),
  };

  factory Workplace.fromJson(Map<String, dynamic> json) => Workplace(
    id: json['id'] as String,
    name: json['name'] as String,
    industry: json['industry'] as String,
    worksites: (json['worksites'] as List<dynamic>)
        .map((site) => Worksite.fromJson(site as Map<String, dynamic>))
        .toList(),
  );
}

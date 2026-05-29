class ProvinceModel {
  final int code;
  final String name;
  final String codename;

  const ProvinceModel({
    required this.code,
    required this.name,
    required this.codename,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      code: json['code'] ?? 0,
      name: json['name'] ?? '',
      codename: json['codename'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'codename': codename,
      };
}

class DistrictModel {
  final int code;
  final String name;
  final String codename;

  const DistrictModel({
    required this.code,
    required this.name,
    required this.codename,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      code: json['code'] ?? 0,
      name: json['name'] ?? '',
      codename: json['codename'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'codename': codename,
      };
}

class WardModel {
  final int code;
  final String name;
  final String codename;

  const WardModel({
    required this.code,
    required this.name,
    required this.codename,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      code: json['code'] ?? 0,
      name: json['name'] ?? '',
      codename: json['codename'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'codename': codename,
      };
}

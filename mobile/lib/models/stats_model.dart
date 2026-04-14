class StatsOverview {
  final int totalUsers;
  final int totalTransactions;
  final int batteriesListed;
  final int vehiclesListed;

  const StatsOverview({
    required this.totalUsers,
    required this.totalTransactions,
    required this.batteriesListed,
    required this.vehiclesListed,
  });

  factory StatsOverview.fromJson(Map<String, dynamic> json) => StatsOverview(
        totalUsers: json['totalUsers'] ?? 0,
        totalTransactions: json['totalTransactions'] ?? 0,
        batteriesListed: json['batteriesListed'] ?? 0,
        vehiclesListed: json['vehiclesListed'] ?? 0,
      );
}

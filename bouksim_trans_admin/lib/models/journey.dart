import 'charge.dart';

class Journey {
  final String company;
  final String startCity;
  final String endCity;
  final List<Charge> charges;
  final double payment;
  final DateTime date;
  final String userId;
  final String plateNumber;
  final String cargoType;
  final double cargoWeight;
  final String bonDeLivraison;

  Journey({
    required this.company,
    required this.startCity,
    required this.endCity,
    required this.charges,
    required this.payment,
    required this.date,
    required this.userId,
    required this.plateNumber,
    required this.cargoType,
    required this.cargoWeight,
    this.bonDeLivraison = '',
  });

  // Add this factory constructor for Firebase data
  factory Journey.fromFirebase(Map<String, dynamic> data, String userId) {
    // Parse charges list
    final chargesList = List<Charge>.from(
      (data['charges'] as List<dynamic>? ?? []).map((chargeData) {
        final chargeMap = Map<String, dynamic>.from(chargeData);
        return Charge(
          name: chargeMap['name'] ?? '',
          amount: (chargeMap['amount'] ?? 0).toDouble(),
        );
      }),
    );

    // Parse date - handle both Timestamp and milliseconds
    DateTime parseDate(dynamic dateData) {
      if (dateData is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateData);
      } else {
        return DateTime.now(); // Fallback
      }
    }

    return Journey(
      company: data['company'] ?? '',
      startCity: data['startCity'] ?? '',
      endCity: data['endCity'] ?? '',
      charges: chargesList,
      payment: (data['payment'] ?? 0).toDouble(),
      date: parseDate(data['date']),
      userId: userId,
      plateNumber: data['plateNumber'] ?? '',
      cargoType: data['cargoType'] ?? '',
      cargoWeight: (data['cargoWeight'] ?? 0).toDouble(),
      bonDeLivraison: data['bonDeLivraison'] ?? '',
    );
  }

  double get totalCharges => charges.fold(0.0, (sum, charge) => sum + charge.amount);
  double get netProfit => payment - totalCharges;
}
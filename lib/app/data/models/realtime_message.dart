import 'package:equatable/equatable.dart';

class RealtimeMessage extends Equatable {
  const RealtimeMessage({
    required this.id,
    required this.type,
    required this.payload,
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;

  @override
  List<Object> get props => [id, type, payload];
}

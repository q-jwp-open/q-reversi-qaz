import 'package:equatable/equatable.dart';
import 'piece_type.dart';
import 'position.dart';

/// 駒
class Piece extends Equatable {
  final String id;
  final PieceType type;
  final Position position;
  final String? entangledPairId;
  
  const Piece({
    required this.id,
    required this.type,
    required this.position,
    this.entangledPairId,
  });
  
  Piece copyWith({
    String? id,
    PieceType? type,
    Position? position,
    String? entangledPairId,
  }) {
    return Piece(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      entangledPairId: entangledPairId ?? this.entangledPairId,
    );
  }
  
  bool get isEntangled => entangledPairId != null;
  
  @override
  List<Object?> get props => [id, type, position, entangledPairId];
}


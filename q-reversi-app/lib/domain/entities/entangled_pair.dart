import 'package:equatable/equatable.dart';
import 'position.dart';

/// エンタングルペア
class EntangledPair extends Equatable {
  final String id;
  final Position position1;
  final Position position2;
  
  const EntangledPair({
    required this.id,
    required this.position1,
    required this.position2,
  });
  
  /// 指定位置がこのペアに含まれるか
  bool contains(Position position) {
    return position == position1 || position == position2;
  }
  
  /// もう一方の位置を取得
  Position getOtherPosition(Position position) {
    if (position == position1) return position2;
    if (position == position2) return position1;
    throw ArgumentError('Position is not in this pair');
  }
  
  @override
  List<Object?> get props => [id, position1, position2];
}


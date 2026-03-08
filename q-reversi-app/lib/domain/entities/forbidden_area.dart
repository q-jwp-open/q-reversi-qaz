import 'package:equatable/equatable.dart';
import 'position.dart';

/// 禁止領域の種類
enum ForbiddenAreaType {
  row,      // 行
  column,   // 列
  fourPieces, // 4マス
}

/// 禁止領域
class ForbiddenArea extends Equatable {
  final ForbiddenAreaType type;
  final int? row;        // 行選択の場合
  final int? column;     // 列選択の場合
  final List<Position>? positions; // 4マス選択の場合
  
  const ForbiddenArea({
    required this.type,
    this.row,
    this.column,
    this.positions,
  });
  
  /// 行の禁止領域を作成
  factory ForbiddenArea.row(int row) {
    return ForbiddenArea(type: ForbiddenAreaType.row, row: row);
  }
  
  /// 列の禁止領域を作成
  factory ForbiddenArea.column(int column) {
    return ForbiddenArea(type: ForbiddenAreaType.column, column: column);
  }
  
  /// 4マスの禁止領域を作成
  factory ForbiddenArea.fourPieces(List<Position> positions) {
    return ForbiddenArea(
      type: ForbiddenAreaType.fourPieces,
      positions: List.unmodifiable(positions),
    );
  }
  
  /// 指定位置が禁止領域に含まれるか
  bool contains(Position position) {
    switch (type) {
      case ForbiddenAreaType.row:
        return position.row == row;
      case ForbiddenAreaType.column:
        return position.col == column;
      case ForbiddenAreaType.fourPieces:
        return positions?.any((p) => p == position) ?? false;
    }
  }
  
  /// 4マス選択が禁止されているか（完全一致のみ）
  bool isFourPiecesForbidden(List<Position> targetPositions) {
    if (type != ForbiddenAreaType.fourPieces || positions == null) {
      return false;
    }
    if (targetPositions.length != positions!.length) {
      return false;
    }
    // 完全一致チェック
    final sortedTarget = List<Position>.from(targetPositions)..sort((a, b) {
      if (a.row != b.row) return a.row.compareTo(b.row);
      return a.col.compareTo(b.col);
    });
    final sortedForbidden = List<Position>.from(positions!)..sort((a, b) {
      if (a.row != b.row) return a.row.compareTo(b.row);
      return a.col.compareTo(b.col);
    });
    for (int i = 0; i < sortedTarget.length; i++) {
      if (sortedTarget[i] != sortedForbidden[i]) {
        return false;
      }
    }
    return true;
  }
  
  @override
  List<Object?> get props => [type, row, column, positions];
}


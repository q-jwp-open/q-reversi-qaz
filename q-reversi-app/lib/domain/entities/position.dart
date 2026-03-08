import 'dart:math';

/// 盤面上の位置
class Position {
  final int row;
  final int col;
  
  const Position(this.row, this.col);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;
  
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
  
  @override
  String toString() => '($row, $col)';
  
  /// 2つの位置が隣接しているか（縦横斜め）
  bool isAdjacent(Position other) {
    final rowDiff = (row - other.row).abs();
    final colDiff = (col - other.col).abs();
    return rowDiff <= 1 && colDiff <= 1 && !(rowDiff == 0 && colDiff == 0);
  }
  
  /// 中央からの距離
  double distanceFromCenter(int boardSize) {
    final center = boardSize / 2.0;
    final rowDist = (row - center).abs();
    final colDist = (col - center).abs();
    return sqrt(rowDist * rowDist + colDist * colDist);
  }
}


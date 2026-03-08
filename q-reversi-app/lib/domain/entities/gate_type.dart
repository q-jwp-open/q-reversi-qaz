/// 量子ゲートの種類
enum GateType {
  h,      // Hゲート
  x,      // Xゲート
  y,      // Yゲート
  z,      // Zゲート
  cnot,   // CNOTゲート
  swap,   // SWAPゲート
}

extension GateTypeExtension on GateType {
  /// 表示名
  String get displayName {
    switch (this) {
      case GateType.h:
        return 'H';
      case GateType.x:
        return 'X';
      case GateType.y:
        return 'Y';
      case GateType.z:
        return 'Z';
      case GateType.cnot:
        return 'CNOT';
      case GateType.swap:
        return 'SWAP';
    }
  }
  
  /// 1ビットゲートかどうか
  bool get isOneBitGate {
    return this == GateType.h ||
           this == GateType.x ||
           this == GateType.y ||
           this == GateType.z;
  }
  
  /// 2ビットゲートかどうか
  bool get isTwoBitGate {
    return this == GateType.cnot || this == GateType.swap;
  }
  
  /// クールタイム
  int get cooldown {
    switch (this) {
      case GateType.h:
        return 2;
      case GateType.x:
      case GateType.y:
        return 6;
      case GateType.z:
        return 0;
      case GateType.cnot:
      case GateType.swap:
        return 3;
    }
  }
  
  /// 文字列から変換
  static GateType? fromString(String str) {
    switch (str.trim().toUpperCase()) {
      case 'H':
        return GateType.h;
      case 'X':
        return GateType.x;
      case 'Y':
        return GateType.y;
      case 'Z':
        return GateType.z;
      case 'CNOT':
        return GateType.cnot;
      case 'SWAP':
        return GateType.swap;
      default:
        return null;
    }
  }
}


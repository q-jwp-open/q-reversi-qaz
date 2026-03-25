"""Type definitions for Q-Reversi.

Python equivalents of the Dart enums in q-reversi-app/lib/domain/entities/.
"""
from enum import Enum, auto


class PieceType(Enum):
    """Quantum state of a piece on the board."""
    WHITE = "W"       # |0>  classical white
    BLACK = "B"       # |1>  classical black
    GRAY_PLUS = "+"   # |+>  superposition
    GRAY_MINUS = "-"  # |->  superposition
    BLACK_WHITE = "BW"  # entangled (top=black, bottom=white)
    WHITE_BLACK = "WB"  # entangled (top=white, bottom=black)

    @property
    def is_entangled(self) -> bool:
        return self in (PieceType.BLACK_WHITE, PieceType.WHITE_BLACK)

    @property
    def is_determined(self) -> bool:
        return self in (PieceType.WHITE, PieceType.BLACK)

    @property
    def is_superposition(self) -> bool:
        return self in (PieceType.GRAY_PLUS, PieceType.GRAY_MINUS)

    @classmethod
    def from_str(cls, s: str) -> "PieceType":
        for member in cls:
            if member.value == s.strip().upper():
                return member
        raise ValueError(f"Unknown PieceType string: {s!r}")


class GateType(Enum):
    """Quantum gate types available in the game."""
    H = "H"
    X = "X"
    Y = "Y"
    Z = "Z"
    CNOT = "CNOT"
    SWAP = "SWAP"

    @property
    def is_one_bit(self) -> bool:
        return self in (GateType.H, GateType.X, GateType.Y, GateType.Z)

    @property
    def is_two_bit(self) -> bool:
        return self in (GateType.CNOT, GateType.SWAP)

    @property
    def cooldown(self) -> int:
        """Turns of cooldown after use."""
        return {
            GateType.H: 2,
            GateType.X: 6,
            GateType.Y: 6,
            GateType.Z: 0,
            GateType.CNOT: 3,
            GateType.SWAP: 3,
        }[self]


class PlayerColor(Enum):
    WHITE = "white"
    BLACK = "black"


class AIDifficulty(Enum):
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    QUANTUM = "quantum"  # New: QAZ-QR based quantum AI


class ForbiddenAreaType(Enum):
    ROW = "row"
    COLUMN = "column"
    FOUR_PIECES = "four_pieces"

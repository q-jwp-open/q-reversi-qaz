"""Q-Reversi game state data classes.

Python equivalents of the Dart entities in q-reversi-app/lib/domain/entities/.
All objects are immutable (dataclass with frozen=True or explicit copy methods).
"""
from __future__ import annotations

import copy
import random
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

from .types import (
    AIDifficulty,
    ForbiddenAreaType,
    GateType,
    PieceType,
    PlayerColor,
)

# ─────────────────────────────────────────────────────────────
# Piece
# ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Piece:
    type: PieceType
    row: int
    col: int
    entangled_pair_id: Optional[str] = None

    @property
    def is_entangled(self) -> bool:
        return self.type.is_entangled

    def copy_with(self, **kwargs) -> "Piece":
        return Piece(
            type=kwargs.get("type", self.type),
            row=kwargs.get("row", self.row),
            col=kwargs.get("col", self.col),
            entangled_pair_id=kwargs.get("entangled_pair_id", self.entangled_pair_id),
        )


# ─────────────────────────────────────────────────────────────
# Board
# ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Board:
    """8×8 immutable board.

    pieces: list[list[Optional[Piece]]], shape (rows, cols).
    """
    pieces: Tuple[Tuple[Optional[Piece], ...], ...]
    rows: int = 8
    cols: int = 8

    # ---- factories ----

    @classmethod
    def create_8x8(cls) -> "Board":
        pieces = tuple(
            tuple(None for _ in range(8)) for _ in range(8)
        )
        return cls(pieces=pieces, rows=8, cols=8)

    @classmethod
    def create_random_8x8(cls, seed: Optional[int] = None) -> "Board":
        """Create 8×8 board with 16 pieces of each type (random)."""
        rng = random.Random(seed)
        types = (
            [PieceType.WHITE] * 16
            + [PieceType.BLACK] * 16
            + [PieceType.GRAY_PLUS] * 16
            + [PieceType.GRAY_MINUS] * 16
        )
        rng.shuffle(types)
        piece_list = list(types)
        rows = []
        idx = 0
        for r in range(8):
            row = []
            for c in range(8):
                row.append(Piece(type=piece_list[idx], row=r, col=c))
                idx += 1
            rows.append(tuple(row))
        return cls(pieces=tuple(rows), rows=8, cols=8)

    # ---- accessors ----

    def get_piece(self, row: int, col: int) -> Optional[Piece]:
        if row < 0 or row >= self.rows or col < 0 or col >= self.cols:
            return None
        return self.pieces[row][col]

    def set_piece(self, row: int, col: int, piece: Optional[Piece]) -> "Board":
        new_rows = [list(r) for r in self.pieces]
        new_rows[row][col] = piece
        return Board(
            pieces=tuple(tuple(r) for r in new_rows),
            rows=self.rows,
            cols=self.cols,
        )

    def is_valid(self, row: int, col: int) -> bool:
        return 0 <= row < self.rows and 0 <= col < self.cols

    def all_pieces(self) -> List[Piece]:
        result = []
        for row in self.pieces:
            for p in row:
                if p is not None:
                    result.append(p)
        return result

    def to_numpy(self):
        """Return (rows, cols) int8 array encoding PieceType index."""
        import numpy as np
        TYPE_IDX = {
            PieceType.WHITE: 0,
            PieceType.BLACK: 1,
            PieceType.GRAY_PLUS: 2,
            PieceType.GRAY_MINUS: 3,
            PieceType.BLACK_WHITE: 4,
            PieceType.WHITE_BLACK: 5,
        }
        arr = np.full((self.rows, self.cols), -1, dtype=np.int8)
        for r in range(self.rows):
            for c in range(self.cols):
                p = self.pieces[r][c]
                if p is not None:
                    arr[r, c] = TYPE_IDX[p.type]
        return arr


# ─────────────────────────────────────────────────────────────
# ForbiddenArea
# ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class ForbiddenArea:
    type: ForbiddenAreaType
    row: Optional[int] = None
    column: Optional[int] = None
    positions: Optional[Tuple[Tuple[int, int], ...]] = None  # ((row,col), ...)

    @classmethod
    def for_row(cls, row: int) -> "ForbiddenArea":
        return cls(type=ForbiddenAreaType.ROW, row=row)

    @classmethod
    def for_column(cls, col: int) -> "ForbiddenArea":
        return cls(type=ForbiddenAreaType.COLUMN, column=col)

    @classmethod
    def for_four_pieces(cls, positions: List[Tuple[int, int]]) -> "ForbiddenArea":
        return cls(
            type=ForbiddenAreaType.FOUR_PIECES,
            positions=tuple(sorted(positions)),
        )

    def contains(self, row: int, col: int) -> bool:
        if self.type == ForbiddenAreaType.ROW:
            return row == self.row
        if self.type == ForbiddenAreaType.COLUMN:
            return col == self.column
        if self.type == ForbiddenAreaType.FOUR_PIECES and self.positions:
            return (row, col) in self.positions
        return False

    def is_four_pieces_forbidden(self, target_positions: List[Tuple[int, int]]) -> bool:
        """Exact match check for 4-cell forbidden area."""
        if self.type != ForbiddenAreaType.FOUR_PIECES or not self.positions:
            return False
        return tuple(sorted(target_positions)) == self.positions


# ─────────────────────────────────────────────────────────────
# EntangledPair
# ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class EntangledPair:
    id: str
    pos1: Tuple[int, int]  # (row, col)
    pos2: Tuple[int, int]


# ─────────────────────────────────────────────────────────────
# Player
# ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class Player:
    id: int
    color: PlayerColor
    cooldowns: Dict[GateType, int] = field(default_factory=dict)
    is_ai: bool = False
    ai_difficulty: Optional[AIDifficulty] = None

    def can_use_gate(self, gate: GateType) -> bool:
        return self.cooldowns.get(gate, 0) == 0

    def available_gates(self) -> List[GateType]:
        return [g for g in GateType if self.can_use_gate(g)]

    def use_gate(self, gate: GateType) -> "Player":
        new_cd = dict(self.cooldowns)
        new_cd[gate] = gate.cooldown
        return Player(
            id=self.id,
            color=self.color,
            cooldowns=new_cd,
            is_ai=self.is_ai,
            ai_difficulty=self.ai_difficulty,
        )

    def decrease_cooldowns(self) -> "Player":
        new_cd = {g: max(0, v - 1) for g, v in self.cooldowns.items() if v > 0}
        return Player(
            id=self.id,
            color=self.color,
            cooldowns=new_cd,
            is_ai=self.is_ai,
            ai_difficulty=self.ai_difficulty,
        )

    def copy_with(self, **kwargs) -> "Player":
        return Player(
            id=kwargs.get("id", self.id),
            color=kwargs.get("color", self.color),
            cooldowns=kwargs.get("cooldowns", dict(self.cooldowns)),
            is_ai=kwargs.get("is_ai", self.is_ai),
            ai_difficulty=kwargs.get("ai_difficulty", self.ai_difficulty),
        )


# ─────────────────────────────────────────────────────────────
# GameState
# ─────────────────────────────────────────────────────────────

@dataclass(frozen=True)
class GameState:
    """Complete game state, immutable."""
    board: Board
    current_player: int  # 1 or 2
    turn_count: int
    max_turns: int
    players: Dict[int, Player]
    # key=player_id -> list of ForbiddenArea (valid for their NEXT turn)
    forbidden_areas: Dict[int, List[ForbiddenArea]] = field(default_factory=dict)
    entangled_pairs: List[EntangledPair] = field(default_factory=list)
    # key=player_id -> [(row,col), ...] positions of last 2-bit gate (for opponent)
    last_two_bit_positions: Dict[int, List[Tuple[int, int]]] = field(default_factory=dict)

    @classmethod
    def create_initial(
        cls,
        player1_color: PlayerColor = PlayerColor.WHITE,
        player2_is_ai: bool = True,
        ai_difficulty: AIDifficulty = AIDifficulty.ADVANCED,
        max_turns: int = 20,
        seed: Optional[int] = None,
    ) -> "GameState":
        board = Board.create_random_8x8(seed=seed)
        p1 = Player(id=1, color=player1_color, is_ai=False)
        p2_color = PlayerColor.BLACK if player1_color == PlayerColor.WHITE else PlayerColor.WHITE
        p2 = Player(id=2, color=p2_color, is_ai=player2_is_ai, ai_difficulty=ai_difficulty)
        return cls(
            board=board,
            current_player=1,
            turn_count=0,
            max_turns=max_turns,
            players={1: p1, 2: p2},
            forbidden_areas={1: [], 2: []},
            entangled_pairs=[],
            last_two_bit_positions={1: [], 2: []},
        )

    def get_current_player(self) -> Optional[Player]:
        return self.players.get(self.current_player)

    def get_opponent_player(self) -> Optional[Player]:
        opp_id = 2 if self.current_player == 1 else 1
        return self.players.get(opp_id)

    def get_forbidden_areas(self, player_id: int) -> List[ForbiddenArea]:
        return self.forbidden_areas.get(player_id, [])

    @property
    def is_game_over(self) -> bool:
        return self.turn_count >= self.max_turns

    @property
    def opponent_id(self) -> int:
        return 2 if self.current_player == 1 else 1

    def copy_with(self, **kwargs) -> "GameState":
        return GameState(
            board=kwargs.get("board", self.board),
            current_player=kwargs.get("current_player", self.current_player),
            turn_count=kwargs.get("turn_count", self.turn_count),
            max_turns=kwargs.get("max_turns", self.max_turns),
            players=kwargs.get("players", dict(self.players)),
            forbidden_areas=kwargs.get("forbidden_areas", {k: list(v) for k, v in self.forbidden_areas.items()}),
            entangled_pairs=kwargs.get("entangled_pairs", list(self.entangled_pairs)),
            last_two_bit_positions=kwargs.get("last_two_bit_positions", {k: list(v) for k, v in self.last_two_bit_positions.items()}),
        )

    def to_key(self) -> bytes:
        """Hashable key for caching (board + turn info)."""
        return self.board.to_numpy().tobytes() + bytes([self.current_player, self.turn_count % 256])

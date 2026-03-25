"""Gate application logic for Q-Reversi.

Ported from q-reversi-app/lib/domain/services/gate_service.dart.
All transformation rules are faithfully replicated.
"""
from __future__ import annotations

import uuid
from typing import List, Optional, Tuple

from .types import GateType, PieceType, PlayerColor, ForbiddenAreaType
from .game_state import (
    Board,
    EntangledPair,
    ForbiddenArea,
    GameState,
    Piece,
    Player,
)


# ─────────────────────────────────────────────────────────────
# 1-bit gate piece transformations
# ─────────────────────────────────────────────────────────────

def apply_one_bit_to_piece(piece_type: PieceType, gate: GateType) -> PieceType:
    """Apply a 1-bit gate to a single piece type. Player color not needed
    for H/X/Y/Z — the VS-mode CNOT inversion is handled separately."""
    if gate == GateType.X:
        # X: white <-> black
        if piece_type == PieceType.WHITE:
            return PieceType.BLACK
        if piece_type == PieceType.BLACK:
            return PieceType.WHITE
        return piece_type

    if gate == GateType.H:
        # H: gray+ <-> white,  gray- <-> black
        if piece_type == PieceType.GRAY_PLUS:
            return PieceType.WHITE
        if piece_type == PieceType.WHITE:
            return PieceType.GRAY_PLUS
        if piece_type == PieceType.GRAY_MINUS:
            return PieceType.BLACK
        if piece_type == PieceType.BLACK:
            return PieceType.GRAY_MINUS
        return piece_type

    if gate == GateType.Y:
        # Y: white <-> black,  gray+ <-> gray-
        if piece_type == PieceType.WHITE:
            return PieceType.BLACK
        if piece_type == PieceType.BLACK:
            return PieceType.WHITE
        if piece_type == PieceType.GRAY_PLUS:
            return PieceType.GRAY_MINUS
        if piece_type == PieceType.GRAY_MINUS:
            return PieceType.GRAY_PLUS
        return piece_type

    if gate == GateType.Z:
        # Z: gray+ <-> gray-
        if piece_type == PieceType.GRAY_PLUS:
            return PieceType.GRAY_MINUS
        if piece_type == PieceType.GRAY_MINUS:
            return PieceType.GRAY_PLUS
        return piece_type

    return piece_type


# ─────────────────────────────────────────────────────────────
# GateService
# ─────────────────────────────────────────────────────────────

class GateService:
    """Applies quantum gates to a GameState, returning a new GameState.

    Mirrored from GateService.dart.  Does NOT manage cooldowns, forbidden
    areas, or turn advancement — those are handled by GameService.
    """

    def apply_gate(
        self,
        state: GameState,
        gate: GateType,
        target_positions: List[Tuple[int, int]],  # [(row, col), ...]
    ) -> GameState:
        if gate.is_one_bit:
            return self._apply_one_bit(state, gate, target_positions)
        else:
            return self._apply_two_bit(state, gate, target_positions)

    # ── 1-bit gate ──────────────────────────────────────────

    def _apply_one_bit(
        self,
        state: GameState,
        gate: GateType,
        positions: List[Tuple[int, int]],
    ) -> GameState:
        player = state.get_current_player()
        if player is None:
            return state

        # Forbidden area positions for this player (from opponent's last move)
        forbidden = state.get_forbidden_areas(player.id)

        def _is_forbidden(row: int, col: int) -> bool:
            for area in forbidden:
                if area.contains(row, col):
                    return True
            return False

        is_row_or_col = len(positions) == 8  # exactly one row or one column

        new_board = state.board
        for (r, c) in positions:
            piece = new_board.get_piece(r, c)
            if piece is None:
                continue

            # Forbidden area guard: skip piece (both row/col and 4-cell modes)
            if _is_forbidden(r, c):
                continue

            # Entanglement guard
            if piece.is_entangled:
                if is_row_or_col:
                    # Stop propagation at entangled piece
                    break
                else:
                    # 4-cell: skip entangled piece only
                    continue

            new_type = apply_one_bit_to_piece(piece.type, gate)
            new_board = new_board.set_piece(r, c, piece.copy_with(type=new_type))

        return state.copy_with(board=new_board)

    # ── 2-bit gate ──────────────────────────────────────────

    def _apply_two_bit(
        self,
        state: GameState,
        gate: GateType,
        positions: List[Tuple[int, int]],
    ) -> GameState:
        if len(positions) != 2:
            return state

        (r1, c1), (r2, c2) = positions
        if not _is_adjacent(r1, c1, r2, c2):
            return state

        player = state.get_current_player()
        if player is None:
            return state

        piece1 = state.board.get_piece(r1, c1)
        piece2 = state.board.get_piece(r2, c2)
        if piece1 is None or piece2 is None:
            return state
        if piece1.is_entangled or piece2.is_entangled:
            return state

        if gate == GateType.SWAP:
            new_board = state.board
            # piece2 goes to pos1, piece1 goes to pos2 (matching Dart: setPiece(pos1, newPiece2))
            new_board = new_board.set_piece(r1, c1, piece2.copy_with(row=r1, col=c1))
            new_board = new_board.set_piece(r2, c2, piece1.copy_with(row=r2, col=c2))
            return state.copy_with(board=new_board)

        if gate == GateType.CNOT:
            return self._apply_cnot(state, player, piece1, piece2, r1, c1, r2, c2)

        return state

    def _apply_cnot(
        self,
        state: GameState,
        player: Player,
        piece1: Piece,
        piece2: Piece,
        r1: int, c1: int,
        r2: int, c2: int,
    ) -> GameState:
        is_vs_mode = True  # for AI training we always use VS mode rules
        result = _cnot_result(piece1, piece2, player.color, is_vs_mode)

        new_board = state.board
        new_board = new_board.set_piece(r1, c1, result[0])
        new_board = new_board.set_piece(r2, c2, result[1])

        new_entangled = list(state.entangled_pairs)
        if result[2] is not None:  # entangled pair id
            new_entangled.append(EntangledPair(
                id=result[2],
                pos1=(r1, c1),
                pos2=(r2, c2),
            ))

        return state.copy_with(board=new_board, entangled_pairs=new_entangled)


# ─────────────────────────────────────────────────────────────
# CNOT helpers
# ─────────────────────────────────────────────────────────────

def _is_adjacent(r1: int, c1: int, r2: int, c2: int) -> bool:
    dr, dc = abs(r1 - r2), abs(c1 - c2)
    return (dr <= 1 and dc <= 1) and not (dr == 0 and dc == 0)


def _cnot_result(
    piece1: Piece,
    piece2: Piece,
    player_color: PlayerColor,
    is_vs_mode: bool,
) -> Tuple[Piece, Piece, Optional[str]]:
    """Returns (new_piece1, new_piece2, optional_entangled_pair_id).

    Implements the full CNOT truth table from design-document.md §2.6.
    """
    t1, t2 = piece1.type, piece2.type

    # ── VS mode: opponent's color triggers X on piece2 ──────
    if is_vs_mode:
        is_opponent = (
            (player_color == PlayerColor.WHITE and t1 == PieceType.BLACK) or
            (player_color == PlayerColor.BLACK and t1 == PieceType.WHITE)
        )
        if is_opponent:
            new_t2 = apply_one_bit_to_piece(t2, GateType.X)
            return piece1, piece2.copy_with(type=new_t2), None
        is_own = (
            (player_color == PlayerColor.WHITE and t1 == PieceType.WHITE) or
            (player_color == PlayerColor.BLACK and t1 == PieceType.BLACK)
        )
        if is_own:
            return piece1, piece2, None
    else:
        # normal mode: own color triggers X
        is_own = (
            (player_color == PlayerColor.WHITE and t1 == PieceType.WHITE) or
            (player_color == PlayerColor.BLACK and t1 == PieceType.BLACK)
        )
        if is_own:
            new_t2 = apply_one_bit_to_piece(t2, GateType.X)
            return piece1, piece2.copy_with(type=new_t2), None
        is_opponent = (
            (player_color == PlayerColor.WHITE and t1 == PieceType.BLACK) or
            (player_color == PlayerColor.BLACK and t1 == PieceType.WHITE)
        )
        if is_opponent:
            return piece1, piece2, None

    # ── Gray piece as control ─────────────────────────────────
    if t1 in (PieceType.GRAY_PLUS, PieceType.GRAY_MINUS):
        return _cnot_gray_control(piece1, piece2, player_color, is_vs_mode)

    return piece1, piece2, None


def _cnot_gray_control(
    piece1: Piece,
    piece2: Piece,
    player_color: PlayerColor,
    is_vs_mode: bool,
) -> Tuple[Piece, Piece, Optional[str]]:
    """CNOT with gray piece as control (design-document.md §2.6 table)."""
    t1, t2 = piece1.type, piece2.type
    pair_id = f"ep_{uuid.uuid4().hex[:8]}"

    def entangle(nt1: PieceType, nt2: PieceType) -> Tuple[Piece, Piece, Optional[str]]:
        is_ent = nt1.is_entangled or nt2.is_entangled
        pid = pair_id if is_ent else None
        p1 = piece1.copy_with(type=nt1, entangled_pair_id=pid)
        p2 = piece2.copy_with(type=nt2, entangled_pair_id=pid)
        return p1, p2, pid

    if t1 == PieceType.GRAY_PLUS:
        if t2 == PieceType.GRAY_PLUS:
            return entangle(PieceType.GRAY_PLUS, PieceType.GRAY_PLUS)
        if t2 == PieceType.GRAY_MINUS:
            return entangle(PieceType.GRAY_MINUS, PieceType.GRAY_MINUS)
        if t2 in (PieceType.WHITE, PieceType.BLACK):
            is_my = (player_color == PlayerColor.WHITE and t2 == PieceType.WHITE) or \
                    (player_color == PlayerColor.BLACK and t2 == PieceType.BLACK)
            if is_vs_mode:
                if not is_my:   # opponent
                    return entangle(PieceType.WHITE_BLACK, PieceType.BLACK_WHITE)
                else:           # own
                    return entangle(PieceType.WHITE_BLACK, PieceType.WHITE_BLACK)
            else:
                if is_my:
                    return entangle(PieceType.WHITE_BLACK, PieceType.BLACK_WHITE)
                else:
                    return entangle(PieceType.WHITE_BLACK, PieceType.WHITE_BLACK)

    if t1 == PieceType.GRAY_MINUS:
        if t2 == PieceType.GRAY_PLUS:
            return entangle(PieceType.GRAY_MINUS, PieceType.GRAY_MINUS)
        if t2 == PieceType.GRAY_MINUS:
            return entangle(PieceType.GRAY_PLUS, PieceType.GRAY_MINUS)
        if t2 in (PieceType.WHITE, PieceType.BLACK):
            is_my = (player_color == PlayerColor.WHITE and t2 == PieceType.WHITE) or \
                    (player_color == PlayerColor.BLACK and t2 == PieceType.BLACK)
            if is_vs_mode:
                if not is_my:
                    return entangle(PieceType.BLACK_WHITE, PieceType.WHITE_BLACK)
                else:
                    return entangle(PieceType.BLACK_WHITE, PieceType.BLACK_WHITE)
            else:
                if is_my:
                    return entangle(PieceType.BLACK_WHITE, PieceType.WHITE_BLACK)
                else:
                    return entangle(PieceType.BLACK_WHITE, PieceType.BLACK_WHITE)

    return piece1, piece2, None

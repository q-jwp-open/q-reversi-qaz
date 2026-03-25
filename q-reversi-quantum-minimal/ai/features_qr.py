"""Feature extraction for Q-Reversi (QAZ-QR).

Designs 32 features capturing the unique quantum state of the Q-Reversi board.
These feed into the QPVN-QR circuit (ai/quantum_evaluator_qr.py).

Feature groups:
  F0-F7   : Piece-type composition (8)
  F8-F15  : Spatial / positional value (8)
  F16-F21 : Entanglement structure (6)
  F22-F25 : Cooldown / mobility (4)
  F26-F29 : Measurement expectation (4)
  F30-F31 : Game phase (2)
  Total   : 32
"""
from __future__ import annotations

from typing import List, Optional

import numpy as np

from qreversi.types import GateType, PieceType, PlayerColor
from qreversi.game_state import Board, GameState
from qreversi.game_service import GameService, QRAction
from qreversi.measurement import _piece_measurement_probs

NUM_FEATURES = 32
_svc = GameService()

# ─────────────────────────────────────────────────────────────
# Corner / edge positions (8×8)
# ─────────────────────────────────────────────────────────────
_CORNERS = {(0, 0), (0, 7), (7, 0), (7, 7)}
_EDGES = {
    (r, c)
    for r in range(8) for c in range(8)
    if r == 0 or r == 7 or c == 0 or c == 7
} - _CORNERS
_INNER = {
    (r, c)
    for r in range(1, 7) for c in range(1, 7)
}
_TOTAL = 64


def extract_features(state: GameState, player_color: PlayerColor) -> np.ndarray:
    """Extract 32 features for the given player from a game state.

    Returns float32 array of shape (NUM_FEATURES,), values in [-1, 1].
    """
    board = state.board
    player = _player_for_color(state, player_color)
    opponent = _opponent_for_color(state, player_color)
    opp_color = PlayerColor.BLACK if player_color == PlayerColor.WHITE else PlayerColor.WHITE

    # ── Piece counts ────────────────────────────────────────
    my_white = my_black = my_gray_plus = my_gray_minus = 0
    opp_white = opp_black = opp_gray_plus = opp_gray_minus = 0
    my_entangled = opp_entangled = 0
    superposition_count = 0

    # ── Spatial accumulators ─────────────────────────────────
    my_corner = my_edge = my_inner = 0
    opp_corner = opp_edge = opp_inner = 0
    my_pos_value = opp_pos_value = 0.0

    for r in range(8):
        for c in range(8):
            p = board.get_piece(r, c)
            if p is None:
                continue

            is_mine = _is_my_color(p.type, player_color)
            is_opp = _is_opp_color(p.type, opp_color)
            pos = (r, c)
            pos_val = _position_value(r, c)

            if p.type.is_entangled:
                if is_mine:
                    my_entangled += 1
                elif is_opp:
                    opp_entangled += 1
            elif p.type.is_superposition:
                superposition_count += 1
                if p.type == PieceType.GRAY_PLUS:
                    if is_mine:
                        my_gray_plus += 1
                    else:
                        opp_gray_plus += 1
                else:
                    if is_mine:
                        my_gray_minus += 1
                    else:
                        opp_gray_minus += 1
            else:
                if player_color == PlayerColor.WHITE:
                    if p.type == PieceType.WHITE:
                        my_white += 1
                    else:
                        opp_black += 1
                else:
                    if p.type == PieceType.BLACK:
                        my_black += 1
                    else:
                        opp_white += 1

            if is_mine:
                if pos in _CORNERS:
                    my_corner += 1
                elif pos in _EDGES:
                    my_edge += 1
                else:
                    my_inner += 1
                my_pos_value += pos_val
            elif is_opp:
                if pos in _CORNERS:
                    opp_corner += 1
                elif pos in _EDGES:
                    opp_edge += 1
                else:
                    opp_inner += 1
                opp_pos_value += pos_val

    # ── Determine confirmed piece counts ─────────────────────
    my_determined = my_white + my_black
    opp_determined = opp_white + opp_black
    my_superpos = my_gray_plus + my_gray_minus
    opp_superpos = opp_gray_plus + opp_gray_minus

    # ── Legal action count ────────────────────────────────────
    legal = _svc.legal_actions(state)
    my_legal_count = len(legal)

    # How many 1-bit gate types are available?
    my_one_bit_avail = sum(
        1 for g in [GateType.H, GateType.X, GateType.Y, GateType.Z]
        if player is not None and player.can_use_gate(g)
    )
    my_two_bit_avail = sum(
        1 for g in [GateType.CNOT, GateType.SWAP]
        if player is not None and player.can_use_gate(g)
    )

    # Opponent gate availability
    opp_one_bit_avail = sum(
        1 for g in [GateType.H, GateType.X, GateType.Y, GateType.Z]
        if opponent is not None and opponent.can_use_gate(g)
    )

    # ── Entanglement structure ────────────────────────────────
    n_pairs = len(state.entangled_pairs)
    # Pairs where both pieces favor my color
    my_pairs = sum(
        1 for ep in state.entangled_pairs
        if _is_my_color_entangled(ep, board, player_color)
    )
    opp_pairs = n_pairs - my_pairs

    # ── Measurement expectation ───────────────────────────────
    my_exp = opp_exp = 0.0
    for r in range(8):
        for c in range(8):
            p = board.get_piece(r, c)
            if p is None:
                continue
            wp, bp = _piece_measurement_probs(p.type)
            if player_color == PlayerColor.WHITE:
                if _is_my_color(p.type, player_color) or p.type.is_superposition or p.type.is_entangled:
                    my_exp += wp
                    opp_exp += bp
            else:
                if _is_my_color(p.type, player_color) or p.type.is_superposition or p.type.is_entangled:
                    my_exp += bp
                    opp_exp += wp

    # ── Game phase ────────────────────────────────────────────
    turn_ratio = state.turn_count / max(1, state.max_turns)

    # ─────────────────────────────────────────────────────────
    # Assemble feature vector (32 values, all in [-1, 1])
    # ─────────────────────────────────────────────────────────
    def _norm(x: float, total: float = _TOTAL) -> float:
        return float(x) / max(1.0, total)

    def _diff_norm(a: float, b: float, total: float = _TOTAL) -> float:
        return (float(a) - float(b)) / max(1.0, total)

    feats = np.zeros(NUM_FEATURES, dtype=np.float32)

    # F0-F7: Piece-type composition
    feats[0] = _diff_norm(my_determined, opp_determined)
    feats[1] = _diff_norm(my_superpos, opp_superpos)
    feats[2] = _norm(my_determined)
    feats[3] = _norm(opp_determined)
    feats[4] = _norm(my_superpos)
    feats[5] = _norm(opp_superpos)
    feats[6] = _diff_norm(my_entangled, opp_entangled)
    feats[7] = _norm(superposition_count)

    # F8-F15: Spatial / positional value
    feats[8]  = _diff_norm(my_corner, opp_corner, 4)
    feats[9]  = _diff_norm(my_edge, opp_edge, 28)
    feats[10] = _diff_norm(my_inner, opp_inner, 36)
    feats[11] = float(np.clip((my_pos_value - opp_pos_value) / 64.0, -1, 1))
    feats[12] = _norm(my_corner, 4)
    feats[13] = _norm(opp_corner, 4)
    feats[14] = _norm(my_edge, 28)
    feats[15] = _norm(opp_edge, 28)

    # F16-F21: Entanglement structure
    feats[16] = _norm(n_pairs, 16)                        # total entangled pairs
    feats[17] = _diff_norm(my_pairs, opp_pairs, max(1, n_pairs))
    feats[18] = _norm(my_entangled, _TOTAL)
    feats[19] = _norm(opp_entangled, _TOTAL)
    feats[20] = float(my_pairs) / max(1.0, n_pairs)       # ratio of my pairs
    feats[21] = float(my_entangled) / max(1.0, my_entangled + opp_entangled + 1)

    # F22-F25: Cooldown / mobility
    feats[22] = float(my_one_bit_avail) / 4.0
    feats[23] = float(my_two_bit_avail) / 2.0
    feats[24] = float(opp_one_bit_avail) / 4.0
    feats[25] = float(np.clip(my_legal_count / 200.0, 0.0, 1.0))  # max ~200 actions

    # F26-F29: Measurement expectation
    feats[26] = float(np.clip(my_exp / _TOTAL, 0, 1))
    feats[27] = float(np.clip(opp_exp / _TOTAL, 0, 1))
    feats[28] = float(np.clip((my_exp - opp_exp) / _TOTAL, -1, 1))
    feats[29] = float(np.clip(my_exp / max(1.0, my_exp + opp_exp), 0, 1))

    # F30-F31: Game phase
    feats[30] = float(turn_ratio)          # 0 → early, 1 → late
    feats[31] = 1.0 - float(turn_ratio)    # turns remaining ratio

    return feats


def compute_delta_features(
    state: GameState,
    action: QRAction,
    player_color: PlayerColor,
    game_service: Optional[GameService] = None,
) -> np.ndarray:
    """Compute Δf(s, a) = f(s') - f(s) for a single action.

    Shape: (NUM_FEATURES,).
    Used by the policy head: score(s,a) = W_P · concat(z, Δf).
    """
    svc = game_service or _svc
    f_before = extract_features(state, player_color)
    next_state = svc.apply_action(state, action)
    f_after = extract_features(next_state, player_color)
    return (f_after - f_before).astype(np.float32)


def compute_all_delta_features(
    state: GameState,
    actions: List[QRAction],
    player_color: PlayerColor,
) -> np.ndarray:
    """Return Δf for all actions. Shape: (len(actions), NUM_FEATURES)."""
    f_before = extract_features(state, player_color)
    deltas = []
    for a in actions:
        next_state = _svc.apply_action(state, a)
        f_after = extract_features(next_state, player_color)
        deltas.append(f_after - f_before)
    return np.array(deltas, dtype=np.float32)


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

def _position_value(r: int, c: int) -> float:
    """Simple positional weight: corners > edges > inner."""
    if (r, c) in _CORNERS:
        return 1.0
    if (r, c) in _EDGES:
        return 0.5
    return 0.2


def _is_my_color(piece_type: PieceType, my_color: PlayerColor) -> bool:
    if my_color == PlayerColor.WHITE:
        return piece_type == PieceType.WHITE
    return piece_type == PieceType.BLACK


def _is_opp_color(piece_type: PieceType, opp_color: PlayerColor) -> bool:
    return _is_my_color(piece_type, opp_color)


def _is_my_color_entangled(ep, board: Board, my_color: PlayerColor) -> bool:
    """True if both pieces of an entangled pair are 'favoring' my color."""
    p1 = board.get_piece(*ep.pos1)
    p2 = board.get_piece(*ep.pos2)
    if p1 is None or p2 is None:
        return False
    # WHITE_BLACK / BLACK_WHITE are equally likely to be either color after measurement
    # We use a heuristic: whiteBlack favors white, blackWhite favors black
    if my_color == PlayerColor.WHITE:
        return p1.type == PieceType.WHITE_BLACK or p2.type == PieceType.WHITE_BLACK
    else:
        return p1.type == PieceType.BLACK_WHITE or p2.type == PieceType.BLACK_WHITE


def _player_for_color(state: GameState, color: PlayerColor):
    for p in state.players.values():
        if p.color == color:
            return p
    return None


def _opponent_for_color(state: GameState, color: PlayerColor):
    opp = PlayerColor.BLACK if color == PlayerColor.WHITE else PlayerColor.WHITE
    return _player_for_color(state, opp)

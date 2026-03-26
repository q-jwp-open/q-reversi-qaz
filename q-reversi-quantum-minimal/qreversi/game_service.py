"""Full game logic for Q-Reversi.

Ported from q-reversi-app/lib/domain/services/game_service.dart.
Handles:
  - Cooldown enforcement
  - Forbidden-area checks
  - Entanglement guards
  - Turn advancement
  - Legal action enumeration
"""
from __future__ import annotations

from typing import List, NamedTuple, Optional, Tuple

from .types import ForbiddenAreaType, GateType, PlayerColor
from .game_state import (
    ForbiddenArea,
    GameState,
    Player,
)
from .gate_service import GateService, _is_adjacent

_gate_service = GateService()


# ─────────────────────────────────────────────────────────────
# Action representation
# ─────────────────────────────────────────────────────────────

class QRAction(NamedTuple):
    """A legal action: (gate, target_positions)."""
    gate: GateType
    positions: Tuple[Tuple[int, int], ...]  # immutable

    def __repr__(self) -> str:
        return f"QRAction({self.gate.value}, {list(self.positions)})"


# ─────────────────────────────────────────────────────────────
# GameService
# ─────────────────────────────────────────────────────────────

class GameService:
    """Applies a full game step (gate + state bookkeeping)."""

    def apply_action(self, state: GameState, action: QRAction) -> GameState:
        return self.apply_gate(state, action.gate, list(action.positions))

    def apply_gate(
        self,
        state: GameState,
        gate: GateType,
        target_positions: List[Tuple[int, int]],
    ) -> GameState:
        """Apply gate with full VS-mode logic. Returns unchanged state on illegal move."""
        player = state.get_current_player()
        if player is None:
            return state

        # ── Cooldown check ──────────────────────────────────
        if not player.can_use_gate(gate):
            return state

        # ── Forbidden area check (1-bit gates only) ──────────
        if gate.is_one_bit:
            my_forbidden = state.get_forbidden_areas(player.id)
            for area in my_forbidden:
                if _is_target_forbidden(area, gate, target_positions):
                    return state

        # ── Entanglement guard (2-bit gates: hard block) ─────
        if gate.is_two_bit:
            for (r, c) in target_positions:
                p = state.board.get_piece(r, c)
                if p is not None and p.is_entangled:
                    return state

        # ── Apply gate transformation ─────────────────────────
        new_state = _gate_service.apply_gate(state, gate, target_positions)

        # ── Cooldown update ───────────────────────────────────
        updated_player = player.use_gate(gate)
        new_players = dict(new_state.players)
        new_players[player.id] = updated_player

        # ── Forbidden area update ─────────────────────────────
        forbidden_area = _create_forbidden_area(gate, target_positions)
        new_forbidden = {k: list(v) for k, v in new_state.forbidden_areas.items()}
        opponent_id = new_state.opponent_id

        new_forbidden[player.id] = []           # clear current player's restriction
        new_forbidden[opponent_id] = [forbidden_area]  # restrict opponent next turn

        # ── Last 2-bit gate positions ─────────────────────────
        new_two_bit = {k: list(v) for k, v in new_state.last_two_bit_positions.items()}
        if gate.is_two_bit and len(target_positions) == 2:
            new_two_bit[player.id] = []
            new_two_bit[opponent_id] = list(target_positions)
        else:
            new_two_bit[player.id] = []

        # ── Advance turn / opponent cooldown decrease ─────────
        next_player_id = opponent_id
        next_player = new_players.get(next_player_id)
        if next_player is not None:
            new_players[next_player_id] = next_player.decrease_cooldowns()

        return new_state.copy_with(
            players=new_players,
            forbidden_areas=new_forbidden,
            last_two_bit_positions=new_two_bit,
            current_player=next_player_id,
            turn_count=new_state.turn_count + 1,
        )

    # ─────────────────────────────────────────────────────────
    # Legal action enumeration
    # ─────────────────────────────────────────────────────────

    def legal_actions(self, state: GameState) -> List[QRAction]:
        """Return all legal actions for the current player."""
        player = state.get_current_player()
        if player is None or state.is_game_over:
            return []

        actions = []
        board = state.board

        for gate in GateType:
            if not player.can_use_gate(gate):
                continue

            if gate.is_one_bit:
                my_forbidden = state.get_forbidden_areas(player.id)

                # Row targets
                for r in range(board.rows):
                    pos = tuple((r, c) for c in range(board.cols))
                    if not _is_one_bit_target_forbidden(my_forbidden, gate, list(pos)):
                        actions.append(QRAction(gate=gate, positions=pos))

                # Column targets
                for c in range(board.cols):
                    pos = tuple((r, c) for r in range(board.rows))
                    if not _is_one_bit_target_forbidden(my_forbidden, gate, list(pos)):
                        actions.append(QRAction(gate=gate, positions=pos))

                # 4-cell square targets
                for r in range(board.rows - 1):
                    for c in range(board.cols - 1):
                        pos = (
                            (r, c), (r, c + 1),
                            (r + 1, c), (r + 1, c + 1),
                        )
                        if not _is_one_bit_target_forbidden(my_forbidden, gate, list(pos)):
                            actions.append(QRAction(gate=gate, positions=pos))

            else:  # 2-bit gate
                for r in range(board.rows):
                    for c in range(board.cols):
                        for dr in range(-1, 2):
                            for dc in range(-1, 2):
                                if dr == 0 and dc == 0:
                                    continue
                                r2, c2 = r + dr, c + dc
                                if not board.is_valid(r2, c2):
                                    continue
                                p1 = board.get_piece(r, c)
                                p2 = board.get_piece(r2, c2)
                                if p1 is None or p2 is None:
                                    continue
                                if p1.is_entangled or p2.is_entangled:
                                    continue
                                pos = ((r, c), (r2, c2))
                                actions.append(QRAction(gate=gate, positions=pos))

        # Deduplicate (rows/cols produce duplicate pairs for 2-bit gates)
        seen = set()
        unique = []
        for a in actions:
            key = (a.gate, a.positions)
            if key not in seen:
                seen.add(key)
                unique.append(a)

        return unique

    def action_count(self, state: GameState) -> int:
        return len(self.legal_actions(state))


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────

def _is_target_forbidden(
    area: ForbiddenArea,
    gate: GateType,
    target_positions: List[Tuple[int, int]],
) -> bool:
    if not gate.is_one_bit:
        return False
    if area.type == ForbiddenAreaType.ROW and target_positions:
        return area.row == target_positions[0][0]
    if area.type == ForbiddenAreaType.COLUMN and target_positions:
        return area.column == target_positions[0][1]
    if area.type == ForbiddenAreaType.FOUR_PIECES:
        return area.is_four_pieces_forbidden(target_positions)
    return False


def _is_one_bit_target_forbidden(
    opp_forbidden: List[ForbiddenArea],
    gate: GateType,
    target_positions: List[Tuple[int, int]],
) -> bool:
    for area in opp_forbidden:
        if _is_target_forbidden(area, gate, target_positions):
            return True
    return False


def _create_forbidden_area(
    gate: GateType,
    target_positions: List[Tuple[int, int]],
) -> ForbiddenArea:
    if gate.is_one_bit:
        n = len(target_positions)
        if n == 8:
            # Row or column?
            rows = {p[0] for p in target_positions}
            cols = {p[1] for p in target_positions}
            if len(rows) == 1:
                return ForbiddenArea.for_row(next(iter(rows)))
            if len(cols) == 1:
                return ForbiddenArea.for_column(next(iter(cols)))
        if n == 4:
            return ForbiddenArea.for_four_pieces(target_positions)
    # 2-bit gate or fallback: empty forbidden area (no restriction)
    return ForbiddenArea.for_four_pieces([])

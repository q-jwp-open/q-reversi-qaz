"""Measurement (game-end scoring) for Q-Reversi.

Implements the stochastic measurement rules from design-document.md §2.10.
Used both for actual game termination and for expected-value estimation
during AI tree search.
"""
from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

from .types import PieceType, PlayerColor
from .game_state import Board, EntangledPair, GameState


# ─────────────────────────────────────────────────────────────
# Measurement rules
# ─────────────────────────────────────────────────────────────
# §2.10 (design-document.md):
#   white / black          → unchanged
#   grayPlus / grayMinus   → 50% → white, 50% → black
#   blackWhite / whiteBlack → 50% → white, 50% → black
#   entangled pair         → 1st piece measured, 2nd determined by 1st

def _measure_superposition(rng: random.Random) -> PieceType:
    return PieceType.WHITE if rng.random() < 0.5 else PieceType.BLACK


def _measure_entangled_pair(
    type1: PieceType,
    rng: random.Random,
) -> Tuple[PieceType, PieceType]:
    """Measure a CNOT-generated entangled pair.

    blackWhite: collapses to (black, black) or (white, white)
    whiteBlack: collapses to (black, black) or (white, white)

    (Both encode a Bell state; measurement gives correlated outcomes.)
    """
    outcome = rng.random() < 0.5  # True → first outcome is "black"
    if type1 == PieceType.BLACK_WHITE:
        return (PieceType.BLACK, PieceType.BLACK) if outcome else (PieceType.WHITE, PieceType.WHITE)
    if type1 == PieceType.WHITE_BLACK:
        return (PieceType.BLACK, PieceType.BLACK) if outcome else (PieceType.WHITE, PieceType.WHITE)
    # fallback
    r = _measure_superposition(rng)
    return r, r


# ─────────────────────────────────────────────────────────────
# MeasurementResult
# ─────────────────────────────────────────────────────────────

@dataclass
class MeasurementResult:
    white_count: int
    black_count: int
    winner: Optional[PlayerColor]  # None on draw

    @property
    def score_diff(self) -> int:
        """white_count - black_count"""
        return self.white_count - self.black_count

    def winner_from_color(self, color: PlayerColor) -> float:
        """Return +1 / 0 / -1 from the perspective of `color`."""
        if self.winner is None:
            return 0.0
        return 1.0 if self.winner == color else -1.0


# ─────────────────────────────────────────────────────────────
# MeasurementService
# ─────────────────────────────────────────────────────────────

class MeasurementService:

    def measure(
        self,
        state: GameState,
        seed: Optional[int] = None,
    ) -> MeasurementResult:
        """Perform a single stochastic measurement and count pieces."""
        rng = random.Random(seed)
        board = state.board

        # Track which positions have been resolved as part of an entangled pair
        entangled_resolved: Dict[Tuple[int, int], PieceType] = {}
        for pair in state.entangled_pairs:
            p1 = board.get_piece(*pair.pos1)
            if p1 is None:
                continue
            t1, t2 = _measure_entangled_pair(p1.type, rng)
            entangled_resolved[pair.pos1] = t1
            entangled_resolved[pair.pos2] = t2

        white_count = 0
        black_count = 0

        for r in range(board.rows):
            for c in range(board.cols):
                piece = board.get_piece(r, c)
                if piece is None:
                    continue

                if (r, c) in entangled_resolved:
                    final_type = entangled_resolved[(r, c)]
                elif piece.type == PieceType.WHITE:
                    final_type = PieceType.WHITE
                elif piece.type == PieceType.BLACK:
                    final_type = PieceType.BLACK
                elif piece.type.is_superposition:
                    final_type = _measure_superposition(rng)
                else:
                    # already an entangled type not in pairs dict → treat as superposition
                    final_type = _measure_superposition(rng)

                if final_type == PieceType.WHITE:
                    white_count += 1
                else:
                    black_count += 1

        if white_count > black_count:
            winner = PlayerColor.WHITE
        elif black_count > white_count:
            winner = PlayerColor.BLACK
        else:
            winner = None

        return MeasurementResult(
            white_count=white_count,
            black_count=black_count,
            winner=winner,
        )

    def expected_score(
        self,
        state: GameState,
        player_color: PlayerColor,
        samples: int = 200,
        seed: Optional[int] = None,
    ) -> float:
        """Monte Carlo estimate of P(player_color wins) in [-1, +1].

        Runs `samples` independent measurements and averages.
        Used as rollout value in MCTS.
        """
        rng = random.Random(seed)
        wins = 0
        draws = 0
        for i in range(samples):
            result = self.measure(state, seed=rng.randint(0, 2**31))
            if result.winner == player_color:
                wins += 1
            elif result.winner is None:
                draws += 1

        return (wins + 0.5 * draws) / samples * 2.0 - 1.0

    def deterministic_expected_value(
        self,
        state: GameState,
        player_color: PlayerColor,
    ) -> float:
        """Closed-form expected score (no sampling).

        Each piece contributes:
          white/black:    ±1  (certain)
          superposition:  0   (equal probability → cancel)
          entangled:      depends on pair type (also ≈ 0 in expectation)
        Returns score in [-1, +1] range.
        """
        board = state.board
        total = board.rows * board.cols

        my_expected = 0.0
        opp_expected = 0.0

        for r in range(board.rows):
            for c in range(board.cols):
                piece = board.get_piece(r, c)
                if piece is None:
                    continue
                white_prob, black_prob = _piece_measurement_probs(piece.type)
                if player_color == PlayerColor.WHITE:
                    my_expected += white_prob
                    opp_expected += black_prob
                else:
                    my_expected += black_prob
                    opp_expected += white_prob

        if total == 0:
            return 0.0
        return (my_expected - opp_expected) / total


def _piece_measurement_probs(piece_type: PieceType) -> Tuple[float, float]:
    """Return (P(white), P(black)) for a single piece."""
    if piece_type == PieceType.WHITE:
        return 1.0, 0.0
    if piece_type == PieceType.BLACK:
        return 0.0, 1.0
    # superposition or entangled → 50/50
    return 0.5, 0.5

"""FourPlyQPVNPlayer: 4-ply minimax with QPVN quantum circuit for candidate selection.

Architecture (integrates insights from FourPlyMiniMaxQR):

  Depth-1 (AI):
    1a. Score ALL legal actions with classical eval  → top K_PRE=30 candidates
    1b. Score top K_PRE with QPVNEvaluatorQR         → top K1=10 by QPVN value

  Depth-2 (Opp, greedy):
    Opponent plays argmin(classical_eval) — single best reply

  Depth-3 (AI):
    Score all AI actions with classical eval → top K3=3

  Depth-4 (Opp, pessimistic tie-breaking):
    Opponent plays argmin(classical_eval).
    ALL tied-minimum moves evaluated via analytical P(win).
    Take worst-case (min) P(win) — pessimistic, correct minimax.

  Terminal:
    P(win) = Φ(μ / √n_gray)   [analytical, same as FourPlyMiniMaxQR]

Key insight: QPVN sees 32 rich features (spatial, entanglement, cooldowns, mobility)
vs classical eval which only counts confirmed pieces.  Using QPVN at depth-1 selects
better candidates for the deep search without slowing the search itself.

QPVN cost: K_PRE × 11ms ≈ 0.3 s/turn — negligible vs 3 s minimax.
"""
from __future__ import annotations

import random
from math import erf, sqrt
from pathlib import Path
from typing import List, Optional

import numpy as np

from qreversi.types import GateType, PieceType, PlayerColor
from qreversi.game_state import GameState
from qreversi.game_service import GameService, QRAction
from qreversi.measurement import MeasurementService

from ai.quantum_evaluator_qr import QPVNEvaluatorQR
from ai.features_qr import extract_features

_game_service = GameService()
_meas_service = MeasurementService()

_DEFAULT_PARAMS = Path(__file__).resolve().parent.parent / "trained" / "qpvn_params.json"


# ─────────────────────────────────────────────────────────────────────────────
# Shared evaluation helpers
# ─────────────────────────────────────────────────────────────────────────────

def _classical_eval(state: GameState, color: PlayerColor) -> float:
    """(certain_mine - certain_opp) / 64.  Identical to FourPlyMiniMaxQR."""
    return _meas_service.deterministic_expected_value(state, color)


def _prob_win_eval(state: GameState, color: PlayerColor) -> float:
    """Φ(μ / √n_gray) mapped to [-1, 1].  Identical to FourPlyMiniMaxQR."""
    mine = opp = n_gray = 0
    for row in state.board.pieces:
        for p in row:
            if p is None:
                continue
            t = p.type
            if color == PlayerColor.WHITE:
                if t == PieceType.WHITE:    mine  += 1
                elif t == PieceType.BLACK:  opp   += 1
            else:
                if t == PieceType.BLACK:    mine  += 1
                elif t == PieceType.WHITE:  opp   += 1
            if t in (PieceType.GRAY_PLUS, PieceType.GRAY_MINUS):
                n_gray += 1
    mu    = float(mine - opp)
    sigma = sqrt(max(1.0, float(n_gray)))
    z     = mu / (sigma * sqrt(2.0))
    prob  = (1.0 + erf(z)) / 2.0
    return 2.0 * prob - 1.0


# ─────────────────────────────────────────────────────────────────────────────
# FourPlyQPVNPlayer
# ─────────────────────────────────────────────────────────────────────────────

class FourPlyQPVNPlayer:
    """4-ply minimax + QPVN quantum circuit for depth-1 candidate selection.

    Combines the proven FourPlyMiniMaxQR search structure with the
    QPVNEvaluatorQR quantum circuit evaluator:
      - Classical eval filters all actions → K_PRE candidates (fast)
      - QPVN ranks K_PRE → top K1 final candidates (quantum)
      - Standard 4-ply minimax with pessimistic depth-4 tie-breaking
      - Analytical P(win) terminal (same as FourPlyMiniMaxQR)
    """

    K_PRE = 30   # classical pre-filter size (must be ≥ K1)
    K1    = 10   # QPVN-ranked candidates entering 4-ply
    K3    = 3    # depth-3 classical filter size

    def __init__(
        self,
        color: PlayerColor,
        params_file: Optional[str] = None,
        seed: int = 42,
    ):
        self.color    = color
        self._rng     = random.Random(seed)
        if params_file is None and _DEFAULT_PARAMS.exists():
            params_file = str(_DEFAULT_PARAMS)
        self._qpvn    = QPVNEvaluatorQR(params_file=params_file, seed=seed)

    # ── Public interface ──────────────────────────────────────────────────

    def choose_action(self, state: GameState) -> Optional[QRAction]:
        legal = _game_service.legal_actions(state)
        if not legal:
            return None
        if len(legal) == 1:
            return legal[0]

        # ── Stage 1a: classical pre-filter ────────────────────────────────
        s1_cache: List[Optional[GameState]] = []
        classical_scores = np.empty(len(legal))
        for i, a in enumerate(legal):
            s1 = _game_service.apply_action(state, a)
            s1_cache.append(s1)
            classical_scores[i] = _classical_eval(s1, self.color)

        k_pre = min(self.K_PRE, len(legal))
        pre_idx = np.argsort(classical_scores)[::-1][:k_pre]

        # ── Stage 1b: QPVN re-rank ────────────────────────────────────────
        qpvn_scores = np.empty(k_pre)
        for j, i in enumerate(pre_idx):
            s1 = s1_cache[i]
            feats = extract_features(s1, self.color)
            qpvn_scores[j] = self._qpvn.evaluate(feats)

        k1 = min(self.K1, k_pre)
        top_qpvn = np.argsort(qpvn_scores)[::-1][:k1]
        top_k1_idx = pre_idx[top_qpvn]  # original indices into `legal`

        # ── Stage 2-4: 4-ply minimax ──────────────────────────────────────
        best_score = float("-inf")
        best: List[QRAction] = []

        for i in top_k1_idx:
            s1 = s1_cache[i]
            score = self._eval_from_s2(s1)

            if score > best_score:
                best_score = score
                best = [legal[i]]
            elif score == best_score:
                best.append(legal[i])

        return self._rng.choice(best)

    # ── Search helpers ────────────────────────────────────────────────────

    def _eval_from_s2(self, s1: GameState) -> float:
        """Depth-2 greedy opp → depth-3 AI (K3) → depth-4 pessimistic opp → P(win)."""
        # Depth 2: greedy opponent (argmin classical)
        opp1 = _game_service.legal_actions(s1)
        if not opp1:
            return _prob_win_eval(s1, self.color)

        opp1_scores = np.array([
            _classical_eval(_game_service.apply_action(s1, b), self.color)
            for b in opp1
        ])
        s2 = _game_service.apply_action(s1, opp1[int(np.argmin(opp1_scores))])

        # Depth 3: AI top-K3 by classical eval
        ai2 = _game_service.legal_actions(s2)
        if not ai2:
            return _prob_win_eval(s2, self.color)

        ai2_scores = np.array([
            _classical_eval(_game_service.apply_action(s2, c), self.color)
            for c in ai2
        ])
        k3 = min(self.K3, len(ai2))
        top_k3 = np.argsort(ai2_scores)[::-1][:k3]

        best_k3 = float("-inf")
        for j in top_k3:
            s3 = _game_service.apply_action(s2, ai2[j])
            opp2 = _game_service.legal_actions(s3)

            if not opp2:
                v = _prob_win_eval(s3, self.color)
            else:
                # Depth 4: pessimistic — ALL tied min-classical opp moves → min P(win)
                opp2_scores = np.array([
                    _classical_eval(_game_service.apply_action(s3, d), self.color)
                    for d in opp2
                ])
                min_d4 = opp2_scores.min()
                tied   = np.where(np.abs(opp2_scores - min_d4) < 1e-12)[0]
                v = min(
                    _prob_win_eval(_game_service.apply_action(s3, opp2[j2]), self.color)
                    for j2 in tied
                )

            if v > best_k3:
                best_k3 = v

        return best_k3

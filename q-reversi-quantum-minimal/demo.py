#!/usr/bin/env python3
"""Demo: QPVN-QR quantum circuit evaluation for Q-Reversi.

Run from the project root:
    python demo.py
"""
from __future__ import annotations

import time

import numpy as np

from qreversi.types import PlayerColor
from qreversi.game_state import GameState
from qreversi.game_service import GameService
from qreversi.measurement import MeasurementService
from ai.quantum_evaluator_qr import QPVNEvaluatorQR, NUM_QUBITS, NUM_LAYERS, NUM_PARAMS
from ai.features_qr import extract_features, NUM_FEATURES


def demo_forward_pass():
    """1. Raw forward pass with random features."""
    print("=" * 60)
    print("  Demo 1: QPVN-QR Forward Pass (random features)")
    print("=" * 60)
    print(f"  Qubits: {NUM_QUBITS}  Layers: {NUM_LAYERS}  Params: {NUM_PARAMS}")
    print(f"  Features: {NUM_FEATURES}")
    print()

    evaluator = QPVNEvaluatorQR(seed=0)

    rng = np.random.RandomState(42)
    features = rng.uniform(-1, 1, NUM_FEATURES).astype(np.float32)

    t0 = time.perf_counter()
    value, z_latent = evaluator.evaluate_with_latent(features)
    dt = (time.perf_counter() - t0) * 1000

    print(f"  Forward pass time: {dt:.1f} ms")
    print(f"  Value output:      {value:+.4f}  (range [-1, +1])")
    print(f"  Latent <Z> std:    {z_latent.std():.4f}")
    print(f"  Latent <Z>:        {np.array2string(z_latent, precision=3, separator=', ')}")
    print()


def demo_game_evaluation():
    """2. Evaluate an actual Q-Reversi game state."""
    print("=" * 60)
    print("  Demo 2: Evaluate a Q-Reversi Game State")
    print("=" * 60)

    state = GameState.create_initial(max_turns=20, seed=123)
    evaluator = QPVNEvaluatorQR(seed=0)

    for color in [PlayerColor.WHITE, PlayerColor.BLACK]:
        features = extract_features(state, color)
        value = evaluator.evaluate(features)
        print(f"  {color.value:5s} perspective: value = {value:+.4f}")

    # Show board composition
    w = b = g = e = 0
    for row in state.board.pieces:
        for p in row:
            if p is None:
                continue
            if p.type.is_determined:
                if p.type.value == "W":
                    w += 1
                else:
                    b += 1
            elif p.type.is_superposition:
                g += 1
            elif p.type.is_entangled:
                e += 1
    print(f"  Board: {w}W {b}B {g} superposition {e} entangled")
    print()


def demo_play_game():
    """3. Play a short game using FourPlyQPVNPlayer vs random moves."""
    print("=" * 60)
    print("  Demo 3: QPVN Player vs Random (1 game)")
    print("=" * 60)

    from ai.quantum_player import FourPlyQPVNPlayer

    svc = GameService()
    meas = MeasurementService()

    state = GameState.create_initial(max_turns=6, seed=42)
    ai = FourPlyQPVNPlayer(color=PlayerColor.WHITE, seed=42)
    rng = np.random.default_rng(99)

    turn = 0
    while not state.is_game_over:
        current = state.get_current_player()
        if current is None:
            break

        t0 = time.perf_counter()
        if current.color == PlayerColor.WHITE:
            action = ai.choose_action(state)
            who = "QPVN"
        else:
            legal = svc.legal_actions(state)
            action = legal[rng.integers(len(legal))] if legal else None
            who = "Rand"
        dt = time.perf_counter() - t0

        if action is None:
            break

        turn += 1
        print(f"  Turn {turn:2d} [{who}]  {action.gate.value:4s} → {list(action.positions)[:2]}...  ({dt:.2f}s)")
        state = svc.apply_action(state, action)

    result = meas.measure(state, seed=0)
    print(f"\n  Final: W={result.white_count} B={result.black_count}  "
          f"Winner: {result.winner.value if result.winner else 'Draw'}")
    print()


if __name__ == "__main__":
    demo_forward_pass()
    demo_game_evaluation()
    demo_play_game()
    print("All demos completed.")

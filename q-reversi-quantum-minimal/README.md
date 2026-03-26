# Q-Reversi Quantum — Minimal Standalone

Variational quantum circuit (VQC) を用いた **Q-Reversi** (量子リバーシ) AI の最小構成パッケージ。

量子ゲート操作を含むボードゲーム「Q-Reversi」に対して、14量子ビット変分回路 (QPVN-QR) で盤面を評価し、4手読みミニマックス探索と組み合わせることで対戦する AI プレイヤーを実装しています。

## Quick Start

```bash
# 依存: Python 3.10+, NumPy
pip install numpy

# デモ実行
python demo.py
```

## Architecture

### QPVN-QR (Quantum Policy-Value Network)

```
Input: 32-dim feature vector (board state)
         ↓
┌─────────────────────────────────────────────┐
│  14 Qubits  ×  3 Layers                     │
│                                              │
│  Register layout:                            │
│    R0 (Spatial)  : q[0:4]                    │
│    R1 (Action)   : q[4:8]                    │
│    R2 (QState)   : q[8:12]                   │
│    R3 (Context)  : q[12:14]                  │
│                                              │
│  Per layer:                                  │
│    1. Data encoding:  RY(α·f·π + β)         │
│    2. Variational:    RY(θ) → RZ(φ)         │
│    3. Entanglement:   54 CX gates            │
│       - Intra-register rings                 │
│       - Inter-register bridges               │
│       - Long-range (q3↔q8)                   │
└─────────────────────────────────────────────┘
         ↓
Measurement: ⟨Z_q⟩ for each qubit (14-dim)
         ↓
Value head: tanh(w·⟨Z⟩ + b) → [-1, +1]
```

- **183 trainable parameters** (α, β, θ, φ, w, b)
- **NumPy state-vector simulation** (2^14 = 16,384 次元) — 外部量子ライブラリ不要
- Forward pass: ~11 ms

### 32-Dimensional Features

| Index   | Group                | Description                         |
|---------|----------------------|-------------------------------------|
| F0–F7   | Piece composition    | 確定駒・重ね合わせ・エンタングル比率 |
| F8–F15  | Spatial value        | コーナー・エッジ・内部の位置価値     |
| F16–F21 | Entanglement         | ペア数・自分 vs 相手のペア比率       |
| F22–F25 | Cooldown / Mobility  | 利用可能ゲート・合法手数             |
| F26–F29 | Measurement expect.  | 測定期待値 (白/黒確率)               |
| F30–F31 | Game phase           | ターン進行率                         |

### FourPlyQPVNPlayer (AI)

```
Depth 1 (AI):      Classical eval → top 30 → QPVN re-rank → top 10
Depth 2 (Opponent): Greedy (argmin classical)
Depth 3 (AI):      Top 3 by classical eval
Depth 4 (Opponent): Pessimistic tie-breaking → analytical P(win)
```

## File Structure

```
q-reversi-quantum-minimal/
├── README.md                       ← This file
├── demo.py                         ← Demo script
├── qreversi/                       ← Game engine
│   ├── __init__.py
│   ├── types.py                    ← PieceType, GateType, PlayerColor
│   ├── game_state.py               ← Board, Piece, GameState (immutable)
│   ├── game_service.py             ← Turn logic, legal actions
│   ├── gate_service.py             ← Quantum gate transformations
│   └── measurement.py              ← Stochastic measurement, scoring
├── ai/
│   ├── __init__.py
│   ├── quantum_evaluator_qr.py     ← QPVN-QR circuit (core)
│   ├── features_qr.py              ← 32-dim feature extraction
│   └── quantum_player.py           ← 4-ply minimax + QPVN player
└── trained/
    └── qpvn_params.json            ← Trained circuit parameters (183 values)
```

## Q-Reversi Game Rules (概要)

- 8×8 ボードに 64 個の駒（白・黒・重ね合わせ |+⟩ |−⟩）をランダム配置
- プレイヤーは量子ゲート（H, X, Y, Z, CNOT, SWAP）を駒に適用
- ゲート適用後、クールダウンと禁止エリアのルールが発動
- CNOT で重ね合わせ駒をコントロールにすると **エンタングルメント** が生成
- 20 ターン後に全駒を測定 → 白/黒の多い方が勝利

## Requirements

- Python >= 3.10
- NumPy

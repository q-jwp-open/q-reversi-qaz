"""QPVN-QR: Quantum Policy-Value Network for Q-Reversi.

Architecture:
  - 32 input features capturing quantum board state
  - 14 qubits / 3 layers / 54 CX gates
  - Register layout: R0(Spatial q0-3), R1(Action q4-7), R2(QState q8-11), R3(Context q12-13)
  - Value head: tanh(w · <Z> + b)

Pure NumPy state-vector simulation — no external quantum library required.
Run standalone to verify circuit dimensions and a random forward pass.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Optional, Tuple

import numpy as np

from ai.features_qr import NUM_FEATURES

NUM_QUBITS = 14
NUM_LAYERS = 3
# params layout:
#   α[l,q]  : NUM_LAYERS * NUM_QUBITS  (feature encoding scale)
#   β[l,q]  : NUM_LAYERS * NUM_QUBITS  (feature encoding bias)
#   θ[l,q]  : NUM_LAYERS * NUM_QUBITS  (variational RY)
#   φ[l,q]  : NUM_LAYERS * NUM_QUBITS  (variational RZ)
#   w[q]    : NUM_QUBITS               (value head weights)
#   b       : 1                        (value head bias)
_N_ANG = NUM_LAYERS * NUM_QUBITS
NUM_PARAMS = 4 * _N_ANG + NUM_QUBITS + 1  # = 4*42 + 14 + 1 = 183


# ─────────────────────────────────────────────────────────────
# Entanglement topology (QPVN-14)
# ─────────────────────────────────────────────────────────────
# R0 (Spatial):   q[0:4]
# R1 (Action):    q[4:8]
# R2 (QState):    q[8:12]
# R3 (Context):   q[12:14]

def _entangle_layer_numpy(sv: np.ndarray) -> np.ndarray:
    """Apply the QPVN-14 entanglement topology to state vector."""
    # Intra-register rings (R0, R1, R2 — 4Q each)
    for reg_start in [0, 4, 8]:
        for i in range(4):
            ctrl = reg_start + i
            tgt = reg_start + (i + 1) % 4
            sv = _cx(sv, ctrl, tgt, NUM_QUBITS)
    # R3 pair
    sv = _cx(sv, 12, 13, NUM_QUBITS)
    # Inter-register bridges
    for (c, t) in [(3, 4), (7, 8), (11, 12), (13, 0)]:
        sv = _cx(sv, c, t, NUM_QUBITS)
    # Long-range
    sv = _cx(sv, 3, 8, NUM_QUBITS)
    return sv


# ─────────────────────────────────────────────────────────────
# NumPy state-vector simulation helpers
# ─────────────────────────────────────────────────────────────

def _ry(sv: np.ndarray, qubit: int, angle: float, n: int) -> np.ndarray:
    c, s = np.cos(angle / 2), np.sin(angle / 2)
    mat = np.array([[c, -s], [s, c]], dtype=np.complex128)
    return _apply_single(sv, qubit, mat, n)


def _rz(sv: np.ndarray, qubit: int, angle: float, n: int) -> np.ndarray:
    c = np.exp(-1j * angle / 2)
    mat = np.diag([c, np.conj(c)])
    return _apply_single(sv, qubit, mat, n)


def _apply_single(sv: np.ndarray, qubit: int, mat: np.ndarray, n: int) -> np.ndarray:
    dim = 2 ** n
    sv = sv.reshape([2] * n)
    sv = np.tensordot(mat, sv, axes=([1], [qubit]))
    # move qubit axis back to position `qubit`
    sv = np.moveaxis(sv, 0, qubit)
    return sv.reshape(dim)


def _cx(sv: np.ndarray, ctrl: int, tgt: int, n: int) -> np.ndarray:
    dim = 2 ** n
    sv = sv.reshape([2] * n)
    # Flip tgt when ctrl=1
    idx = [slice(None)] * n
    idx[ctrl] = 1
    sv_ctrl1 = sv[tuple(idx)]
    # Apply X to tgt in the ctrl=1 subspace
    sv_ctrl1 = np.flip(sv_ctrl1, axis=tgt if tgt < ctrl else tgt - 1)
    sv[tuple(idx)] = sv_ctrl1
    return sv.reshape(dim)


# ─────────────────────────────────────────────────────────────
# QPVN-QR forward pass
# ─────────────────────────────────────────────────────────────

def _unpack_params(params: np.ndarray):
    """Unpack flat parameter vector into named sub-arrays."""
    k = NUM_LAYERS * NUM_QUBITS
    alpha = params[0:k].reshape(NUM_LAYERS, NUM_QUBITS)
    beta  = params[k:2*k].reshape(NUM_LAYERS, NUM_QUBITS)
    theta = params[2*k:3*k].reshape(NUM_LAYERS, NUM_QUBITS)
    phi   = params[3*k:4*k].reshape(NUM_LAYERS, NUM_QUBITS)
    w_val = params[4*k:4*k+NUM_QUBITS]
    b_val = params[4*k+NUM_QUBITS]
    return alpha, beta, theta, phi, w_val, b_val


def forward(
    features: np.ndarray,  # shape (NUM_FEATURES,)
    params: np.ndarray,    # shape (NUM_PARAMS,)
) -> Tuple[float, np.ndarray]:
    """Run QPVN-QR forward pass.

    Returns:
        value   : float in [-1, 1]
        z_latent: np.ndarray of shape (NUM_QUBITS,) — <Z_q> expectation values
    """
    assert features.shape == (NUM_FEATURES,), f"Expected {NUM_FEATURES} features"
    assert params.shape == (NUM_PARAMS,), f"Expected {NUM_PARAMS} params"

    alpha, beta, theta, phi, w_val, b_val = _unpack_params(params)

    # Feature rotation mapping (3 layers × 14 qubits → 32 features)
    # Layer 0: f[0..13], Layer 1: f[14..27], Layer 2: f[0..13] (reinforcement)
    feature_rot = [
        [features[q % NUM_FEATURES] for q in range(NUM_QUBITS)],
        [features[(NUM_QUBITS + q) % NUM_FEATURES] for q in range(NUM_QUBITS)],
        [features[q % NUM_FEATURES] for q in range(NUM_QUBITS)],
    ]

    # Initialize |0...0>
    sv = np.zeros(2 ** NUM_QUBITS, dtype=np.complex128)
    sv[0] = 1.0

    for l in range(NUM_LAYERS):
        for q in range(NUM_QUBITS):
            # Data encoding: RY(α · f · π + β)
            enc_angle = float(alpha[l, q]) * float(feature_rot[l][q]) * np.pi + float(beta[l, q])
            sv = _ry(sv, q, enc_angle, NUM_QUBITS)
            # Variational rotation
            sv = _ry(sv, q, float(theta[l, q]), NUM_QUBITS)
            sv = _rz(sv, q, float(phi[l, q]), NUM_QUBITS)
        sv = _entangle_layer_numpy(sv)

    # Compute <Z_q> = P(|1>) - P(|0>) for each qubit
    probs = np.abs(sv) ** 2
    z_exp = np.zeros(NUM_QUBITS)
    for q in range(NUM_QUBITS):
        # Sum probabilities where qubit q = 1
        idx = np.arange(2 ** NUM_QUBITS)
        mask = ((idx >> (NUM_QUBITS - 1 - q)) & 1).astype(bool)
        p1 = float(probs[mask].sum())
        p0 = 1.0 - p1
        z_exp[q] = p1 - p0  # in [-1, 1]

    value = float(np.tanh(np.dot(w_val, z_exp) + b_val))
    return value, z_exp


# ─────────────────────────────────────────────────────────────
# Evaluator class
# ─────────────────────────────────────────────────────────────

class QPVNEvaluatorQR:
    """QPVN-QR evaluator for Q-Reversi.

    Wraps forward() with parameter loading, caching, and a clean interface.
    """

    def __init__(
        self,
        params: Optional[np.ndarray] = None,
        params_file: Optional[str] = None,
        seed: int = 42,
        cache_size: int = 4096,
    ):
        if params is not None:
            self.params = np.array(params, dtype=np.float64)
        elif params_file is not None:
            self.params = self._load_params(params_file)
        else:
            self.params = self._default_params(seed)

        assert self.params.shape == (NUM_PARAMS,), \
            f"Expected {NUM_PARAMS} params, got {self.params.shape}"

        self._cache: dict = {}
        self._cache_size = cache_size
        self._hits = self._misses = 0

    @staticmethod
    def _load_params(path: str) -> np.ndarray:
        with open(path) as f:
            data = json.load(f)
        return np.array(data["params"], dtype=np.float64)

    @staticmethod
    def _default_params(seed: int = 42) -> np.ndarray:
        """DRQ-style initialization: α=1, β=0, ry/rz=small, w=small signed."""
        rng = np.random.RandomState(seed)
        k = NUM_LAYERS * NUM_QUBITS
        alpha = np.ones(k)
        beta  = np.zeros(k)
        theta = rng.uniform(-np.pi, np.pi, k)
        phi   = rng.uniform(-np.pi, np.pi, k)
        w_val = rng.uniform(-0.05, 0.05, NUM_QUBITS)
        b_val = np.array([0.0])
        return np.concatenate([alpha, beta, theta, phi, w_val, b_val])

    def save_params(self, path: str) -> None:
        with open(path, "w") as f:
            json.dump({"params": self.params.tolist(), "num_qubits": NUM_QUBITS}, f, indent=2)

    def evaluate(self, features: np.ndarray) -> float:
        """Return value in [-1, 1]."""
        key = features.tobytes()
        if key in self._cache:
            self._hits += 1
            return self._cache[key][0]
        self._misses += 1
        value, z = forward(features, self.params)
        self._update_cache(key, (value, z))
        return value

    def get_latent(self, features: np.ndarray) -> np.ndarray:
        """Return z_latent of shape (NUM_QUBITS,)."""
        key = features.tobytes()
        if key in self._cache:
            self._hits += 1
            return self._cache[key][1]
        self._misses += 1
        value, z = forward(features, self.params)
        self._update_cache(key, (value, z))
        return z

    def evaluate_with_latent(self, features: np.ndarray) -> Tuple[float, np.ndarray]:
        key = features.tobytes()
        if key in self._cache:
            self._hits += 1
            return self._cache[key]
        self._misses += 1
        result = forward(features, self.params)
        self._update_cache(key, result)
        return result

    def _update_cache(self, key: bytes, value) -> None:
        if self._cache_size <= 0:
            return
        if len(self._cache) >= self._cache_size:
            self._cache.pop(next(iter(self._cache)))
        self._cache[key] = value

    def clear_cache(self) -> None:
        self._cache.clear()
        self._hits = self._misses = 0

    @property
    def cache_hit_rate(self) -> float:
        total = self._hits + self._misses
        return self._hits / total if total > 0 else 0.0


# ─────────────────────────────────────────────────────────────
# Sanity check
# ─────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import time

    print(f"NUM_FEATURES = {NUM_FEATURES}")
    print(f"NUM_QUBITS   = {NUM_QUBITS}")
    print(f"NUM_LAYERS   = {NUM_LAYERS}")
    print(f"NUM_PARAMS   = {NUM_PARAMS}")

    rng = np.random.RandomState(0)
    features = rng.uniform(-1, 1, NUM_FEATURES).astype(np.float32)
    ev = QPVNEvaluatorQR(seed=0)

    t0 = time.perf_counter()
    value, z = ev.evaluate_with_latent(features)
    t1 = time.perf_counter()

    print(f"\nForward pass: {(t1-t0)*1000:.1f} ms")
    print(f"Value  : {value:.4f}")
    print(f"z_latent std: {z.std():.4f}  (>0.05 means circuit is expressive)")
    print(f"z_latent: {z.round(3)}")

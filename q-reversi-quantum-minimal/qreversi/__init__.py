"""Q-Reversi Python game engine.

This package replicates the Flutter q-reversi-app game logic in Python,
enabling training and inference of the QAZ-QR quantum AI.
"""
from .types import PieceType, GateType, PlayerColor, AIDifficulty, ForbiddenAreaType
from .game_state import Piece, Board, Player, ForbiddenArea, EntangledPair, GameState
from .gate_service import GateService
from .game_service import GameService
from .measurement import MeasurementService

__all__ = [
    "PieceType", "GateType", "PlayerColor", "AIDifficulty", "ForbiddenAreaType",
    "Piece", "Board", "Player", "ForbiddenArea", "EntangledPair", "GameState",
    "GateService", "GameService", "MeasurementService",
]

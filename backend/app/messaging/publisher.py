"""Downstream interface; replace this adapter with a queue/event publisher later."""
from typing import Protocol
from app.schemas.models import FindingsMessage
class FindingsConsumer(Protocol):
    def publish(self, message: FindingsMessage) -> None: ...
class JsonSerializer:
    def serialize(self, message: FindingsMessage) -> str: return message.model_dump_json()
class NoopPublisher:
    """Explicit MVP endpoint that preserves the message without external infrastructure."""
    def __init__(self): self.last_message: FindingsMessage|None=None
    def publish(self,message:FindingsMessage)->None: self.last_message=message

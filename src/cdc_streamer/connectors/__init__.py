"""Connector implementations for CDC Streamer."""

from abc import ABC, abstractmethod


class BaseConnector(ABC):
	"""Base class for all connectors."""

	@abstractmethod
	def execute(self, *args, **kwargs):
		"""Execute a query against the data source."""
		return NotImplementedError("Subclasses must implement this method.")
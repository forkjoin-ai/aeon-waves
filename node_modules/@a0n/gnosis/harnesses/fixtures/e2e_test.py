"""End-to-end test fixture for gnode polyglot execution."""


def add(a, b):
    """Add two numbers."""
    return a + b


def fibonacci(n):
    """Compute the nth Fibonacci number."""
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b


def transform(data):
    """Transform input data."""
    if isinstance(data, dict):
        return {k: v * 2 if isinstance(v, (int, float)) else v for k, v in data.items()}
    return data


def main():
    """Main entry point -- returns a summary of all computations."""
    return {
        "add_result": add(3, 4),
        "fib_10": fibonacci(10),
        "transformed": transform({"x": 5, "y": 10, "name": "test"}),
    }

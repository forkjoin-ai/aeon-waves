"""Typed Python pipeline for signature extraction and compose testing."""


def parse_input(raw_data: str, delimiter: str = ",") -> list[dict]:
    """Parse raw CSV-like data into records."""
    lines = raw_data.strip().split("\n")
    headers = lines[0].split(delimiter)
    records = []
    for line in lines[1:]:
        values = line.split(delimiter)
        records.append(dict(zip(headers, values)))
    return records


async def fetch_remote(url: str, timeout: float = 30.0) -> dict:
    """Fetch data from a remote URL."""
    import aiohttp
    async with aiohttp.ClientSession() as session:
        async with session.get(url, timeout=timeout) as response:
            return await response.json()


def transform(records: list[dict], *filters, threshold: int = 0) -> list[dict]:
    """Filter and transform records."""
    result = [r for r in records if int(r.get("value", 0)) > threshold]
    return result


def summarize(records: list[dict]) -> dict:
    """Produce summary statistics."""
    count = len(records)
    total = sum(int(r.get("value", 0)) for r in records)
    return {"count": count, "total": total, "mean": total / max(count, 1)}

# Bug: file handle leak -- opened without context manager, no close.
def read_config(path):
    f = open(path, "r")
    data = f.read()
    # BUG: f.close() never called
    return data

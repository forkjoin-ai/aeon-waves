# Bug: file handle leak -- opened without block form.
def read_config(path)
  f = File.open(path, "r")
  data = f.read
  # BUG: f.close never called
  data
end

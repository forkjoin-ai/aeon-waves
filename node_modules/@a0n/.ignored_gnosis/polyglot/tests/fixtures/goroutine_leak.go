package main

// Bug: goroutine leak -- spawned goroutine never joined.
func startWorker(data []byte) {
    go processAsync(data)
    // BUG: no WaitGroup, no channel, no join -- goroutine leak
}

func processAsync(data []byte) {
    for _, b := range data {
        transform(b)
    }
}

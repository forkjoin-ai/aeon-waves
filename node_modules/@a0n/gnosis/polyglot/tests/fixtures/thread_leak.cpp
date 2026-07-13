// Bug: thread leak -- spawned without join.
#include <thread>
#include <vector>

void process_batch(std::vector<int>& data) {
    for (int i = 0; i < 4; i++) {
        std::thread(
            [&data, i]() { data[i] *= 2; }
        );
        // BUG: thread handle dropped, never joined
    }
}

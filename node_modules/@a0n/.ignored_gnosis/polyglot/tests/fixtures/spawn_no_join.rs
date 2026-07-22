use std::thread;

// Bug: spawned thread handle dropped -- never joined.
fn process_data(data: Vec<u8>) {
    let _handle = thread::spawn(move || {
        for byte in data {
            transform(byte);
        }
    });
    // BUG: JoinHandle dropped, thread never joined
}

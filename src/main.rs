use prost::Message;

pub mod hello {
    include!(concat!(env!("OUT_DIR"), "/hello.rs"));
}

use hello::Person;

fn main() {
    // Create a new Person
    let person = Person {
        name: "Alice".to_string(),
        age: 30,
        email: "alice@example.com".to_string(),
    };

    println!("Original person: {person:?}");

    // Serialize to bytes
    let encoded = person.encode_to_vec();
    println!("Encoded bytes: {encoded:?}");

    // Deserialize from bytes
    let decoded = Person::decode(encoded.as_slice()).expect("Failed to decode");
    println!("Decoded person: {decoded:?}");

    println!("\nHello, {}!", decoded.name);
}

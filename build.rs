fn main() -> Result<(), Box<dyn std::error::Error>> {
    prost_build::compile_protos(&["proto-fixed/proto/person.proto"], &["proto-fixed/proto/"])?;
    Ok(())
}

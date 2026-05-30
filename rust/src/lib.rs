use std::{path::Path, sync::{LazyLock, OnceLock}};

use flexi_logger::{opt_format, Age, Cleanup, Criterion, FileSpec, Logger, Naming, WriteMode};
use tokio::runtime::Runtime;
use log::info;


uniffi::setup_scaffolding!();

pub static RUNTIME: LazyLock<tokio::runtime::Runtime> = LazyLock::new(|| {
    info!("creating runner");
    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(1)
        .thread_name("tokio-rustpush")
        .enable_all()
        .build().unwrap()
});

pub mod bbhwinfo {
    include!(concat!(env!("OUT_DIR"), "/bbhwinfo.rs"));
}

pub fn init_logger(path: &Path) {
    #[cfg(target_os = "android")]
    let system = android_logger::AndroidLogger::new(
        android_logger::Config::default().with_max_level(log::LevelFilter::Debug),
    );
    #[cfg(not(target_os = "android"))]
    let system = {
        if let Err(_) = std::env::var("RUST_LOG") {
            std::env::set_var("RUST_LOG", "debug");
        }
        pretty_env_logger::formatted_builder()
            .build()
    };

    println!("here??");
    
    let (logger, _) = Logger::try_with_str("debug").expect("No logger?")
        .log_to_file(FileSpec::default().directory(path.join("logs")).suppress_timestamp())
        .append()
        .format(opt_format)
        .cleanup_in_background_thread(false)
        .rotate(Criterion::AgeOrSize(Age::Day, 1024 * 1024 * 10 /* 10 MB */), Naming::Numbers, Cleanup::KeepLogFiles(1))
        .write_mode(WriteMode::BufferAndFlush)
        .build().unwrap();
    
    multi_log::MultiLogger::init(vec![Box::new(system), logger], log::Level::Trace).expect("No init?");
}

mod native;
pub mod api;
mod keystore;
mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
pub mod flathub_host;

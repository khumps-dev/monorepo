use anyhow::anyhow;
use anyhow::Result;
use clap::Parser;
use clap::Subcommand;
use std::io::Write;
use std::process::Command;
use std::process::Stdio;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[clap(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    Operator,
}

fn main() -> Result<()> {
    let args = Args::parse();
    let crd_bundle = include_bytes!("../../external/prometheus_crds/file/downloaded");

    match args.command {
        Commands::Operator => deploy_kube_manifest(crd_bundle),
    }
}

fn deploy_kube_manifest(manifest_data: &[u8]) -> Result<()> {
    let mut child = Command::new("kubectl")
        .args([
            "apply",
            "--force-conflicts=true",
            "--server-side",
            "-f",
            "-",
        ])
        .stdin(Stdio::piped())
        .spawn()?;
    child.stdin.take().unwrap().write_all(manifest_data)?;
    match child.wait()?.success() {
        true => Ok(()),
        false => Err(anyhow!("failed to deploy operator")),
    }
}

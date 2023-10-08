use anyhow::{anyhow, Context, Result};
use clap::{Parser, Subcommand};
use futures::future::join_all;
use serde::{Deserialize, Serialize};
use std::{
    fmt::{self, Display},
    net::IpAddr,
    process::Stdio,
    str::FromStr,
    time::Duration,
};
use tokio::process::Command;

#[derive(Debug, Deserialize, Serialize)]
struct K8sConfig {
    microk8s_version: Microk8sVersion,
    singularity_node: Vec<SingularityNode>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
struct SingularityNode {
    name: String,
    ip_address: IpAddr,
    #[serde(default)]
    ignore_firmware: bool,
}

#[derive(Parser)]
struct Args {
    #[clap(subcommand)]
    target: CommandTarget,
}

#[derive(Subcommand)]
enum CommandTarget {
    Converge {},
    UpdatePackages {},
    UpdateK8s { node_name: String },
}

impl fmt::Display for SingularityNode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&format!(
            "[name: {} | ip_address: {}]",
            self.name, self.ip_address
        ))
    }
}

#[derive(Debug, Deserialize, PartialEq, PartialOrd, Serialize)]
enum Microk8sVersion {
    #[serde(rename = "1.27/stable")]
    V1_27Stable,
    #[serde(rename = "1.28/stable")]
    V1_28Stable,
}

impl FromStr for Microk8sVersion {
    type Err = anyhow::Error;

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> {
        match s.trim() {
            "1.27/stable" => Ok(Self::V1_27Stable),
            "1.28/stable" => Ok(Self::V1_28Stable),
            unexpected => Err(anyhow!("Can't parse {unexpected} as Microk8sVersion")),
        }
    }
}

impl Display for Microk8sVersion {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(match self {
            Microk8sVersion::V1_27Stable => "1.27/stable",
            Microk8sVersion::V1_28Stable => "1.28/stable",
        })
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    let k8s_config = include_str!("../../config/kubernetes/nodes.toml");
    let k8s_config: K8sConfig = toml::from_str(k8s_config)?;

    match args.target {
        CommandTarget::Converge {} => cli_converge(&k8s_config).await,
        CommandTarget::UpdatePackages {} => cli_update_package(&k8s_config).await,
        CommandTarget::UpdateK8s { node_name } => cli_update_k8s(&k8s_config, &node_name).await,
    }
}

fn new_ssh_command(node: &SingularityNode) -> Command {
    let mut cmd = Command::new("ssh");
    cmd.args(["-o", "StrictHostKeyChecking=accept-new"])
        .args(["-o", "BatchMode=yes"])
        .args(["-o", "ConnectTimeout=5"])
        .arg(format!("kevin@{}", node.ip_address));
    cmd
}

async fn verify_nodes(config: &K8sConfig) -> Result<()> {
    println!("Verifying all nodes...");

    let verify_node_handles = config.singularity_node.iter().cloned().map(|node| {
        tokio::spawn(async move {
            if !node_is_healthy(&node).await? {
                return Err(anyhow!("{node} is not healthy"));
            }
            println!("{node} is healthy");
            Ok(())
        })
    });

    let verify_node_responses = join_all(verify_node_handles).await;

    for verify_response in verify_node_responses {
        verify_response??;
    }
    Ok(())
}

async fn node_is_healthy(node: &SingularityNode) -> Result<bool> {
    Ok(can_reach_internet(node)
        .await
        .context("node can_reach_internet")?
        && dns_works(node).await.context("node dns_works")?)
}

async fn can_reach_internet(node: &SingularityNode) -> Result<bool> {
    can_ping(node, "1.1.1.1").await
}

async fn dns_works(node: &SingularityNode) -> Result<bool> {
    can_ping(node, "www.google.com").await
}

async fn can_ping(node: &SingularityNode, host_to_ping: &str) -> Result<bool> {
    let ping_output = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec!["ping", "-c", "5", host_to_ping])
        .output()
        .await?;
    Ok(ping_output.status.success())
}

async fn drain_node(node: &SingularityNode) -> Result<()> {
    println!("Draining {node}");

    let drain_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec![
            "microk8s",
            "kubectl",
            "drain",
            "--ignore-daemonsets",
            "--delete-emptydir-data",
            "--timeout=5m",
            &node.name,
        ])
        .output()
        .await?;

    match drain_cmd.status.success() {
        true => {
            println!("{node} | Drain succeeded.");
            Ok(())
        }
        false => {
            let err_msg = String::from_utf8(drain_cmd.stderr)?;
            let err_msg = err_msg.trim();
            println!("Error: {err_msg}");
            if err_msg == "microk8s is not running, try microk8s start" {
                println!("{node} | Node already drained");
                Ok(())
            } else {
                Err(anyhow!("{node} | Error, drain never completed."))
            }
        }
    }
}

async fn undrain_node(node: &SingularityNode) -> Result<()> {
    let mut undrain_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec!["microk8s", "kubectl", "uncordon", &node.name])
        .spawn()?;

    let undrain_status = undrain_cmd.wait().await?;

    if undrain_status.success() {
        println!("{node} | Undrain succeeded.");
        Ok(())
    } else {
        match undrain_status.code() {
            Some(code) => Err(anyhow!("{node} | Error, undrain exited with code {code}.")),
            None => Err(anyhow!("{node} | Error, undrain never completed.")),
        }
    }
}

async fn stop_microk8s(node: &SingularityNode) -> Result<()> {
    let mut stop_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec!["sudo", "microk8s", "stop"])
        .spawn()?;

    let stop_status = stop_cmd.wait().await?;

    if stop_status.success() {
        println!("{node} | Stopping microk8s succeeded.");
        Ok(())
    } else {
        match stop_status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, stopping microk8s exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, stopping microk8s never completed."
            )),
        }
    }
}

async fn start_microk8s(node: &SingularityNode) -> Result<()> {
    let mut start_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec!["sudo", "microk8s", "start"])
        .spawn()?;

    let start_status = start_cmd.wait().await?;

    if start_status.success() {
        println!("{node} | Starting microk8s succeeded.");
        Ok(())
    } else {
        match start_status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, starting microk8s exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, starting microk8s never completed."
            )),
        }
    }
}

async fn upgrade_packages(node: &SingularityNode) -> Result<()> {
    let upgrade_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec![
            "sudo", "apt-get", "update", "&&", "sudo", "apt-get", "upgrade", "-y",
        ])
        .output()
        .await?;

    if upgrade_cmd.status.success() {
        println!("{node} | Upgrading packages succeeded.");
        Ok(())
    } else {
        match upgrade_cmd.status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, upgrading packages exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, upgrading packages never completed."
            )),
        }
    }
}

async fn upgrade_firmware(node: &SingularityNode) -> Result<()> {
    if node.ignore_firmware {
        println!("This node skips firmware upgrades.");
        return Ok(());
    }

    let upgrade_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec![
            "sudo",
            "fwupdmgr",
            "update",
            "-y",
            "--offline",
            "--no-reboot-check",
        ])
        .output()
        .await?;

    if upgrade_cmd.status.success() {
        println!("{node} | Firmware update scheduled for next reboot.");
        Ok(())
    } else {
        match upgrade_cmd.status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, firmware upgrade schedling exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, firmware upgrade schedling never completed."
            )),
        }
    }
}

async fn get_microk8s_train(node: &SingularityNode) -> Result<Microk8sVersion> {
    String::from_utf8(
        new_ssh_command(node)
            .args([
                "snap",
                "info",
                "microk8s",
                "|",
                "grep",
                "tracking",
                "|",
                "grep",
                "-oP",
                "'\\d+\\.\\d+/\\S+'",
            ])
            .output()
            .await?
            .stdout,
    )?
    .parse()
}

async fn upgrade_microk8s(node: &SingularityNode, version: &Microk8sVersion) -> Result<()> {
    let mut upgrade_cmd = new_ssh_command(node)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .args(vec![
            "sudo",
            "snap",
            "refresh",
            "microk8s",
            "--channel",
            &version.to_string(),
        ])
        .spawn()?;

    let upgrade_status = upgrade_cmd.wait().await?;

    if upgrade_status.success() {
        println!("{node} | Upgrading microk8s succeeded.");
        Ok(())
    } else {
        match upgrade_status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, upgrading microk8s exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, upgrading microk8s never completed."
            )),
        }
    }
}

async fn reboot_node(node: &SingularityNode) -> Result<()> {
    let reboot_output = new_ssh_command(node)
        .args(vec!["sudo", "shutdown", "-r", "now"])
        .stdout(Stdio::null())
        .spawn()
        .context("sending reboot command")?;

    println!("reboot executed");
    Ok(())
}

async fn test_pingable(node: &SingularityNode) -> Result<()> {
    Command::new("ping")
        .args(vec!["-c", "1", &node.ip_address.to_string()])
        .output()
        .await?;
    Ok(())
}

async fn wait_for_reboot(node: &SingularityNode) -> Result<()> {
    println!("Waiting for {node} to reboot");
    tokio::time::sleep(Duration::from_secs(20)).await;
    {
        println!("Waiting for {node} to be accepting ssh connections");

        for i in 1..=20 {
            match new_ssh_command(node)
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .arg("whoami")
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .output()
                .await
            {
                Ok(output) if output.status.success() => {
                    println!("{node} is responding to ssh. Continuing.");
                    break;
                }
                Ok(_) | Err(_) => {
                    println!("[{i}/20] {node} is not responding to ssh. Waiting to retry.")
                }
            }

            tokio::time::sleep(Duration::from_secs(10)).await;
        }
    }
    println!("{node} has rebooted");
    Ok(())
}

async fn wait_for_node_ready(node: &SingularityNode) -> Result<()> {
    println!("Waiting for {node} to be in a k8s ready state");
    let max_tries = 20;

    for i in 1..=max_tries {
        match new_ssh_command(node)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .args([
                "microk8s",
                "kubectl",
                "get",
                "nodes",
                &format!(
                    "{} -o jsonpath='{{$.status.conditions[?(@.reason==\"KubeletReady\")].status}}'",
                    node.name
                ),
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .output()
            .await
        {
            Ok(output) if output.status.success() => {
                let out = String::from_utf8(output.stdout)?;
                if out == "True" {
                    println!("[{i}/{max_tries}] {node} is ready. Continuing.");
                    return Ok(());
                } else {
                    println!("{out} is not ready");
                }
            }
            Ok(_) | Err(_)=> {}
        }
        println!("[{i}/{max_tries}] {node} is not ready. Waiting to retry.");

        tokio::time::sleep(Duration::from_secs(10)).await;
    }

    Err(anyhow!("Node never became ready"))
}

async fn cli_converge(k8s_config: &K8sConfig) -> Result<()> {
    verify_nodes(&k8s_config).await?;
    for node in &k8s_config.singularity_node {
        handle_node_upgrade(node, &k8s_config.microk8s_version).await?;
    }
    Ok(())
}

async fn cli_update_package(k8s_config: &K8sConfig) -> Result<()> {
    for node in &k8s_config.singularity_node {
        upgrade_packages(node).await?;
    }
    Ok(())
}

async fn cli_update_k8s(k8s_config: &K8sConfig, node_name: &str) -> Result<()> {
    match k8s_config
        .singularity_node
        .iter()
        .find(|node| node.name == node_name)
    {
        Some(node) => {
            verify_nodes(&k8s_config).await?;
            let current_version = get_microk8s_train(node).await?;
            println!("Current Version: {current_version}");
            if current_version == k8s_config.microk8s_version {
                println!("Version is already {current_version}, skipping");
                Ok(())
            } else {
                drain_node(node).await?;
                stop_microk8s(node).await?;
                upgrade_microk8s(node, &k8s_config.microk8s_version).await?;
                start_microk8s(node).await?;
                wait_for_node_ready(node).await?;
                undrain_node(node).await
            }
        }
        None => Err(anyhow!("{node_name} is not a valid node")),
    }
}

async fn handle_node_upgrade(
    node: &SingularityNode,
    target_version: &Microk8sVersion,
) -> Result<()> {
    upgrade_packages(&node).await?;
    drain_node(node).await?;
    stop_microk8s(node).await?;
    upgrade_microk8s(node, target_version).await?;
    upgrade_firmware(node).await?;
    reboot_node(node).await?;
    wait_for_reboot(node).await?;
    start_microk8s(node).await?;
    wait_for_node_ready(node).await?;
    undrain_node(node).await?;
    Ok(())
}

#[cfg(feature = "hw_test")]
#[tokio::test]
#[serial_test::serial]
async fn test_drain_undrain() {
    let singularity001 = get_test_node();

    {
        println!("Testing drain on {singularity001}");

        drain_node(&singularity001)
            .await
            .expect("draining {singularity001}")
    }

    {
        println!("Testing undrain on {singularity001}");
        undrain_node(&singularity001)
            .await
            .expect("undraining {singularity001}")
    }
}

#[cfg(feature = "hw_test")]
#[tokio::test]
#[serial_test::serial]
async fn test_wait_for_reboot() {
    let test_node = get_test_node();

    wait_for_reboot(&test_node)
        .await
        .expect("waiting for reboot")
}

// #[tokio::test]
// async fn test_execute_node_upgrade() {
//     let test_node = get_test_node();

//     handle_node_upgrade(&test_node,)
//         .await
//         .expect("waiting for node upgrade");
// }

#[cfg(feature = "hw_test")]
#[tokio::test]
#[serial_test::serial]
async fn test_get_microk8s_version() {
    let test_node = get_test_node();

    let version = get_microk8s_train(&test_node)
        .await
        .expect("getting microk8s version");
    println!("Version: {version}");
}

#[cfg(feature = "hw_test")]
fn get_test_node() -> SingularityNode {
    SingularityNode {
        name: "singularity001".to_string(),
        ip_address: "192.168.60.11"
            .parse()
            .expect("serializing singularity001 ip address"),
        ignore_firmware: true,
    }
}

use anyhow::{anyhow, Context, Ok, Result};
use futures::future::join_all;
use serde::{Deserialize, Serialize};
use std::{
    fmt::{self, Display},
    net::IpAddr,
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
}

impl fmt::Display for SingularityNode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&format!(
            "[name: {} | ip_address: {}]",
            self.name, self.ip_address
        ))
    }
}

#[derive(Debug, Deserialize, Serialize)]
enum Microk8sVersion {
    V1_27Stable,
    V1_28Stable,
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
    let k8s_config = include_str!("../../config/kubernetes/nodes.toml");
    let k8s_config: K8sConfig = toml::from_str(k8s_config)?;

    verify_nodes(k8s_config).await?;
    Ok(())
}

fn new_ssh_command(node: &SingularityNode) -> Command {
    let mut cmd = Command::new("ssh");
    cmd.args(["-o", "StrictHostKeyChecking=accept-new"])
        .args(["-o", "BatchMode=yes"])
        .args(["-o", "ConnectTimeout=5"])
        .arg(format!("kevin@{}", node.ip_address));
    cmd
}

async fn verify_nodes(config: K8sConfig) -> Result<()> {
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
        .args(vec!["ping", "-c", "5", host_to_ping])
        .output()
        .await?;
    Ok(ping_output.status.success())
}

async fn drain_node(node: &SingularityNode) -> Result<()> {
    let mut drain_cmd = new_ssh_command(node)
        .args(vec![
            "microk8s",
            "kubectl",
            "drain",
            "--ignore-daemonsets",
            "--delete-emptydir-data",
            &node.name,
        ])
        .spawn()?;

    let drain_status = drain_cmd.wait().await?;

    if drain_status.success() {
        println!("{node} | Drain succeeded.");
        Ok(())
    } else {
        match drain_status.code() {
            Some(code) => Err(anyhow!("{node} | Error, drain exited with code {code}.")),
            None => Err(anyhow!("{node} | Error, drain never completed.")),
        }
    }
}

async fn undrain_node(node: &SingularityNode) -> Result<()> {
    let mut undrain_cmd = new_ssh_command(node)
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
    let mut upgrade_cmd = new_ssh_command(node)
        .args(vec![
            "sudo", "apt", "update", "&&", "sudo", "apt", "upgrade", "-y",
        ])
        .spawn()?;

    let upgrade_status = upgrade_cmd.wait().await?;

    if upgrade_status.success() {
        println!("{node} | Upgrading packages succeeded.");
        Ok(())
    } else {
        match upgrade_status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, upgrading packages exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, upgrading packages never completed."
            )),
        }
    }
}

async fn upgrade_microk8s(node: &SingularityNode, version: &Microk8sVersion) -> Result<()> {
    let mut upgrade_cmd = new_ssh_command(node)
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
        println!("{node} | Upgrading packages succeeded.");
        Ok(())
    } else {
        match upgrade_status.code() {
            Some(code) => Err(anyhow!(
                "{node} | Error, upgrading packages exited with code {code}."
            )),
            None => Err(anyhow!(
                "{node} | Error, upgrading packages never completed."
            )),
        }
    }
}

async fn reboot_node(node: &SingularityNode) -> Result<()> {
    let mut reboot_output = new_ssh_command(node)
        .args(vec!["sudo", "reboot", "now"])
        .output()
        .await?;

    if reboot_output.status.success() {
        println!("{node} | Reboot initiated.");
    } else {
        match reboot_output.status.code() {
            Some(code) => return Err(anyhow!("{node} | Reboot command exited with code {code}.")),
            None => return Err(anyhow!("{node} | Error, reboot command never completed.")),
        }
    }

    wait_for_reboot(node).await
}

async fn wait_for_reboot(node: &SingularityNode) -> Result<()> {
    {
        let max_ping_attempts = 20;

        println!("Waiting for {node} to be pingable.");

        for i in 1..=max_ping_attempts {
            let test = Command::new("ping")
                .args(vec!["-c", "1", &node.ip_address.to_string()])
                .output()
                .await;
            // match Command::new("ping")
            //     .args(vec!["-c", "1", &node.ip_address.to_string()])
            //     .output()
            //     .await
            match test {
                Ok(_) => println!("{node} is pingable. Continuing"),
                Err(_) => println!("{node} is not responding to ping. Waiting to retry."),
            }
        }
    }

    {
        let max_ssh_attempts = 20;

        println!("Waiting for {node} to be accepting ssh connections");

        for i in 1..=max_ssh_attempts {
            // match new_ssh_command(node).arg("whoami").output().await {
            //     Ok(_) => println!("{node} is responding to ssh. Continuing."),
            //     Err(_) => println!("{node} is not responding to ssh. Waiting to retry."),
            // }

            tokio::time::sleep(Duration::from_secs(10)).await;
        }
    }

    Ok(())
}

#[tokio::test]
async fn test_drain_undrain() {
    let singularity001 = SingularityNode {
        name: "singularity001".to_string(),
        ip_address: "192.168.60.11"
            .parse()
            .expect("serializing singularity001 ip address"),
    };

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

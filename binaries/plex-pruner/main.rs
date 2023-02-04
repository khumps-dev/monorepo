use std::env;

use anyhow::{anyhow, Context, Result};
use reqwest::blocking::Client;
use serde::{Deserialize, Serialize};
use serde_json::Value;

fn main() -> Result<()> {
    let client = Client::new();
    let plexpy_user = env::var("PLEXPY_USER").context("PLEXPY_USER not set")?;
    let plexpy_pass = env::var("PLEXPY_PASS").context("PLEXPY_PASS not set")?;
    let plexpy_api_key = env::var("PLEXPY_API_KEY").context("PLEXPY_API_KEY not set")?;
    let plexpy_url = format!("https://plexpy.khumps.dev");
    println!(
        "{:?}",
        get_unwatched_media(
            &client,
            plexpy_url,
            plexpy_user,
            plexpy_pass,
            plexpy_api_key
        )?
    );
    Ok(())
}

#[derive(Debug, Deserialize, Serialize)]
struct LibraryMediaRecord {
    section_id: u32,
    section_type: MediaType,
    added_at: String,
    last_played: Option<u32>,
    play_count: Option<u32>,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
enum MediaType {
    Tv,
    Movie,
}
fn get_unwatched_media(
    client: &Client,
    plexpy_url: String,
    user: String,
    pass: String,
    api_key: String,
) -> Result<Vec<LibraryMediaRecord>> {
    let resp = client
        .get(format!("{plexpy_url}/api/v2"))
        .basic_auth(user, Some(pass))
        .query(&[
            ("apikey", api_key),
            ("cmd", "get_library_media_info".to_string()),
            ("section_id", 2.to_string()),
            ("order_column", "last_played".to_string()),
            ("order_dir", "asc".to_string()),
            ("length", 10000.to_string()),
        ])
        .send()?;
    let text = resp.text()?;
    // println!("resp: {text:?}");
    let mut parsed = serde_json::from_str::<Value>(&text)?;
    let items = parsed
        .get_mut("response")
        .ok_or(anyhow!("no response object in json"))?
        .get_mut("data")
        .ok_or(anyhow!("no data array in json"))?
        .get_mut("data")
        .ok_or(anyhow!("no data array in json"))?;
    let items = items.take();
    // println!("{items:?}");
    Ok(serde_json::from_value::<Vec<LibraryMediaRecord>>(items)?)
}

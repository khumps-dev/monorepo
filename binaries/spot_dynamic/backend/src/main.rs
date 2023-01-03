use oauth2::reqwest::http_client;
use oauth2::TokenResponse;
use oauth2::{basic::BasicClient, AuthUrl, ClientId, ClientSecret, TokenUrl};
use reqwest::blocking;
use std::env;

fn main() {
    let client_id =
        ClientId::new(env::var("SPOTIFY_CLIENT_ID").expect("SPOTIFY_CLIENT_ID must be set"));
    let client_secret = ClientSecret::new(
        env::var("SPOTIFY_CLIENT_SECRET").expect("SPOTIFY_CLIENT_SECRET must be set"),
    );

    let auth_url =
        AuthUrl::new(format!("https://unused.url")).expect("Invalid authorization endpoint URL");
    let token_url = TokenUrl::new("https://accounts.spotify.com/api/token".to_string())
        .expect("Invalid token endpoint URL");

    let client = BasicClient::new(client_id, Some(client_secret), auth_url, Some(token_url));
    let token_resp = client
        .exchange_client_credentials()
        .request(http_client)
        .expect("failed to get token");
    let client = blocking::Client::new();

    let request = client
        .request(
            reqwest::Method::GET,
            "https://api.spotify.com/v1/search?type=artist&q=Queen".to_string(),
        )
        .bearer_auth(token_resp.access_token().secret());
    let resp = blocking::RequestBuilder::send(request).expect("query failed");
    println!("{}", resp.text().expect("failed to parse response"));
}

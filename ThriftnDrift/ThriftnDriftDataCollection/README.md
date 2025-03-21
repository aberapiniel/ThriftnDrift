# ThriftnDrift Data Collection Tools

This directory contains tools for collecting thrift store data using the Google Places API.

## Setup

1. Create a virtual environment and activate it:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   cd Scripts
   pip install -r requirements.txt
   ```

3. Set up Google Cloud Project:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the Places API and Maps JavaScript API
   - Create credentials (API key)
   - Restrict the API key to only Places API and Maps JavaScript API
   - Add billing information (required for Places API)

4. Configure environment variables:
   - Copy your Google API key to `Scripts/.env`

## Usage

1. Run the store collection script:
   ```bash
   cd Scripts
   python fetch_thrift_stores.py
   ```

2. The script will:
   - Search for thrift stores in configured cities across multiple states
   - Collect detailed information about each store
   - Save data to `stores.json` in the Resources directory

## Output Structure

The `stores.json` file contains:
- A root object with a `states` property
- Each state has:
  - `name`: Full state name
  - `stores`: Array of store objects with detailed information

## Adding More States and Cities

Edit the `STATES` dictionary in `fetch_thrift_stores.py` to add more states and cities. Each state entry should include:
- name: Full state name
- cities: Array of city objects, each containing:
  - name: City name
  - lat: Latitude
  - lng: Longitude
  - radius: Search radius in meters (default: 50000 for 50km)

## Notes

- The script includes rate limiting to avoid API quota issues
- Store data is saved to stores.json for use in the iOS app
- Social media links and some store details may need manual verification 
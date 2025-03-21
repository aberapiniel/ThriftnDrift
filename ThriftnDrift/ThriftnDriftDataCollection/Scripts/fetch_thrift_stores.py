#!/usr/bin/env python3
import os
import json
import time
from datetime import datetime
from typing import List, Dict, Any
from dotenv import load_dotenv
import googlemaps
from tqdm import tqdm

# Load environment variables
load_dotenv()
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
print(f"API Key loaded: {'*' * (len(GOOGLE_API_KEY) - 8) + GOOGLE_API_KEY[-8:] if GOOGLE_API_KEY else 'None'}")

# Initialize Google Maps client
gmaps = googlemaps.Client(key=GOOGLE_API_KEY)

# States and their major cities
STATES = {
    "NC": {
        "name": "North Carolina",
        "cities": [
            {
                "name": "Charlotte",
                "lat": 35.2271,
                "lng": -80.8431,
                "radius": 50000
            },
            {
                "name": "Raleigh",
                "lat": 35.7796,
                "lng": -78.6382,
                "radius": 50000
            },
            {
                "name": "Durham",
                "lat": 35.9940,
                "lng": -78.8986,
                "radius": 50000
            },
            {
                "name": "Greensboro",
                "lat": 36.0726,
                "lng": -79.7920,
                "radius": 50000
            }
        ]
    },
    "SC": {
        "name": "South Carolina",
        "cities": [
            {
                "name": "Charleston",
                "lat": 32.7765,
                "lng": -79.9311,
                "radius": 50000
            },
            {
                "name": "Columbia",
                "lat": 34.0007,
                "lng": -81.0348,
                "radius": 50000
            },
            {
                "name": "Greenville",
                "lat": 34.8526,
                "lng": -82.3940,
                "radius": 50000
            }
        ]
    },
    "GA": {
        "name": "Georgia",
        "cities": [
            {
                "name": "Atlanta",
                "lat": 33.7490,
                "lng": -84.3880,
                "radius": 50000
            },
            {
                "name": "Savannah",
                "lat": 32.0809,
                "lng": -81.0912,
                "radius": 50000
            },
            {
                "name": "Athens",
                "lat": 33.9519,
                "lng": -83.3576,
                "radius": 50000
            }
        ]
    },
    "FL": {
        "name": "Florida",
        "cities": [
            {
                "name": "Miami",
                "lat": 25.7617,
                "lng": -80.1918,
                "radius": 50000
            },
            {
                "name": "Orlando",
                "lat": 28.5383,
                "lng": -81.3792,
                "radius": 50000
            },
            {
                "name": "Tampa",
                "lat": 27.9506,
                "lng": -82.4572,
                "radius": 50000
            }
        ]
    },
    "TN": {
        "name": "Tennessee",
        "cities": [
            {
                "name": "Nashville",
                "lat": 36.1627,
                "lng": -86.7816,
                "radius": 50000
            },
            {
                "name": "Memphis",
                "lat": 35.1495,
                "lng": -90.0490,
                "radius": 50000
            },
            {
                "name": "Knoxville",
                "lat": 35.9606,
                "lng": -83.9207,
                "radius": 50000
            }
        ]
    },
    "VA": {
        "name": "Virginia",
        "cities": [
            {
                "name": "Richmond",
                "lat": 37.5407,
                "lng": -77.4360,
                "radius": 50000
            },
            {
                "name": "Virginia Beach",
                "lat": 36.8529,
                "lng": -75.9780,
                "radius": 50000
            },
            {
                "name": "Norfolk",
                "lat": 36.8508,
                "lng": -76.2859,
                "radius": 50000
            }
        ]
    }
}

def get_place_details(place_id: str) -> Dict[Any, Any]:
    """Get detailed information about a place using its place_id."""
    try:
        details = gmaps.place(
            place_id,
            fields=[
                'name', 'formatted_address', 'geometry/location', 'formatted_phone_number',
                'website', 'rating', 'user_ratings_total', 'current_opening_hours',
                'type', 'price_level'
            ]
        )
        return details.get('result', {})
    except Exception as e:
        print(f"Error fetching place details for {place_id}: {e}")
        return {}

def search_thrift_stores(city: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Search for thrift stores in a given city."""
    stores = []
    search_queries = [
        "thrift store",
        "secondhand store",
        "consignment store",
        "goodwill",
        "salvation army store"
    ]
    
    for query in search_queries:
        try:
            # Search for stores
            search_result = gmaps.places(
                query=f"{query} in {city['name']}",
                location=(city['lat'], city['lng']),
                radius=city['radius']
            )
            
            # Process results
            for place in search_result.get('results', []):
                place_id = place.get('place_id')
                if not place_id:
                    continue
                
                # Get detailed information
                details = get_place_details(place_id)
                if not details:
                    continue
                
                # Extract coordinates
                location = details.get('geometry', {}).get('location', {})
                
                store = {
                    'id': place_id,
                    'name': details.get('name', ''),
                    'description': '',  # Need to be added manually or from another source
                    'address': details.get('formatted_address', ''),
                    'latitude': location.get('lat', 0),
                    'longitude': location.get('lng', 0),
                    'phoneNumber': details.get('formatted_phone_number'),
                    'website': details.get('website', ''),
                    'rating': details.get('rating', 0),
                    'reviewCount': details.get('user_ratings_total', 0),
                    'priceRange': '$' * (details.get('price_level', 1) if details.get('price_level') else 1),
                    'categories': details.get('types', []),
                    'acceptsDonations': True,  # Default assumption for thrift stores
                    'hasClothingSection': True,  # Default assumption
                    'hasFurnitureSection': False,
                    'hasElectronicsSection': False,
                    'lastVerified': datetime.utcnow().isoformat() + 'Z',
                    'isUserSubmitted': False,
                    'verificationStatus': 'verified'
                }
                
                # Only add if not already in the list
                if not any(s['id'] == store['id'] for s in stores):
                    stores.append(store)
            
            # Handle pagination if more results are available
            while 'next_page_token' in search_result:
                time.sleep(2)  # Wait for token to be valid
                search_result = gmaps.places(
                    query=f"{query} in {city['name']}",
                    location=(city['lat'], city['lng']),
                    radius=city['radius'],
                    page_token=search_result['next_page_token']
                )
                
                # Process additional results
                for place in search_result.get('results', []):
                    place_id = place.get('place_id')
                    if not place_id or any(s['id'] == place_id for s in stores):
                        continue
                    
                    details = get_place_details(place_id)
                    if not details:
                        continue
                    
                    location = details.get('geometry', {}).get('location', {})
                    store = {
                        'id': place_id,
                        'name': details.get('name', ''),
                        'description': '',
                        'address': details.get('formatted_address', ''),
                        'latitude': location.get('lat', 0),
                        'longitude': location.get('lng', 0),
                        'phoneNumber': details.get('formatted_phone_number'),
                        'website': details.get('website', ''),
                        'rating': details.get('rating', 0),
                        'reviewCount': details.get('user_ratings_total', 0),
                        'priceRange': '$' * (details.get('price_level', 1) if details.get('price_level') else 1),
                        'categories': details.get('types', []),
                        'acceptsDonations': True,
                        'hasClothingSection': True,
                        'hasFurnitureSection': False,
                        'hasElectronicsSection': False,
                        'lastVerified': datetime.utcnow().isoformat() + 'Z',
                        'isUserSubmitted': False,
                        'verificationStatus': 'verified'
                    }
                    stores.append(store)
            
        except Exception as e:
            print(f"Error searching for {query} in {city['name']}: {e}")
    
    return stores

def fetch_stores_for_state(state_code: str, state_data: Dict[str, Any]) -> Dict[str, Any]:
    """Fetch all stores for a given state."""
    all_stores = []
    
    for city in state_data['cities']:
        print(f"Fetching stores for {city['name']}, {state_code}...")
        city_stores = search_thrift_stores(city)
        all_stores.extend(city_stores)
        print(f"Found {len(city_stores)} stores in {city['name']}")
        time.sleep(2)  # Rate limiting
    
    return {
        'name': state_data['name'],
        'stores': all_stores
    }

def test_api_key():
    """Test if the API key is working by making a simple request."""
    try:
        result = gmaps.geocode('1600 Amphitheatre Parkway, Mountain View, CA')
        print("API Key test successful!")
        return True
    except Exception as e:
        print(f"API Key test failed: {e}")
        return False

def main():
    """Main function to fetch and save thrift store data."""
    print("Testing API key...")
    if not test_api_key():
        print("API key validation failed. Please check your API key and ensure the necessary APIs are enabled.")
        return
    
    print("Initializing Google Maps client...")
    
    # Create or load existing stores.json
    output_file = '../../Resources/stores.json'
    existing_data = {'states': {}}
    
    if os.path.exists(output_file):
        try:
            with open(output_file, 'r') as f:
                existing_data = json.load(f)
        except json.JSONDecodeError:
            print("Error reading existing stores.json, starting fresh")
    
    # Fetch stores for each state
    for state_code, state_data in STATES.items():
        print(f"\nProcessing state: {state_data['name']} ({state_code})")
        state_stores = fetch_stores_for_state(state_code, state_data)
        existing_data['states'][state_code] = state_stores
        
        # Save after each state to prevent data loss
        with open(output_file, 'w') as f:
            json.dump(existing_data, f, indent=2)
        print(f"Saved data for {state_code}")
        time.sleep(5)  # Rate limiting between states
    
    print("\nStore data has been saved to stores.json")

if __name__ == "__main__":
    main() 
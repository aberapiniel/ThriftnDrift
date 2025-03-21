import os
from dotenv import load_dotenv
import googlemaps
from pprint import pprint

# Load environment variables
load_dotenv()
api_key = os.getenv('GOOGLE_API_KEY')
print(f"API Key loaded: {'*' * (len(api_key) - 8) + api_key[-8:] if api_key else 'None'}")

# Initialize the client
gmaps = googlemaps.Client(key=api_key)

# Try a simple Places API request
try:
    # Search for a place
    result = gmaps.places(
        query='coffee shop',
        location=(35.7796, -78.6382),  # Raleigh coordinates
        radius=1000
    )
    print("\nSearch successful!")
    print("\nFirst result:")
    if result.get('results'):
        pprint(result['results'][0])
    else:
        print("No results found")
except Exception as e:
    print(f"\nError: {e}") 
#!/usr/bin/env python3
import os
import json

cities = [
    # North Carolina
    "charlotte",
    "raleigh",
    "durham",
    "greensboro",
    
    # South Carolina
    "charleston",
    "columbia",
    "greenville",
    
    # Georgia
    "atlanta",
    "savannah",
    "athens",
    
    # Florida
    "miami",
    "orlando",
    "tampa",
    
    # Tennessee
    "nashville",
    "memphis",
    "knoxville",
    
    # Virginia
    "richmond",
    "virginia_beach",
    "norfolk"
]

asset_template = {
    "images": [
        {
            "filename": "{city}_skyline.jpg",
            "idiom": "universal",
            "scale": "1x"
        },
        {
            "idiom": "universal",
            "scale": "2x"
        },
        {
            "idiom": "universal",
            "scale": "3x"
        }
    ],
    "info": {
        "author": "xcode",
        "version": 1
    }
}

def create_asset_catalog():
    # Create Cities directory if it doesn't exist
    cities_dir = "Resources/Assets.xcassets/Cities"
    os.makedirs(cities_dir, exist_ok=True)
    
    # Create Contents.json for Cities directory
    with open(os.path.join(cities_dir, "Contents.json"), "w") as f:
        json.dump({
            "info": {
                "author": "xcode",
                "version": 1
            }
        }, f, indent=2)
    
    # Create imageset directory and Contents.json for each city
    for city in cities:
        city_dir = os.path.join(cities_dir, f"{city}_skyline.imageset")
        os.makedirs(city_dir, exist_ok=True)
        
        contents = asset_template.copy()
        contents["images"][0]["filename"] = f"{city}_skyline.jpg"
        
        with open(os.path.join(city_dir, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)
        
        print(f"Created asset catalog entry for {city}")

if __name__ == "__main__":
    create_asset_catalog() 
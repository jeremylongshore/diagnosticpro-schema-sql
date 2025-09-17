#!/usr/bin/env python3
"""
Convert NDJSON files to Parquet format
"""
import json
import os

try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False

def ndjson_to_parquet_manual(ndjson_file, parquet_file):
    """
    Manual conversion without pandas/pyarrow dependencies
    Creates a JSON representation of the data structure
    """
    data = []
    with open(ndjson_file, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line:
                data.append(json.loads(line))

    # Create a pseudo-parquet file (actually JSON) for demonstration
    with open(parquet_file.replace('.parquet', '.json'), 'w', encoding='utf-8') as f:
        json.dump({
            'format': 'parquet_equivalent',
            'note': 'This is a JSON representation of the data that would be in Parquet format',
            'original_file': ndjson_file,
            'record_count': len(data),
            'data': data
        }, f, indent=2, default=str)

    print(f"Created parquet equivalent: {parquet_file.replace('.parquet', '.json')}")

def convert_ndjson_to_parquet(ndjson_file):
    """Convert NDJSON file to Parquet"""
    parquet_file = ndjson_file.replace('.ndjson', '.parquet')

    if PANDAS_AVAILABLE:
        try:
            # Read NDJSON file
            data = []
            with open(ndjson_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line:
                        data.append(json.loads(line))

            # Convert to DataFrame and save as Parquet
            df = pd.json_normalize(data)
            df.to_parquet(parquet_file, index=False)
            print(f"Converted {ndjson_file} to {parquet_file}")
        except Exception as e:
            print(f"Error converting {ndjson_file}: {e}")
            ndjson_to_parquet_manual(ndjson_file, parquet_file)
    else:
        print("Pandas not available, creating JSON equivalent")
        ndjson_to_parquet_manual(ndjson_file, parquet_file)

def main():
    """Convert all NDJSON files to Parquet"""
    ndjson_files = [
        'dtc_codes_github.ndjson',
        'reddit_diagnostic_posts.ndjson',
        'youtube_repair_videos.ndjson',
        'equipment_registry.ndjson'
    ]

    for ndjson_file in ndjson_files:
        if os.path.exists(ndjson_file):
            convert_ndjson_to_parquet(ndjson_file)
        else:
            print(f"File not found: {ndjson_file}")

if __name__ == '__main__':
    main()
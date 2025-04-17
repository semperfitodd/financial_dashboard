import os
import requests
import zipfile
import tempfile
import traceback
import concurrent.futures

ZIP_FILE_URL = os.environ.get("ZIP_FILE_URL")
DEST_DIR = os.environ.get("DEST_DIR", "/s3_mount/unzipped/submissions/")
MAX_WORKERS = int(os.environ.get("MAX_WORKERS", "1"))

def extract_file(archive_path, file_name):
    try:
        with zipfile.ZipFile(archive_path, "r") as archive:
            output_path = os.path.join(DEST_DIR, file_name)
            output_dir = os.path.dirname(output_path)
            os.makedirs(output_dir, exist_ok=True)

            with archive.open(file_name) as zipped_file, open(output_path, "wb") as out_file:
                out_file.write(zipped_file.read())

        print(f"📤 {file_name}")
    except Exception as e:
        print(f"❌ Failed to extract {file_name}: {str(e)}")

def main():
    try:
        if not ZIP_FILE_URL:
            print("❌ ZIP_FILE_URL is not set.")
            raise ValueError("Missing ZIP_FILE_URL")

        print(f"🔒 ZIP_FILE_URL is set to: {ZIP_FILE_URL}")
        print(f"📂 Destination directory is: {DEST_DIR}")

        if not os.path.exists(DEST_DIR):
            print(f"📁 DEST_DIR does not exist, attempting to create: {DEST_DIR}")
            os.makedirs(DEST_DIR, exist_ok=True)

        # Test write access
        test_file = os.path.join(DEST_DIR, "write_test.tmp")
        with open(test_file, "w") as f:
            f.write("test")
        os.remove(test_file)
        print("✅ Write test to DEST_DIR succeeded.")

        # Download the zip to temp file
        print(f"🌐 Downloading ZIP from {ZIP_FILE_URL}...")
        headers = {
            "User-Agent": "Mozilla/5.0 (compatible; SEC-DataBot/1.0; +your-email@yourdomain.com)"
        }

        with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
            with requests.get(ZIP_FILE_URL, headers=headers, stream=True) as r:
                r.raise_for_status()
                for chunk in r.iter_content(chunk_size=8192):
                    if chunk:
                        tmp_file.write(chunk)
            zip_path = tmp_file.name

        print("✅ ZIP downloaded. Scanning contents...")

        with zipfile.ZipFile(zip_path, "r") as archive:
            json_files = [f for f in archive.namelist() if f.endswith(".json")]
            print(f"📦 Found {len(json_files)} JSON files. Starting extraction with {MAX_WORKERS} workers...")

        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
            executor.map(lambda f: extract_file(zip_path, f), json_files)

        print("✅ All files extracted successfully.")

    except Exception as e:
        print("❌ Exception occurred during parallel extraction:")
        traceback.print_exc()
        raise

if __name__ == "__main__":
    main()

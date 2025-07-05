# Create virtual environment (one time setup)
python3 -m venv vlc-env

# Activate it
source vlc-env/bin/activate

# Install packages
pip install keyboard requests

# Run the script
python3 vlc-global-hotkeys.py

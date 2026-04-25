
eval "$(/opt/homebrew/bin/brew shellenv)"

# --- Secret Env ---
if [ -f "$HOME/.config/secret-env" ]; then
  set -a
  source "$HOME/.config/secret-env"
  set +a
fi

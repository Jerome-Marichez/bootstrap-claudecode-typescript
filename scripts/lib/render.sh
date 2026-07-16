# shellcheck shell=bash
# render.sh — moteur de rendu des templates de bootstrap.sh.
# Sourcé par scripts/bootstrap.sh ; n'est pas exécutable seul.
# Lit les globales : NAME DESC OWNER FRAMEWORK_LABEL NODE_VERSION BIOME_VERSION
#                    BIOME_SCHEMA_VERSION VERSION_FILE KEYS

# Échappe une valeur pour le remplacement d'un s/// de sed.
# Les retours à la ligne sont aplatis en amont (cf. validate_args).
esc() { printf '%s' "$1" | sed 's/[&/\]/\\&/g'; }

# Copie un template en substituant les tokens puis en filtrant les blocs only.
render() { # render <src> <dst>
  mkdir -p "$(dirname "$2")"
  sed -e "s/{{PROJECT_NAME}}/$(esc "$NAME")/g" \
      -e "s/{{PROJECT_DESC}}/$(esc "$DESC")/g" \
      -e "s/{{OWNER}}/$(esc "$OWNER")/g" \
      -e "s/{{FRAMEWORK}}/$(esc "$FRAMEWORK_LABEL")/g" \
      -e "s/{{NODE_VERSION}}/$(esc "$NODE_VERSION")/g" \
      -e "s/{{BIOME_VERSION}}/$(esc "$BIOME_VERSION")/g" \
      -e "s/{{BIOME_SCHEMA_VERSION}}/$(esc "$BIOME_SCHEMA_VERSION")/g" \
      -e "s|{{VERSION_FILE}}|$VERSION_FILE|g" \
      "$1" \
  | awk -v keys=" $KEYS " '
      index($0, ">>only:") {
        tags = $0
        sub(/.*>>only:/, "", tags); sub(/[^a-z0-9,-].*/, "", tags)
        keep = 0
        n = split(tags, a, ",")
        for (i = 1; i <= n; i++) if (index(keys, " " a[i] " ")) keep = 1
        skip = !keep; next
      }
      index($0, "<<only") { skip = 0; next }
      !skip
    ' > "$2"
}

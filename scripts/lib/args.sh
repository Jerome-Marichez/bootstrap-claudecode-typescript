# shellcheck shell=bash
# args.sh — options CLI de bootstrap.sh : défauts, parsing et validation.
# Sourcé par scripts/bootstrap.sh ; n'est pas exécutable seul.
# Définit : NAME DESC OWNER LAYOUT FRAMEWORK FRAMEWORK_LABEL CI TARGET
#           STORYBOOK TESTS_SETUP ACCEPTANCE POSTMAN DO_GIT

NAME=""
DESC=""
OWNER=""   # défaut : compte connecté à la CLI GitHub (gh api user), sinon git config user.name
LAYOUT="front-back"
FRAMEWORK="nextjs"
CI="github"
TARGET=""
STORYBOOK=1
TESTS_SETUP=1
ACCEPTANCE=0
POSTMAN=0   # package uniquement : force les tests système API (Postman)
DO_GIT=1

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --name)   NAME="$2"; shift 2 ;;
      --desc)   DESC="$2"; shift 2 ;;
      --owner)  OWNER="$2"; shift 2 ;;
      --layout) LAYOUT="$2"; shift 2 ;;
      --framework) FRAMEWORK="$2"; shift 2 ;;
      --ci)     CI="$2"; shift 2 ;;
      --target) TARGET="$2"; shift 2 ;;
      --no-storybook) STORYBOOK=0; shift ;;
      --no-tests-setup) TESTS_SETUP=0; shift ;;
      --acceptance) ACCEPTANCE=1; shift ;;
      --postman) POSTMAN=1; shift ;;
      --no-git) DO_GIT=0; shift ;;
      # $0 reste bootstrap.sh même sourcé : l'aide est son en-tête.
      -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) echo "Option inconnue : $1" >&2; exit 1 ;;
    esac
  done
}

validate_args() {
  [ -n "$NAME" ]   || { echo "--name est obligatoire" >&2; exit 1; }
  case "$NAME" in *[!a-z0-9-]*) echo "--name doit être en kebab-case (a-z, 0-9, tirets)" >&2; exit 1 ;; esac
  [ -n "$TARGET" ] || { echo "--target est obligatoire" >&2; exit 1; }
  [ -n "$DESC" ]   || DESC="Projet $NAME"
  # Les tokens sont substitués par un s/// de sed, qui ne survit pas à un retour à
  # la ligne dans le remplacement : on les aplatit en espaces.
  DESC=$(printf '%s' "$DESC" | tr '\n' ' ')
  if [ -z "$OWNER" ]; then
    # L'auteur est TOUJOURS le compte lié à la forge : celui connecté à la CLI gh.
    OWNER=$(gh api user --jq '.name // .login' 2>/dev/null || true)
    [ -z "$OWNER" ] && OWNER=$(git config user.name 2>/dev/null || true)
    [ -z "$OWNER" ] && { echo "--owner requis : aucun compte gh connecté (gh auth login) ni git config user.name" >&2; exit 1; }
  fi
  OWNER=$(printf '%s' "$OWNER" | tr '\n' ' ')
  case "$LAYOUT" in front-back|single|package) ;; *) echo "--layout doit être front-back, single ou package" >&2; exit 1 ;; esac
  case "$CI" in github|gitlab|none) ;; *) echo "--ci doit être github, gitlab ou none" >&2; exit 1 ;; esac

  if [ "$LAYOUT" = "package" ]; then
    # Une librairie npm est agnostique : aucun framework front n'est imposé.
    FRAMEWORK="none"
    FRAMEWORK_LABEL="aucun (librairie TypeScript agnostique)"
  else
    case "$FRAMEWORK" in nextjs|vite) ;; *) echo "--framework doit être nextjs ou vite" >&2; exit 1 ;; esac
    case "$FRAMEWORK" in
      nextjs) FRAMEWORK_LABEL="Next.js (App Router)" ;;
      vite)   FRAMEWORK_LABEL="Vite + React" ;;
    esac
  fi
}

#!/bin/sh
# Runs the pipeline in the container: every INTERVAL_MINUTES, and when
# triggered through trigger.py (at most every MIN_GAP_MINUTES). Changed files
# in output/report/ are committed and pushed to BRANCH, which publishes them.
# The pipeline itself only recalculates groups whose version in Zotero
# changed, so a run without changes takes seconds.
set -u
REPO_URL=${REPO_URL:-https://github.com/IPBES-Data/IPBES.LiteratureReport.git}
BRANCH=${BRANCH:-main}
PUSH=${PUSH:-true} # false: commit in the container only (for testing)
INTERVAL=$(( ${INTERVAL_MINUTES:-30} * 60 ))
MIN_GAP=$(( ${MIN_GAP_MINUTES:-5} * 60 ))
WORK=/work/IPBES.LiteratureReport
STATE=/work/state
mkdir -p "$STATE"

log() { echo "$(date -u +%FT%TZ) $*"; }
# the main versions in this image
VERSIONS=$(grep -E "^(R version|openalexPro|zotFunc|targets) " /opt/literature-report/versions.txt | paste -sd ";" - | sed 's/;/; /g')
status() { # state, result, change
  printf '{"state": "%s", "last_start": "%s", "last_end": "%s", "last_result": "%s", "last_change": "%s", "next_run": "%s", "versions": "%s"}\n' \
    "$1" "${last_start:-}" "${last_end:-}" "$2" "$3" "$(date -u -d "@$next" +%FT%TZ)" "$VERSIONS" > "$STATE/status.json"
}

# GitHub access (pushing the reports) and commit author
if [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
fi
git config --global user.name "${GIT_USER_NAME:-IPBES Literature Report (automatic)}"
git config --global user.email "${GIT_USER_EMAIL:-literature-report@users.noreply.github.com}"
git config --global --add safe.directory '*'

if [ ! -d "$WORK/.git" ]; then
  log "cloning $REPO_URL ($BRANCH)"
  git clone --recurse-submodules --branch "$BRANCH" "$REPO_URL" "$WORK" || exit 1
fi

log "versions: $VERSIONS"
python3 /opt/literature-report/trigger.py &

run() {
  last_start=$(date -u +%FT%TZ)
  status running "" ""
  log "run started"
  cd "$WORK" || return 1
  # the pipeline's state (_targets/meta/meta is tracked in git) survives the
  # update of the code; files of an interrupted run are rebuilt by targets
  cp _targets/meta/meta "$STATE/meta" 2>/dev/null
  git reset -q --hard HEAD
  git pull -q --ff-only origin "$BRANCH" || git pull -q --rebase origin "$BRANCH"
  git submodule -q update --init
  cp "$STATE/meta" _targets/meta/meta 2>/dev/null
  if Rscript -e 'targets::tar_make(reporter = "timestamp")' > "$STATE/last.log" 2>&1; then
    result=ok
  else
    result=failed
  fi
  change="no changes"
  if [ "$result" = ok ]; then
    git add output/report
    if ! git diff --cached --quiet; then
      git commit -q -m "Update reports (automatic)"
      if [ "$PUSH" != true ]; then
        change="committed, not pushed (PUSH=$PUSH)"
      elif git push -q origin "$BRANCH" || { git pull -q --rebase origin "$BRANCH" && git push -q origin "$BRANCH"; }; then
        change="pushed"
      else
        change="push failed"
      fi
    fi
  fi
  last_end=$(date -u +%FT%TZ)
  log "run $result, $change"
}

next=$(date +%s)
status idle "" ""
while true; do
  now=$(date +%s)
  if [ -f "$STATE/trigger" ] && [ $(( now - ${last_end_s:-0} )) -ge "$MIN_GAP" ]; then
    rm -f "$STATE/trigger"
    log "triggered"
    next=$now
  fi
  if [ "$now" -ge "$next" ]; then
    next=$(( now + INTERVAL ))
    run
    last_end_s=$(date +%s)
    status idle "$result" "$change"
  fi
  sleep 10
done

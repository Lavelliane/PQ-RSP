#!/usr/bin/env bash
#
# Reproduce every ProVerif verdict reported in the paper
# "Closing the HNDL Window in Consumer eSIM Provisioning".
#
# Requirements: ProVerif 2.05 on PATH (https://bblanche.gitlabpages.inria.fr/proverif/).
# Usage:        ./run_all.sh
#
# For each model the script runs ProVerif, saves the full log to results/<model>.log,
# extracts the RESULT lines, and prints a one-line tally (true / false / cannot-prove).
# Total wall time is on the order of 15 minutes; option_c and option_c_xwing dominate.

set -u
cd "$(dirname "$0")"
mkdir -p results

if ! command -v proverif >/dev/null 2>&1; then
  echo "ERROR: proverif not found on PATH. Install ProVerif 2.05 first." >&2
  exit 1
fi

MODELS=(
  # classical baseline (Dolev-Yao only, no quantum oracle): expect all TRUE
  option_a_classical option_b_classical option_c_classical option_d_classical
  # quantum oracle break_dh active: (a)/(b) FAIL secrecy, (c)/(d) resist
  option_a option_b option_c option_d
  # X-Wing combiner companion for (c): identical verdicts to option_c
  option_c_xwing
  # forward secrecy (phase-1 key reveal, no oracle): expect all TRUE
  option_a_pfs option_b_pfs option_c_pfs option_d_pfs
  # signature-forgery oracle break_ecdsa: authentication queries FALSE
  option_a_break_ecdsa option_a_break_ecdsa_full
)

printf '%-28s %8s %6s %6s %8s\n' "MODEL" "RESULTS" "TRUE" "FALSE" "CANNOT"
printf '%.0s-' {1..62}; echo
for m in "${MODELS[@]}"; do
  log="results/${m}.log"
  proverif "${m}.pv" > "$log" 2>&1
  res=$(grep -c '^RESULT' "$log")
  t=$(grep '^RESULT' "$log" | grep -c 'is true')
  f=$(grep '^RESULT' "$log" | grep -c 'is false')
  c=$(grep '^RESULT' "$log" | grep -c 'cannot be proved')
  printf '%-28s %8s %6s %6s %8s\n' "$m" "$res" "$t" "$f" "$c"
done
echo
echo "Full logs are in results/. Expected verdicts are documented in results/SUMMARY.md and README.md."

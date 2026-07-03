#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf 'ERROR: common.sh must be sourced by a backend script\n' >&2
  exit 1
fi

declare -gA source_do_stmt_by_index=()
declare -gA source_do_binder_by_index=()

source_do_open=""
source_do_return=""
source_do_stmt_count=0

semantic_validation_setup_output_dirs() {
  bin_dir="$output_dir_abs/bin"
  logs_dir="$output_dir_abs/logs"
  results_dir="$output_dir_abs/results"
  summary_log="$output_dir_abs/semantic-validation.log"
  renamer_raw_log="$logs_dir/raw.log"
  ado_summary_log="$output_dir_abs/summary.log"
  graph_log="$logs_dir/graph.log"

  mkdir -p "$bin_dir" "$logs_dir" "$results_dir"
  : > "$summary_log"
  : > "$ado_summary_log"
  : > "$graph_log"
}

log_summary() {
  printf '%s\n' "$*" | tee -a "$summary_log"
}

trim_text() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  text="${text%"${text##*[![:space:]]}"}"
  printf '%s\n' "$text"
}

extract_stmt_binder_label() {
  local stmt="$1"
  local index="$2"
  local label

  if [[ "$stmt" == *"<-"* ]]; then
    label="${stmt%%<-*}"
    label="$(trim_text "$label")"
  else
    label="$(trim_text "$stmt")"
    if [[ "$label" =~ ^let[[:space:]]+ ]]; then
      label="${label#let}"
      label="$(trim_text "$label")"
      if [[ "$label" == *"="* ]]; then
        label="${label%%=*}"
        label="$(trim_text "$label")"
      fi
    else
      label=""
    fi
  fi

  if [ -z "$label" ]; then
    label="stmt$index"
  fi

  printf '%s\n' "$label"
}

load_source_do_notation() {
  local parsed_tmp
  local tag
  local index
  local text

  parsed_tmp="$(mktemp)"

  if ! awk '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function is_cd_do(s) {
      return s ~ /(^|[^[:alnum:]_.])CD[.]do([^[:alnum:]_.]|$)/
    }

    function is_plain_do(s) {
      return s ~ /(^|[^[:alnum:]_.])do([^[:alnum:]_.]|$)/
    }

    function is_cd_return(s) {
      return s ~ /(^|[^[:alnum:]_.])CD[.]return([^[:alnum:]_.]|$)/
    }

    function is_plain_return(s) {
      return s ~ /(^|[^[:alnum:]_.])return([^[:alnum:]_.]|$)/
    }

    function finish_block() {
      block_count++
      block_open[block_count] = current_open
      block_return[block_count] = current_return
      block_stmt_count[block_count] = current_stmt_count

      for (i = 1; i <= current_stmt_count; i++) {
        block_stmt[block_count, i] = current_stmt[i]
      }

      if (current_open == "CD.do") {
        cd_block_count++
        selected_cd_block = block_count
      } else {
        plain_block_count++
        selected_plain_block = block_count
      }
    }

    !capturing && is_cd_do($0) {
      capturing = 1
      current_open = "CD.do"
      current_stmt_count = 0
      delete current_stmt
      next
    }

    !capturing && is_plain_do($0) {
      capturing = 1
      current_open = "do"
      current_stmt_count = 0
      delete current_stmt
      next
    }

    capturing {
      line = trim($0)

      if ((current_open == "CD.do" && is_cd_return($0)) ||
          (current_open == "do" && is_plain_return($0))) {
        current_return = line
        finish_block()
        capturing = 0
        next
      }

      if (line != "" && line !~ /^--/) {
        current_stmt_count++
        current_stmt[current_stmt_count] = line
      }
    }

    END {
      if (cd_block_count == 1) {
        selected_block = selected_cd_block
      } else if (cd_block_count > 1) {
        printf "ERROR: expected at most one CD.do/CD.return block, but found %d\n", cd_block_count > "/dev/stderr"
        exit 1
      } else if (plain_block_count == 1) {
        selected_block = selected_plain_block
      } else if (plain_block_count > 1) {
        printf "ERROR: expected exactly one do/return block, but found %d\n", plain_block_count > "/dev/stderr"
        exit 1
      } else {
        print "ERROR: could not find a do/return or CD.do/CD.return block" > "/dev/stderr"
        exit 1
      }

      printf "OPEN\t%s\n", block_open[selected_block]
      for (i = 1; i <= block_stmt_count[selected_block]; i++) {
        printf "STMT\t%d\t%s\n", i, block_stmt[selected_block, i]
      }
      printf "RETURN\t%s\n", block_return[selected_block]
    }
  ' "$input_file_abs" > "$parsed_tmp"; then
    rm -f "$parsed_tmp"
    exit 1
  fi

  while IFS=$'\t' read -r tag index text; do
    case "$tag" in
      OPEN)
        source_do_open="$index"
        ;;
      STMT)
        source_do_stmt_by_index["$index"]="$text"
        source_do_binder_by_index["$index"]="$(extract_stmt_binder_label "$text" "$index")"
        source_do_stmt_count="$index"
        ;;
      RETURN)
        source_do_return="$index"
        ;;
    esac
  done < "$parsed_tmp"

  rm -f "$parsed_tmp"

  if [ -z "$source_do_open" ] || [ -z "$source_do_return" ] || [ "$source_do_stmt_count" -eq 0 ]; then
    printf 'ERROR: extracted do-notation is incomplete in input-file: %s\n' "$input_file_abs" >&2
    exit 1
  fi
}

filter_rearrange_log() {
  local ghc_output_log="$1"
  local filtered_log="$2"

  awk '
    /^ppsfa/ { capture = 1 }
    capture { print }
    capture && /^[[:space:]]*minimum-cost[- ]permutations[[:space:]]*=/ { exit }
  ' "$ghc_output_log" > "$filtered_log"
}

filter_candidate_log() {
  local ghc_output_log="$1"
  local filtered_log="$2"
  local start_label="$3"

  awk -v start_label="$start_label" '
    !capture && index($0, start_label) == 1 { capture = 1 }
    capture { print }
    capture && /^[[:space:]]*tree-cost[[:space:]]*=/ { exit }
  ' "$ghc_output_log" > "$filtered_log"
}

write_summary_log_from_raw_log() {
  local raw_log="$1"

  if ! awk '
    /^rearrangeForADo-Summary:/ { capture = 1 }
    capture { print }
    capture && /^[[:space:]]*minimum-cost[- ]permutations[[:space:]]*=/ {
      found = 1
      capture = 0
      exit
    }
    END { if (!found) exit 1 }
  ' "$raw_log" > "$ado_summary_log"; then
    printf 'ERROR: could not find rearrangeForADo-Summary in %s\n' "$raw_log" >&2
    exit 1
  fi
}

write_graph_log_from_raw_log() {
  local raw_log="$1"
  local binder_labels_tmp
  local i

  {
    printf '%s\n' "-- Original program"
    printf '%s\n' "$source_do_open"

    for ((i = 1; i <= source_do_stmt_count; i++)); do
      if [ -z "${source_do_stmt_by_index[$i]+_}" ]; then
        printf 'ERROR: missing source statement for graph log: %s\n' "$i" >&2
        return 1
      fi

      printf '  %s\n' "${source_do_stmt_by_index[$i]}"
    done

    printf '  %s\n' "$source_do_return"
    printf '\n'
    printf '%s\n' "-- Internal representation with free variables by statement"
  } > "$graph_log"

  if ! awk '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function add_entry(s) {
      s = trim(s)
      if (s != "") {
        entry_count++
        entries[entry_count] = s
      }
    }

    function split_entries(s,   i, ch, entry, paren_depth, brace_depth, bracket_depth) {
      sub(/^[^[]*\[/, "", s)
      sub(/\][^]]*$/, "", s)

      entry = ""
      paren_depth = 0
      brace_depth = 0
      bracket_depth = 0

      for (i = 1; i <= length(s); i++) {
        ch = substr(s, i, 1)

        if (ch == "," && paren_depth == 0 && brace_depth == 0 && bracket_depth == 0) {
          add_entry(entry)
          entry = ""
          continue
        }

        entry = entry ch

        if (ch == "(") {
          paren_depth++
        } else if (ch == ")" && paren_depth > 0) {
          paren_depth--
        } else if (ch == "{") {
          brace_depth++
        } else if (ch == "}" && brace_depth > 0) {
          brace_depth--
        } else if (ch == "[") {
          bracket_depth++
        } else if (ch == "]" && bracket_depth > 0) {
          bracket_depth--
        }
      }

      add_entry(entry)
    }

    function print_ppsfa() {
      split_entries(buffer)

      if (entry_count == 0) {
        print "ERROR: ppsfa block did not contain statements" > "/dev/stderr"
        exit 1
      }

      print "ppsfa"
      for (i = 1; i <= entry_count; i++) {
        suffix = i < entry_count ? "," : "]"
        if (i == 1) {
          print "  [" entries[i] suffix
        } else {
          print "   " entries[i] suffix
        }
      }
    }

    /^ppsfa[[:space:]]*$/ && !found {
      found = 1
      capture = 1
      next
    }

    capture && /^(addUsedGRE|rearrangeForADo-commutative-do|rearrangeForADo-StmtsDependencyGraph)/ {
      print_ppsfa()
      printed = 1
      capture = 0
      exit
    }

    capture {
      buffer = buffer " " trim($0)
    }

    END {
      if (!found) {
        print "ERROR: could not find ppsfa block" > "/dev/stderr"
        exit 1
      }

      if (capture && !printed) {
        print_ppsfa()
      }
    }
  ' "$raw_log" >> "$graph_log"; then
    printf 'ERROR: could not write ppsfa section to graph log from %s\n' "$raw_log" >&2
    return 1
  fi

  binder_labels_tmp="$(mktemp)"
  for ((i = 1; i <= source_do_stmt_count; i++)); do
    if [ -z "${source_do_binder_by_index[$i]+_}" ]; then
      printf 'ERROR: missing source binder for graph log: %s\n' "$i" >&2
      rm -f "$binder_labels_tmp"
      return 1
    fi

    printf '%s\t%s\n' "$i" "${source_do_binder_by_index[$i]}" >> "$binder_labels_tmp"
  done

  if ! awk -v stmt_count="$source_do_stmt_count" -v binder_labels_file="$binder_labels_tmp" '
    BEGIN {
      while ((getline binder_line < binder_labels_file) > 0) {
        split(binder_line, binder_parts, "\t")
        binder_index = binder_parts[1]
        binder_label = binder_parts[2]
        binder_by_index[binder_index] = binder_label
        binder_label_count[binder_label]++
      }
      close(binder_labels_file)
    }

    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function add_edge(src, dst) {
      edge_count++
      if (adjacency[src] == "") {
        adjacency[src] = dst
      } else {
        adjacency[src] = adjacency[src] ", " dst
      }
    }

    function parse_pair(line,   parts) {
      sub(/^[^=]*=[[:space:]]*/, "", line)
      gsub(/[[:space:]]+/, "", line)
      split(line, parts, "->")
      if (parts[1] != "" && parts[2] != "") {
        add_edge(parts[1] + 0, parts[2] + 0)
      }
    }

    function binder_display_label(idx,   label) {
      label = binder_by_index[idx]
      if (label == "") {
        label = "stmt" idx
      }

      if (binder_label_count[label] > 1) {
        return label "@" idx
      }

      return label
    }

    function print_adjacency_list(   i) {
      print ""
      print "-- Precedence graph adjacency list"
      if (edge_count == 0) {
        print "<no precedence edges: 0 RAW dependencies, all statements are independent>"
      }

      for (i = 1; i <= stmt_count; i++) {
        if (adjacency[i] == "") {
          print i " -> {}"
        } else {
          print i " -> {" adjacency[i] "}"
        }
      }
    }

    function print_grouped_by_binder(   i, printed_any) {
      print ""
      print "-- Precedence graph RAW dependencies grouped by binder"
      for (i = 1; i <= stmt_count; i++) {
        if (adjacency[i] != "") {
          print binder_display_label(i) ": " i " -> {" adjacency[i] "}"
          printed_any = 1
        }
      }

      if (!printed_any) {
        print "<no RAW dependencies to group>"
      }
    }

    function finish_graph() {
      if (found && !finished) {
        print_adjacency_list()
        print_grouped_by_binder()
        finished = 1
      }
    }

    /^rearrangeForADo-StmtsDependencyGraph/ {
      found = 1
      capture = 1
      next
    }

    capture && /^(rearrangeForADo-permutation|rearrangeForADo final tree:|rearrangeForADo-Summary:)/ {
      finish_graph()
      exit
    }

    capture {
      if ($0 ~ /^[[:space:]]*pair[[:space:]]*=/) {
        parse_pair($0)
      }
    }

    /^rearrangeForADo-commutative-do/ && /commutative-do[[:space:]]*=[[:space:]]*False/ {
      commutative_false = 1
    }

    END {
      if (found) {
        finish_graph()
      } else if (commutative_false) {
        print ""
        print "<reordering not executed: commutative-do conditions were not met>"
      } else if (!found) {
        print "ERROR: could not find rearrangeForADo-StmtsDependencyGraph" > "/dev/stderr"
        exit 1
      }
    }
  ' "$raw_log" >> "$graph_log"; then
    printf 'ERROR: could not write precedence graph section from %s\n' "$raw_log" >&2
    rm -f "$binder_labels_tmp"
    return 1
  fi

  rm -f "$binder_labels_tmp"
}

rewrite_original_ado_log_line() {
  local line="$1"

  line="${line//CD.do/do}"
  line="${line//CD.return/return}"
  printf '%s\n' "$line"
}

write_original_ado_log_from_compile_output() {
  local ghc_output_log="$1"
  local log_path="$logs_dir/original_ado.log"
  local candidate_trace_tmp
  local i

  candidate_trace_tmp="$(mktemp)"
  filter_candidate_log "$ghc_output_log" "$candidate_trace_tmp" "rearrangeForADo final tree:"

  if [ ! -s "$candidate_trace_tmp" ]; then
    printf 'ERROR: could not find ApplicativeDo renamer trace for original_ado\n' >&2
    rm -f "$candidate_trace_tmp"
    return 1
  fi

  {
    printf '%s\n' "-- do-notation"
    rewrite_original_ado_log_line "$source_do_open"

    for ((i = 1; i <= source_do_stmt_count; i++)); do
      if [ -z "${source_do_stmt_by_index[$i]+_}" ]; then
        printf 'ERROR: missing source statement for original_ado log: %s\n' "$i" >&2
        rm -f "$candidate_trace_tmp"
        return 1
      fi

      printf '  %s\n' "$(rewrite_original_ado_log_line "${source_do_stmt_by_index[$i]}")"
    done

    printf '  %s\n' "$(rewrite_original_ado_log_line "$source_do_return")"
    printf '\n'
    printf '%s\n' "-- Renamer trace"
    printf '%s\n' "rearrangeForADo final tree:"
  } > "$log_path"

  if ! awk '
    /^[[:space:]]*rearrangeForADo-resulting tree[[:space:]]*=/ {
      capture = 1
      next
    }

    capture && /^[[:space:]]*tree-cost[[:space:]]*=/ {
      found = 1
      capture = 0
      exit
    }

    capture {
      line = $0
      sub(/^  /, "", line)
      print line
    }

    END { if (!found) exit 1 }
  ' "$candidate_trace_tmp" >> "$log_path"; then
    printf 'ERROR: could not extract final StmtTree for original_ado\n' >&2
    rm -f "$candidate_trace_tmp"
    return 1
  fi

  if ! append_execution_plan "$candidate_trace_tmp" "$log_path"; then
    rm -f "$candidate_trace_tmp"
    return 1
  fi

  cat "$log_path"
  rm -f "$candidate_trace_tmp"
}

strip_candidate_summary() {
  local trace_log="$1"
  local stripped_log="$2"

  awk '
    /^rearrangeForADo-Summary:/ {
      skipping = 1
      next
    }

    skipping && /^[[:space:]]*minimum-cost[- ]permutations[[:space:]]*=/ {
      skipping = 0
      next
    }

    !skipping { print }
  ' "$trace_log" > "$stripped_log"
}

extract_index_order() {
  local filtered_log="$1"

  awk '
    /^[[:space:]]*index[- ]order[[:space:]]*=/ {
      line = $0
      sub(/^.*\[/, "", line)
      sub(/\].*$/, "", line)
      gsub(/,/, " ", line)
      gsub(/[[:space:]]+/, " ", line)
      sub(/^ /, "", line)
      sub(/ $/, "", line)
      print line
      exit
    }
  ' "$filtered_log"
}

append_execution_plan() {
  local trace_log="$1"
  local output_log="$2"
  local binders_tmp
  local plan_tmp
  local i

  binders_tmp="$(mktemp)"
  plan_tmp="$(mktemp)"

  for ((i = 1; i <= source_do_stmt_count; i++)); do
    if [ -z "${source_do_binder_by_index[$i]+_}" ]; then
      printf 'ERROR: missing binder label for source statement: %s\n' "$i" >&2
      rm -f "$binders_tmp" "$plan_tmp"
      return 1
    fi

    printf '%s\t%s\n' "$i" "${source_do_binder_by_index[$i]}" >> "$binders_tmp"
  done

  if ! awk -v binders_file="$binders_tmp" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function read_binders(   line, tab, idx) {
      while ((getline line < binders_file) > 0) {
        tab = index(line, "\t")
        if (tab > 0) {
          idx = substr(line, 1, tab - 1)
          binders[idx] = substr(line, tab + 1)
        }
      }
      close(binders_file)
    }

    function parse_plan(   tok, indent, child_count, child, sep, plan, idx) {
      if (node_pos >= node_count) {
        error = "unexpected end of StmtTree"
        return ""
      }

      node_pos++
      tok = node_type[node_pos]
      indent = node_indent[node_pos]

      if (tok == "O") {
        idx = order[++leaf_pos]
        if (idx == "") {
          error = "StmtTreeOne without matching index-order entry"
          return ""
        }
        if (!(idx in binders)) {
          error = "index-order references missing binder label: " idx
          return ""
        }
        return binders[idx]
      }

      if (tok == "B" || tok == "A") {
        sep = tok == "B" ? " ; " : " | "
        plan = ""
        child_count = 0

        while (node_pos < node_count && node_indent[node_pos + 1] > indent) {
          child = parse_plan()
          if (error != "") return ""

          child_count++
          if (child_count == 1) {
            plan = child
          } else {
            plan = plan sep child
          }
        }

        if (tok == "B" && child_count != 2) {
          error = "StmtTreeBind expected exactly 2 children, found " child_count
          return ""
        }

        if (tok == "A" && child_count < 2) {
          error = "StmtTreeApplicative expected at least 2 children, found " child_count
          return ""
        }

        return "(" plan ")"
      }

      error = "unexpected or missing StmtTree token"
      return ""
    }

    function strip_outer_parens(s,   depth, i, ch) {
      if (substr(s, 1, 1) != "(" || substr(s, length(s), 1) != ")") {
        return s
      }

      depth = 0
      for (i = 1; i <= length(s); i++) {
        ch = substr(s, i, 1)
        if (ch == "(") {
          depth++
        } else if (ch == ")") {
          depth--
          if (depth == 0 && i < length(s)) {
            return s
          }
        }
      }

      return substr(s, 2, length(s) - 2)
    }

    BEGIN {
      read_binders()
    }

    order_count == 0 && /^[[:space:]]*index[- ]order[[:space:]]*=/ {
      line = $0
      sub(/^.*\[/, "", line)
      sub(/\].*$/, "", line)
      gsub(/,/, " ", line)
      line = trim(line)
      order_count = split(line, order, /[[:space:]]+/)
    }

    !tree_done && node_count == 0 && /^[[:space:]]*rearrangeForADo-resulting tree[[:space:]]*=/ {
      in_tree = 1
      next
    }

    in_tree && /^[[:space:]]*tree-cost[[:space:]]*=/ {
      in_tree = 0
      tree_done = 1
      next
    }

    in_tree {
      line = $0
      if (match(line, /StmtTree(Bind|Applicative|One)/)) {
        ctor = substr(line, RSTART, RLENGTH)
        indent_text = line
        sub(/[^[:space:]].*$/, "", indent_text)

        node_count++
        node_indent[node_count] = length(indent_text)

        if (ctor == "StmtTreeBind") {
          node_type[node_count] = "B"
        } else if (ctor == "StmtTreeApplicative") {
          node_type[node_count] = "A"
        } else {
          node_type[node_count] = "O"
        }
      }
    }

    END {
      if (order_count == 0) {
        print "ERROR: could not find index order for execution plan" > "/dev/stderr"
        exit 1
      }

      if (node_count == 0) {
        print "ERROR: could not find StmtTree for execution plan" > "/dev/stderr"
        exit 1
      }

      node_pos = 0
      leaf_pos = 0
      plan = parse_plan()

      if (error != "") {
        print "ERROR: " error > "/dev/stderr"
        exit 1
      }

      if (node_pos != node_count) {
        print "ERROR: StmtTree parser did not consume all nodes" > "/dev/stderr"
        exit 1
      }

      if (leaf_pos != order_count) {
        print "ERROR: StmtTree leaf count does not match index-order count" > "/dev/stderr"
        exit 1
      }

      print strip_outer_parens(plan)
    }
  ' "$trace_log" > "$plan_tmp"; then
    rm -f "$binders_tmp" "$plan_tmp"
    return 1
  fi

  {
    printf '\n'
    printf '%s\n' "-- Execution plan"
    cat "$plan_tmp"
  } >> "$output_log"

  rm -f "$binders_tmp" "$plan_tmp"
}

write_candidate_log_with_do_notation() {
  local trace_log="$1"
  local output_log="$2"
  local order
  local index
  local stmt

  order="$(extract_index_order "$trace_log")"
  if [ -z "$order" ]; then
    printf 'ERROR: could not find index order in candidate trace: %s\n' "$trace_log" >&2
    return 1
  fi

  {
    printf '%s\n' "-- Reordered do-notation"
    printf '%s\n' "$source_do_open"

    for index in $order; do
      if [ -z "${source_do_stmt_by_index[$index]+_}" ]; then
        printf 'ERROR: index order references missing source statement: %s\n' "$index" >&2
        return 1
      fi

      stmt="${source_do_stmt_by_index[$index]}"
      printf '  %s\n' "$stmt"
    done

    printf '  %s\n' "$source_do_return"
    printf '\n'
    printf '%s\n' "-- Renamer trace"
  } > "$output_log"

  cat "$trace_log" >> "$output_log"
  append_execution_plan "$trace_log" "$output_log"
}

semantic_validation_candidate_start_label() {
  local candidate_n="${1:-}"

  if [ -n "$candidate_n" ]; then
    printf '%s\n' "rearrangeForADo candidate selection tree (fado-reorder-candidate-n) ="
  else
    printf '%s\n' "rearrangeForADo final tree:"
  fi
}

semantic_validation_process_compile_success() {
  local name="$1"
  local candidate_n="${2:-}"
  local ghc_output_tmp="$3"
  local log_path="$logs_dir/$name.log"
  local candidate_trace_tmp
  local candidate_trace_without_summary_tmp
  local start_label

  candidate_trace_tmp="$(mktemp)"
  candidate_trace_without_summary_tmp="$(mktemp)"
  start_label="$(semantic_validation_candidate_start_label "$candidate_n")"

  if [ -z "$candidate_n" ]; then
    filter_rearrange_log "$ghc_output_tmp" "$renamer_raw_log"
  fi

  filter_candidate_log "$ghc_output_tmp" "$candidate_trace_tmp" "$start_label"
  strip_candidate_summary "$candidate_trace_tmp" "$candidate_trace_without_summary_tmp"

  if ! write_candidate_log_with_do_notation "$candidate_trace_without_summary_tmp" "$log_path"; then
    rm -f "$candidate_trace_tmp" "$candidate_trace_without_summary_tmp"
    return 1
  fi

  if [ -s "$log_path" ]; then
    cat "$log_path"
  fi

  rm -f "$candidate_trace_tmp" "$candidate_trace_without_summary_tmp"
}

semantic_validation_process_compile_failure() {
  local name="$1"
  local candidate_n="${2:-}"
  local ghc_output_tmp="$3"
  local log_path="$logs_dir/$name.log"
  local candidate_trace_tmp
  local candidate_trace_without_summary_tmp
  local start_label

  candidate_trace_tmp="$(mktemp)"
  candidate_trace_without_summary_tmp="$(mktemp)"
  start_label="$(semantic_validation_candidate_start_label "$candidate_n")"

  if [ -z "$candidate_n" ]; then
    filter_rearrange_log "$ghc_output_tmp" "$renamer_raw_log"
  fi

  filter_candidate_log "$ghc_output_tmp" "$candidate_trace_tmp" "$start_label"
  if [ -s "$candidate_trace_tmp" ]; then
    strip_candidate_summary "$candidate_trace_tmp" "$candidate_trace_without_summary_tmp"
    write_candidate_log_with_do_notation "$candidate_trace_without_summary_tmp" "$log_path" || true
  fi

  if [ -s "$log_path" ]; then
    cat "$log_path"
  elif [ -z "$candidate_n" ] && [ -s "$renamer_raw_log" ]; then
    cat "$renamer_raw_log"
  else
    cat "$ghc_output_tmp" >&2
  fi

  rm -f "$candidate_trace_tmp" "$candidate_trace_without_summary_tmp"
  log_summary "ERROR: compilation failed for $name. See log: $log_path"
}

run_binary() {
  local name="$1"
  local bin_path="$2"
  local run_log="$results_dir/$name.run.log"
  local exit_log="$results_dir/$name.exit"
  local status
  local line

  log_summary "[RUN] $name -> $run_log"
  set +e
  "$bin_path" 2>&1 | tee "$run_log"
  status=${PIPESTATUS[0]}
  set -e

  printf '%s\n' "$status" > "$exit_log"

  if [ -s "$run_log" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      log_summary "[OUTPUT] $line"
    done < "$run_log"
  else
    log_summary "[OUTPUT] <empty>"
  fi

  log_summary "[EXIT CODE] $name = $status"
}

extract_permutation_count() {
  local renamer_log="$1"

  awk '
    /^rearrangeForADo-commutative-do/ {
      seen_header = 1
      in_commutative = ($0 ~ /commutative-do[[:space:]]*=[[:space:]]*True/)
      next
    }

    seen_header && /^[[:space:]]*commutative-do[[:space:]]*=/ {
      in_commutative = ($0 ~ /=[[:space:]]*True/)
      seen_header = 0
      next
    }

    /^[^[:space:]]/ && $0 !~ /^rearrangeForADo-commutative-do/ {
      seen_header = 0
    }

    in_commutative && /^[[:space:]]*generated[- ]permutations[[:space:]]*=/ {
      print $NF
      in_commutative = 0
    }
  ' "$renamer_log"
}

has_non_commutative_ado_block() {
  local renamer_log="$1"

  awk '
    /^rearrangeForADo-commutative-do/ && /commutative-do[[:space:]]*=[[:space:]]*False/ {
      found = 1
    }

    END { exit found ? 0 : 1 }
  ' "$renamer_log"
}

semantic_validation_log_context() {
  log_summary "== Semantic validation reorder =="
  log_summary "input-file = $input_file_abs"
  log_summary "output-dir = $output_dir_abs"
  log_summary ""
}

run_semantic_validation_reorder() {
  local permutation_counts
  local n_permutations
  local i
  local name
  local original_status
  local compared_status
  local diff_path
  local failed
  local summary_line

  if ! declare -F compile_candidate >/dev/null; then
    printf 'ERROR: backend must define compile_candidate\n' >&2
    exit 1
  fi

  if ! declare -F compile_original >/dev/null; then
    printf 'ERROR: backend must define compile_original\n' >&2
    exit 1
  fi

  if ! declare -F compile_original_ado >/dev/null; then
    printf 'ERROR: backend must define compile_original_ado\n' >&2
    exit 1
  fi

  semantic_validation_setup_output_dirs

  if declare -F semantic_validation_prepare_backend >/dev/null; then
    semantic_validation_prepare_backend
  fi

  semantic_validation_log_context
  load_source_do_notation

  compile_original
  compile_original_ado
  compile_candidate "optimal-reorder"
  write_graph_log_from_raw_log "$renamer_raw_log"
  write_summary_log_from_raw_log "$renamer_raw_log"

  mapfile -t permutation_counts < <(extract_permutation_count "$renamer_raw_log")

  if [ "${#permutation_counts[@]}" -eq 0 ]; then
    if has_non_commutative_ado_block "$renamer_raw_log"; then
      n_permutations=0
    else
      log_summary "ERROR: could not find 'generated permutations    =' for a commutative block in $renamer_raw_log"
      exit 1
    fi
  fi

  if [ "${#permutation_counts[@]}" -gt 1 ]; then
    log_summary "ERROR: expected exactly one commutative block, but found ${#permutation_counts[@]} values: ${permutation_counts[*]}"
    exit 1
  fi

  if [ "${#permutation_counts[@]}" -eq 1 ]; then
    n_permutations="${permutation_counts[0]}"
    if [[ ! "$n_permutations" =~ ^[0-9]+$ ]]; then
      log_summary "ERROR: generated permutations value is not numeric: $n_permutations"
      exit 1
    fi

    if (( n_permutations <= 0 )); then
      log_summary "ERROR: generated permutations must be greater than zero: $n_permutations"
      exit 1
    fi
  fi

  if (( n_permutations == 0 )); then
    log_summary "generated reorder permutations = 0"
  else
    log_summary "generated permutations = $n_permutations"
  fi
  log_summary ""

  for ((i = 0; i < n_permutations; i++)); do
    compile_candidate "permutation_$i" "$i"
  done

  log_summary ""
  run_binary "original" "$bin_dir/original"
  run_binary "original_ado" "$bin_dir/original_ado"
  run_binary "optimal-reorder" "$bin_dir/optimal-reorder"

  for ((i = 0; i < n_permutations; i++)); do
    run_binary "permutation_$i" "$bin_dir/permutation_$i"
  done

  log_summary ""
  log_summary "== Semantic comparison =="

  read -r original_status < "$results_dir/original.exit"
  failed=0

  compare_with_original() {
    local name="$1"

    read -r compared_status < "$results_dir/$name.exit"

    if [ "$compared_status" != "$original_status" ]; then
      printf -v summary_line '[FAIL] %-15s: different exit code (original=%s, %s=%s)' "$name" "$original_status" "$name" "$compared_status"
      log_summary "$summary_line"
      failed=1
    fi

    if cmp -s "$results_dir/original.run.log" "$results_dir/$name.run.log"; then
      printf -v summary_line '[OK] %-15s: identical output' "$name"
      log_summary "$summary_line"
    else
      diff_path="$results_dir/$name.diff"
      diff -u "$results_dir/original.run.log" "$results_dir/$name.run.log" > "$diff_path" || true
      printf -v summary_line '[FAIL] %-15s: different output. Diff: %s' "$name" "$diff_path"
      log_summary "$summary_line"
      failed=1
    fi
  }

  compare_with_original "original_ado"
  compare_with_original "optimal-reorder"

  for ((i = 0; i < n_permutations; i++)); do
    name="permutation_$i"
    compare_with_original "$name"
  done

  if [ "$failed" -ne 0 ]; then
    log_summary ""
    log_summary "RESULT: FAIL"
    exit 1
  fi

  log_summary ""
  log_summary "RESULT: OK"
}

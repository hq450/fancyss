# Frontend/Backend Interaction Unification

## Goal

Reduce the number of one-off frontend/backend interaction patterns in `Module_shadowsocks.asp`.

Current problems:

- some actions depend on `_api_` success before log polling starts
- some actions use WebSocket streaming, some use HTTP log files, some mix both
- special cases such as `update_ss()` and `restore_ss_conf()` drift away from the common flow
- when backend behavior changes, multiple frontend entrypoints break independently

## Canonical interaction modes

### 1. Realtime log task

Examples:

- `ss_config.sh`
- `ss_conf.sh`
- `ss_rule_update.sh`
- `ss_node_subscribe.sh`
- `ss_xray.sh`
- `ss_reboot_job.sh`
- `ss_status_reset.sh`
- `ss_update.sh`

Rules:

- `ws` available:
  - persist dbus fields through `_api_`
  - execute script through `ws`
  - stream stdout directly
- `ws` unavailable:
  - fire `_api_`
  - start log polling after request dispatch, not after `_api_ success`

### 2. Snapshot/status task

Examples:

- top status bar
- detailed status
- history/status files

Rules:

- prefer reading the latest generated runtime file
- treat placeholder `Waiting/等待` payloads as transitional, not final success
- only fall back to `_api_` execution when snapshot source is unavailable or invalid

### 3. Control/no-log task

Examples:

- `dummy_script.sh`
- small local dbus writes
- UI-only persistence

Rules:

- no loading log window
- no realtime log polling
- caller handles success/failure locally

## Phase 1 implementation

- keep existing `push_data_ws()` path for ws log streaming
- centralize HTTP-side action classification in `push_data()`
- make `update_ss()` and `restore_ss_conf()` stop bypassing the common HTTP path
- keep existing special snapshot readers for now

## Phase 2 candidates

- unify `proc_status`, dns test, and generic file-follow readers under one snapshot helper
- add explicit action profile table instead of regex-based classification
- normalize button/close/countdown behavior for every realtime-log task

use `rg -F 'Command::new'` within `~/sandbox/clones/colmena/`

use `hx $(realpath $(which nixos-rebuild))` to access the bash script

>[!NOTE]
> The option `--extra-experimental-features "flakes"` is only set
> if `expression.requires_flakes()` where `expression: NixExpression`.

>[!TODO]
> Also search for nix-store by itself, nix-instantiate, etc.
> And also search for `make_privileged_command(...)` usages.
> or actually maybe `.stdin(...)` or `Stdio::piped(...)`.


## `Command::new()` Calls Translated
```rs
command/repl.rs:                let mut repl_cmd = Command::new("nix");
/*
nix repl                                       \
  --experimental-features "nix-command flakes" \
  --file $REPL_EXPRESSION_FILE
 */

nix/key.rs:                     let output = Command::new(pathname)
/*
$PATHNAME $ARGS < /dev/null |& ... 
 */

nix/info.rs:                    let version_cmd = Command::new("nix-instantiate")
/*
# `NixCheck::detect(...)`
# NOTE: Used to detect if Nix is present (and if so, what version)
# NOTE: The version number is used to detect if flakes are supported (NOT enabled though)
# NOTE: You can do the same with nix3 with `nix --version`
nix-instantiate --version
 */

nix/info.rs:                    let flake_cmd = Command::new("nix-instantiate")
/*
# `NixCheck::detect(...)`
# NOTE: Used to detect if flakes are enabled
nix-instantiate               \
  --eval -E builtins.getFlake \
  &> /dev/null
 */

nix/flake.rs:                   let child = Command::new("nix")
/*
# `FlakeMetadata::resolve(flake: &str) -> ColmenaREsult<Self>`
nix flake metadata                                   \
  --json                                             \
  --extra-experimental-features "nix-command flakes"
 */

nix/flake.rs:                   let status = Command::new("nix")
/*
# `lock_flake_quiet(uri: &str) -> ColmenaResult<()>`
# NOTE: "Quietly locks the dependencies of a flake."
nix flake lock                                       \
  --extra-experimental-features "nix-command flakes"
 */

nix/profile.rs:                 let mut command = Command::new("nix-store");
/*
# `Profile::create_gc_root(&self, path: &Path) -> ColmenaResult<()>`
# NOTE: "Create a GC root for this profile."
# Each Profile struct contains a StorePath object
nix-store               \
  --no-build-output     \
  --indirect            \
  --add-root            \
  --realise $STORE_PATH \
  1>/dev/null
 */

nix/hive/mod.rs:                let mut command = Command::new("nix-instantiate");
/*
# `NixInstantiate::instantiate(&self) -> Command`
# NOTE: "Instantiation is not supported with DirectFlakeEval"
# NOTE: $EXPRESSION == `self.hive.get_base_expression() + self.expression`
# NOTE: --extra-experimental-features "flakes" only if `self.hive.is_flake()`
nix-instantiate -E $EXPRESSION           \
  --no-gc-warning                        \
  --extra-experimental-features "flakes"
 */

nix/hive/mod.rs:                let mut command = Command::new("nix");
/*
# `NixInstantiate::eval(self) -> Command`
# NOTE: $FLAGS == `self.hive.nix_flags()`

# XXX: WARNING: if `self.hive.evaluation_method` is `EvaluationMethod::NixInstantiate`
# XXX: WARNING: then `NixInstantiate::instantiate(...)` (previous) is called
$NIX_INSTANTIATE_COMMAND
  --eval
  --json
  --strict
  --read-write-mode # ensures the derivations are instantiated, required for system profile evaluation and IFD
  $FLAGS

# XXX: WARNING: else if `self.hive.evaluation_method` is `EvaluationMethod::DirectFlakeEval`
# XXX: WARNING: then `NixInstantiate::instantiate(...)` (previous) is called
nix eval ${FLAKE_URI}#colmenaHive $FULL_EXPRESSION $FLAGS \ 
  --json                                                  \ 
  --apply                                                 \ 
  --extra-experimental-features "nix-command flakes"
 */

nix/evaluator/nix_eval_jobs.rs: let mut command = Command::new(&self.executable);
/*
# `NixEvalJobs::evaluate(&self, expression: &dyn NixExpression, flags: NixFlags) -> ColmenaREsult<Pin<Box<dyn Stream<Item = EvalResult>>>>`
# NOTE: $EXECUTABLE defaults to EXECUTABLE='nix-eval-jobs'
$EXECUTABLE $FLAGS                       \
  --workers $WORKERS                     \
  --expr $EXPRESSION                     \
  --extra-experimental-features "flakes" \
  2>&1
 */

nix/host/local.rs:              let mut command = self.make_privileged_command(&["sh", "-c", &key_script]);
/*
# `Local::upload_key(&mut self, name: &str, key: &Key, require_ownership: bool) -> ColmenaResult<()>`
# XXX: NOTE: Same as `Ssh::upload_key()`
sh -c "$KEY_SCRIPT"
 */


nix/host/local.rs:              let mut command = Command::new("nix-store");
/*
# `Local::realize_remote(...)`
# XXX: NOTE: Same as `Ssh::realize_remote(...)`
nix-store
  --no-gc-warning
  --realise $DERIVATION_PATH
 */

nix/host/local.rs:              self.make_privileged_command(&["nix-env", "--profile", SYSTEM_PROFILE, "--set", path])
/*
# `Local::activate(&mut self, profile: &Profile, goal: Goal) -> ColmenaResult<()>`
# XXX: NOTE: Same as `Ssh::activate(...)`

# NOTE: This command runs if `goal.should_switch_profile()`
nix-env --profile $SYSTEM+PROFILE
  --set $PROFILE_PATH

# NOTE: Separate command (runs regardless of `goal.should_switch_profile()`)
$ACTIVATION_COMMAND*/

nix/host/local.rs:              let paths = Command::new("readlink")
/*
# `Local::get_current_system_profile(&mut self) -> ColmenaResult<Profile>`
# XXX: NOTE: Same as `Ssh::get_current_system_profile(...)`
readlink -e $CURRENT_PROFILE
 */

nix/host/local.rs:              let paths = Command::new("sh")
/*
# `Local::get_main_system_profile(&mut self) -> ColmenaResult<Profile>`
# XXX: NOTE: Same as `Ssh::get_main_system_profile(...)`
sh -c 'readlink -e "$SYSTEM_PROFILE" | readlink -e "$CURRENT_PROFILE"'
 */

nix/host/local.rs:              let mut result = Command::new(full_command[0]);
/*
# `Local::make_privileged_command<S: AsRef<str>>(&self, command: &[S]) -> Command`
$COMMAND
 */

nix/store.rs:                   let references = Command::new("nix-store")
/*
# `StorePath::references(...)`
nix-store
  --query
  --references $STORE_PATH
 */

nix/host/ssh.rs:                let mut cmd = Command::new("ssh");
/*
# `Ssh::ssh(...)`
# $PRIVESC_COMMAND is privilege_escalation_command from Ssh struct
NIX_SSHOPTS="$SSH_OPTIONS" ssh $SSH_OPTIONS -- $PRIVESC_COMMAND $COMMAND
 */

nix/host/ssh.rs:                let mut command = Command::new("nix");
/*
# `Ssh::nix_copy_closure(...)` - CONDITION: `if self.use_nix3_copy()`
# NOTE: --builders-use-substitutes "needed due to UX bug in ssh-ng://"
# --derivation is only added if the `path.file_extension() == "drv"`
# --to or --from is used depending on `CopyDirection`
# "?compress=true" is added after ${SSH_TARGET} if `options.gzip` is set
# WARNING: COMMAND EXECUTED OVER SSH (`self.ssh(...)`)
NIX_SSHOPTS="$SSH_OPTIONS" nix copy $CLOSURE_PATH
  --no-check-sigs
  --substitute-on-destination
  --builders-use-substitutes
  --derivation
  [--to|--from] "ssh-ng://${SSH_TARGET}?compress=true"
  --extra-experimental-features "nix-command"
 */

nix/host/ssh.rs:                let mut command = Command::new("nix-copy-closure");
/*
# `Ssh::nix_copy_closure(...)` - CONDITION: `else`
# --include-outputs if `options.include_outputs`
# --use-substitues if `options.use_substitutes`
# --gzip if `options.gzip`
# WARNING: COMMAND EXECUTED OVER SSH (`self.ssh(...)`)
NIX_SSHOPTS="$SSH_OPTIONS" nix-copy-closure $SSH_TARGET $CLOSURE_PATH
  [--to|--from]
  --include-outputs
  --use-substitues
  --gzip
 */


nix/host/ssh.rs:                let mut command = self.ssh(&["sh", "-c", &key_script]);
/*
# `Ssh::upload_key(...)`
# XXX: NOTE: Same as `Ssh::upload_key()`
# WARNING: COMMAND EXECUTED OVER SSH (`sel.ssh(...)`)
sh -c "$KEY_SCRIPT"
 */


nix/host/ssh.rs:                let mut command = self.ssh("nix-store");
/*
# `Ssh::realize_remote(...)`
# XXX: NOTE: Same as `Local::realize_remote(...)`
# WARNING: COMMAND EXECUTED OVER SSH (`self.ssh(...)`)
nix-store
  --realise $DERIVATION
   --no-gc-warning
 */

nix/host/ssh.rs:                let set_profile = self.ssh(&["nix-env", "--profile", SYSTEM_PROFILE, "--set", path]);
/*
# `Ssh::activate` - activate (switch to) a specific NixOS profile
# XXX: NOTE: Same as `Local::activate(...)`

# NOTE: This command runs if `goal.should_switch_profile()`
# WARNING: COMMAND EXECUTED OVER SSH (`self.ssh(...)`)
nix-env --profile $SYSTEM+PROFILE
  --set $PROFILE_PATH

# NOTE: Separate command (runs regardless of `goal.should_switch_profile()`)
# WARNING: COMMAND EXECUTED OVER SSH (`self.ssh(...)`)
$ACTIVATION_COMMAND
 */

nix/host/ssh.rs:                let paths = self.ssh(&["readlink", "-e", CURRENT_PROFILE])
/*
# `Ssh::get_current_system_profile(&mut self) -> ColmenaResult<Profile>`
# XXX: NOTE: Same as `Local::get_current_system_profile(...)`
readlink -e $CURRENT_PROFILE
 */
 
nix/hosts/ssh.rs:               let paths = self.ssh(&["sh", "-c", &command]).capture_output().await?;
/*
# `Ssh::get_main_system_profile(...)`
# NOTE: the command executed is the same as in `/nix/host/local.rs` (except for SSH)
# XXX: NOTE: Same as `Local::get_main_system_profile(...)`
# WARNING: COMMAND EXECUTED OVER SSH (`self.ssh(...)`)
sh -c 'readlink -e "$SYSTEM_PROFILE" | readlink -e "$CURRENT_PROFILE"'
 */

nix/hosts/ssh.rs:               self.run_command(self.ssh(&["reboot"])).await
/*
# `Ssh::initiate_reboot` (`initate_reboot` spelt incorrectly... omg, line 408)
# WARNING: NOTE: `Local` doesn't seem to have an alternative to reboot (why?)
reboot
 */
```

#### SSH Options
```bash
# === Defined in /nix/host/ssh.rs Ssh::ssh_options() (line 345) === #

-o StrictHostKeyChecking=accept-new
-o BatchMode=yes
-T
$EXTRA_SSH_OPTIONS # I assume these are set by the user?
-p $SSH_PORT   # if self.port is Some
-F $SSH_CONFIG # if self.ssh_config is Some

```

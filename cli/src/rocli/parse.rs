/// Parse the GNU convention CLI argument syntax.
///
/// # Examples
/// ```rs
/// assert!(parse(vec!["--flag=value"]) == vec!["--flag", "value"]);
/// assert!(parse(vec!["--flag value"]) == vec!["--flag", "value"]);
/// assert!(parse(vec!["-abe"]) == vec!["-a", "-b", "-e"]);
/// assert!(parse(vec!["-abef=32"]) == vec!["-a", "-b", "-e", "-f", "32"]);
/// ```
///
/// # Credit
/// Based on [github:ksk001100/seahorse `src/utils.rs`](https://github.com/ksk001100/seahorse/blob/master/src/utils.rs)
pub fn normalize_args(args: Vec<String>) -> Vec<String> {
    args.iter().fold(Vec::<String>::new(), |mut acc, el| {
        if !el.starts_with('-') {
            acc.push(el.to_owned());
            return acc;
        }

        let mut split = el.splitn(2, '=').map(|s| s.to_owned()).collect();
        if el.starts_with("--") {
            acc.append(&mut split);
        } else {
            let flags = split[0].chars().skip(1).map(|c| format!("-{c}"));

            acc.append(&mut flags.collect());
            if let Some(value) = split.get(1) {
                acc.push(value.to_owned());
            }
        }
        acc
    })
}

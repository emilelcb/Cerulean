pub struct Command {
    pub name: String,
    pub version: Option<String>,

    pub action: Action,

    pub subcommands: Vec<Commands>,
    pub flags: Vec<Flag>,
}

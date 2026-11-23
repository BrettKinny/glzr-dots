require("git"):setup { order = 1500 }
require("folder-rules"):setup()
-- feed yazi navigation into zoxide so Z / shell z know these dirs
require("zoxide"):setup { update_db = true }
require("full-border"):setup { set = "rounded" }
require("starship"):setup()
-- extension lookup instead of spawning file.exe per file; falls back to file.exe when unknown
require("mime-ext"):setup()

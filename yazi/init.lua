require("git"):setup { order = 1500 }
require("folder-rules"):setup()
-- feed yazi navigation into zoxide so Z / shell z know these dirs
require("zoxide"):setup { update_db = true }

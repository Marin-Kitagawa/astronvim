return {
    name = "easyjump.yazi",
    url = "https://gitee.com/DreamMaoMao/easyjump.yazi.git",
    lazy = true,
    build = function(plugin)
      require("yazi.plugin").build_plugin(plugin)
    end,
}

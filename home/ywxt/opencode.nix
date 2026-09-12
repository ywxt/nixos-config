{ config, pkgs, ... }:

let
  json = pkgs.formats.json { };
in
{
  sops.secrets."opencode-api-key" = {
    sopsFile = ../../secrets/ywxt-work-opencode.yaml;
    key = "opencode/api-key";
  };
  sops.secrets."opencode-base-url" = {
    sopsFile = ../../secrets/ywxt-work-opencode.yaml;
    key = "opencode/base-url";
  };

  packages = [ pkgs.opencode ];

  xdg.config.files."opencode/opencode.json" = {
    clobber = true;
    source = json.generate "opencode.json" {
      "$schema" = "https://opencode.ai/config.json";
      provider."火山AI网关" = {
        name = "火山AI网关";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = "{file:${config.sops.secrets."opencode-base-url".path}}";
          apiKey = "{file:${config.sops.secrets."opencode-api-key".path}}";
        };
        models = {
          deepseek-v4-flash.name = "DeepSeek-V4-Flash";
          deepseek-v4-pro.name = "DeepSeek-V4-Pro";
          "qwen3.7-plus".name = "Qwen3.7-Plus";
          "qwen3.7-max".name = "Qwen3.7-Max";
          "doubao-seed-2.1-pro".name = "DouBao-Seed-2.1-Pro";
          MiniMax-M3.name = "MiniMax-M3";
          "glm-5.2".name = "GLM-5.2";
          "glm-5.3".name = "GLM-5.3";
          "glm-5.3-flash".name = "GLM-5.3-Flash";
          hy3.name = "HunYuan3";
        };
      };
    };
  };
}

{ lib, pkgs, ... }:

let
  mkValueString =
    value:
    if value == true then
      "True"
    else if value == false then
      "False"
    else
      lib.generators.mkValueStringDefault { } value;
  ini = pkgs.formats.ini {
    mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } "=";
  };
  iniGlobal = pkgs.formats.iniWithGlobalSection {
    mkKeyValue = lib.generators.mkKeyValueDefault { inherit mkValueString; } "=";
  };
in
{
  xdg.config.files = {
    "fcitx5/config" = {
      clobber = true;
      source = ini.generate "fcitx5-config" {
        Hotkey = {
          EnumerateWithTriggerKeys = true;
          EnumerateSkipFirst = false;
          ModifierOnlyKeyTimeout = 250;
        };
        "Hotkey/TriggerKeys" = {
          "0" = "Control+space";
          "1" = "Zenkaku_Hankaku";
          "2" = "Hangul";
        };
        "Hotkey/ActivateKeys"."0" = "Hangul_Hanja";
        "Hotkey/DeactivateKeys"."0" = "Hangul_Romaja";
        "Hotkey/AltTriggerKeys"."0" = "Shift_L";
        "Hotkey/EnumerateGroupForwardKeys"."0" = "Super+space";
        "Hotkey/EnumerateGroupBackwardKeys"."0" = "Shift+Super+space";
        "Hotkey/PrevPage"."0" = "Up";
        "Hotkey/NextPage"."0" = "Down";
        "Hotkey/PrevCandidate"."0" = "Shift+Tab";
        "Hotkey/NextCandidate"."0" = "Tab";
        "Hotkey/TogglePreedit"."0" = "Control+Alt+P";
        Behavior = {
          ActiveByDefault = false;
          resetStateWhenFocusIn = "No";
          ShareInputState = "No";
          PreeditEnabledByDefault = true;
          ShowInputMethodInformation = true;
          showInputMethodInformationWhenFocusIn = false;
          CompactInputMethodInformation = true;
          ShowFirstInputMethodInformation = true;
          DefaultPageSize = 5;
          OverrideXkbOption = false;
          PreloadInputMethod = true;
          AllowInputMethodForPassword = false;
          ShowPreeditForPassword = false;
          AutoSavePeriod = 30;
        };
      };
    };
    "fcitx5/profile" = {
      clobber = true;
      source = ini.generate "fcitx5-profile" {
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "rime";
        };
        "Groups/0/Items/0" = {
          Name = "rime";
          Layout = "";
        };
        GroupOrder."0" = "Default";
      };
    };
    "fcitx5/conf/classicui.conf" = {
      clobber = true;
      source = iniGlobal.generate "fcitx5-classicui" {
        globalSection = {
          "Vertical Candidate List" = false;
          WheelForPaging = true;
          Font = "Sans 10";
          MenuFont = "Sans 10";
          TrayFont = "Sans Bold 10";
          TrayOutlineColor = "#000000";
          TrayTextColor = "#ffffff";
          PreferTextIcon = true;
          ShowLayoutNameInIcon = true;
          UseInputMethodLanguageToDisplayText = true;
          Theme = "FluentLight";
          DarkTheme = "FluentDark";
          UseDarkTheme = true;
          UseAccentColor = true;
          PerScreenDPI = false;
          ForceWaylandDPI = 0;
          EnableFractionalScale = true;
        };
      };
    };
    "fcitx5/conf/rime.conf" = {
      clobber = true;

      source = iniGlobal.generate "fcitx5-rime" {
        globalSection = {
          PreeditMode = "ComposingText";
          PreeditCursorPositionAtBeginning = false;
          InputState = "FollowGlobalConfig";
          SwitchInputMethodBehavior = "CommitCommitPreview";
          LatinModeNameFromSchema = false;
        };
      };
    };
  };

  xdg.data.files."fcitx5/rime/default.custom.yaml" = {
    clobber = true;
    text = ''
      patch:
        schema_list:
          - schema: huma_trad
          - schema: luna_pinyin
    '';
  };
}

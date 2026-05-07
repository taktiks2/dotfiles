{ config, username, ... }:

# gh-dash の設定を Nix attrset で宣言。
# keybindings.prs から ~/.config/gh-dash/bin/octo-review.sh を呼ぶため、
# bin/ は home/common.nix の xdg.configFile で個別 live link 維持。
# GitHub org / dev clone path はユーザ引数から派生（multi-host 対応）。

{
  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        { title = "Needs My Review";  filters = "is:open review-requested:@me"; type = null; }
        { title = "My Pull Requests"; filters = "is:open author:@me draft:false"; type = null; }
        { title = "My Drafts";        filters = "is:open author:@me draft:true";  type = null; }
        { title = "Involved";         filters = "is:open involves:@me -author:@me"; type = null; }
      ];
      issuesSections = [
        { title = "My Issues"; filters = "is:open author:@me"; }
        { title = "Assigned"; filters = "is:open assignee:@me"; }
        { title = "Involved"; filters = "is:open involves:@me -author:@me"; }
      ];
      repo = {
        branchesRefetchIntervalSeconds = 30;
        prsRefetchIntervalSeconds      = 60;
      };
      defaults = {
        preview = { open = true; width = 0.5; };
        prsLimit    = 20;
        issuesLimit = 20;
        view        = "prs";
        layout = {
          prs = {
            updatedAt = { width = 5; };
            repo      = { width = 20; };
            author    = { width = 15; };
            assignees = { width = 20; hidden = true; };
            base      = { width = 15; hidden = true; };
            lines     = { width = 15; };
          };
          issues = {
            updatedAt = { width = 5; };
            repo      = { width = 15; };
            creator   = { width = 10; };
            assignees = { width = 20; hidden = true; };
          };
        };
        refetchIntervalMinutes = 30;
      };
      keybindings = {
        universal = [];
        issues    = [];
        prs = [
          {
            key     = "o";
            name    = "Octo PR";
            command = "tmux new-window -c {{.RepoPath}} -n \"pr#{{.PrNumber}}-$(basename {{.RepoName}})\" \"nvim '+Octo pr edit {{.PrNumber}}'\" ; tmux display-popup -C";
          }
          {
            key     = "O";
            name    = "Checkout & Review";
            command = "tmux new-window -c {{.RepoPath}} -n \"review#{{.PrNumber}}-$(basename {{.RepoName}})\" \"~/.config/gh-dash/bin/octo-review.sh {{.RepoName}} {{.PrNumber}}\" ; tmux display-popup -C";
          }
        ];
        branches = [];
      };
      repoPaths = {
        "${username}/*" = "${config.home.homeDirectory}/dev/*";
      };
      theme = {
        ui = {
          sectionsShowCount = true;
          table = { showSeparator = true; compact = false; };
        };
      };
      pager       = { diff = "delta"; };
      confirmQuit = false;
    };
  };
}

let
  mkKeymaps = mode: key: [ { inherit key mode; } ];
  mkNormal = mkKeymaps [ "n" ];
in
{
  globals = {
    mapleader = " ";
  };

  file-manager.keymaps = {
    view.buffers = mkNormal "<leader>o-";
    view.changes = mkNormal "<leader>s-";
    view.project = mkNormal "<leader>-";
  };

  buffers.keymaps = {
    buffer.close = mkNormal "<leader>cb";
    buffer.forceClose = mkNormal "<leader>Cb";
    buffer.next = mkNormal "<leader>b";
    buffer.previous = mkNormal "<leader>B";
  };

  fuzzy-finder.keymaps = {
    view.buffers = mkNormal "<leader>of";
    view.changes = mkNormal "<leader>sf";
    view.project = mkNormal "<leader>f";
    view.text = mkNormal "<leader>F";
  };

  git.keymaps = {
    hunk.next = mkNormal "<leader>g";
    hunk.preview = mkNormal "<leader>pg";
    hunk.previous = mkNormal "<leader>G";
    hunk.reset = mkNormal "<leader>rg";
    hunk.toggleStaging = mkNormal "<leader>sg";
    buffer.reset = mkNormal "<leader>Rg";
    buffer.toggleStaging = mkNormal "<leader>Sg";
  };
}

let
  mkNormal = key: [
    {
      inherit key;
      mode = [ "n" ];
    }
  ];
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
    view.text = mkNormal "<leader>gf";
  };
}

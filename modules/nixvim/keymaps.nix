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
    view.project = mkNormal "<leader>-";
    view.changes = mkNormal "<leader>s-";
    view.buffers = mkNormal "<leader>o-";
  };

  buffers.keymaps = {
    buffer.next = mkNormal "<leader>b";
    buffer.previous = mkNormal "<leader>B";
    buffer.close = mkNormal "<leader>cb";
    buffer.forceClose = mkNormal "<leader>Cb";
  };
}

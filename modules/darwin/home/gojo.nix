# gojo isn't in Homebrew, so install it from its flake.
#
# Upstream (hackrdotsh/gojo) was rewritten in Go and now ships a proper
# buildGoModule package that supports aarch64-darwin (vendorHash is stable
# across systems via proxyVendor), so the old per-platform bun-deps workaround
# is no longer needed.
{
  inputs,
  system,
  ...
}: {
  home.packages = [inputs.gojo.packages.${system}.default];
}

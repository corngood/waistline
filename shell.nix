with import <nixpkgs> {};

(import ./.).overrideAttrs (super: {
  NIX_SHELL_PROMPT = "W";
  buildInputs = super.buildInputs ++ [
    python
    jq
  ];
})


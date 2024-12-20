{
  lib,
  username,
  sshPubKey,
}:

{
  # the admin user
  users.users."${username}" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # can use sudo
    openssh.authorizedKeys.keys = [ sshPubKey ];
  };

  # allow the "username" user to use sudo without a password
  # DANGER: this might not match your security preferences
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.openssh = {
    enable = true;
    # don't allow root login
    settings.PermitRootLogin = lib.mkForce "no";
    # don't allow password login
    settings.PasswordAuthentication = lib.mkForce false;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  system.stateVersion = "24.11";

}

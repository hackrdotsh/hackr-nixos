{ ... }: {
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    # emSign ECC Root CA - G3 is already absent from Mozilla's trust store.
  ];
}

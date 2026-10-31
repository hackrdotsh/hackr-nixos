{ snowstead }:
''
  def cache-login [] {
    let token = (input --suppress-output "Snowstead push token: ")
    if ($token | is-empty) {
      error make {msg: "A Snowstead push token is required."}
    }
    ${snowstead}/bin/snowstead login snowstead https://cache.snowstead.com $token
    if $env.LAST_EXIT_CODE != 0 {
      error make {msg: "Snowstead login failed."}
    }
  }
''
